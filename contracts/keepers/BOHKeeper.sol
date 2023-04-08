// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../common/ruting/BODSetting.sol";
// import "../common/ruting/BOHSetting.sol";
// import "../common/ruting/BOOSetting.sol";
// import "../common/ruting/BOSSetting.sol";
// import "../common/ruting/ROMSetting.sol";

import "../common/access/AccessControl.sol";

import "./IBOHKeeper.sol";

contract BOHKeeper is IBOHKeeper, AccessControl {
    using RulesParser for uint256;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier notEstablished(address body) {
        require(_gk.getBOH().getHeadOfFile(body).state != 
            uint8(IFilesFolder.StateOfFile.Established), 
            "BOHK.mf.NE: Doc ALREADY Established");
        _;
    }

    modifier onlyOwnerOf(address body, uint256 caller) {
        require(
            caller != 0 && IAccessControl(body).getOwner() == caller,
            "not Owner"
        );
        _;
    }

    modifier onlyPartyOf(address body, uint256 caller) {
        require(ISigPage(body).isParty(caller), "NOT Party of Doc");
        _;
    }

    // #############
    // ##   SHA   ##
    // #############

    // function setTempOfBOH(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
    //     _gk.getBOH().setTemplate(temp, typeOfDoc);
    // }

    function createSHA(uint16 version, address primeKeyOfCaller, uint40 caller) external onlyDirectKeeper {
        require(_gk.getROM().isMember(caller), "not MEMBER");
        // address sha = _gk.getBOH().createDoc(uint8(IRegCenter.TypeOfDoc.ShareholdersAgreement), version, caller);

        uint256 snOfDoc = uint256(uint8(IRegCenter.TypeOfDoc.ShareholdersAgreement)) << 240 +
            uint256(version) << 224; 

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, primeKeyOfCaller);

        IAccessControl(doc.body).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );

        _gk.getBOH().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    // function removeSHA(address sha, uint256 caller)
    //     external
    //     onlyDirectKeeper
    //     onlyOwnerOf(sha, caller)
    //     notEstablished(sha)
    // {
    //     _gk.getBOH().removeDoc(sha);
    // }

    function circulateSHA(
        address sha,
        uint256 seqOfRule,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external onlyDirectKeeper onlyPartyOf(sha, caller) {
        // IShareholdersAgreement(sha).finalizeTerms();
        // IAccessControl(sha).setOwner(0);

        require(IAccessControl(sha).finalized(), "BOHK.CSHA: SHA not finalized");

        RulesParser.VotingRule memory vr = 
            _gk.getSHA().getRule(seqOfRule).votingRuleParser();

        _gk.getBOH().circulateDoc(sha, vr, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper onlyPartyOf(sha, caller) {
        require(
            _gk.getBOH().getHeadOfFile(sha).state == uint8(IFilesFolder.StateOfFile.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(true, caller, sigHash);

        if (ISigPage(sha).established()) 
            _gk.getBOH().setStateOfFile(sha, uint8(IFilesFolder.StateOfFile.Established));
    }

    function effectiveSHA(address sha, uint256 caller)
        external
        onlyDirectKeeper
        onlyPartyOf(sha, caller)
    {
        require(
            _gk.getBOH().getHeadOfFile(sha).state ==
                uint8(IFilesFolder.StateOfFile.Established),
            "BOHK.ES: SHA not executed yet"
        );

        require(_allMembersSigned(sha) || _reachedEffectiveThreshold(sha), 
            "BOHK.ES: SHA effective conditions not reached");

        _gk.getBOH().changePointer(sha);

        RulesParser.GovernanceRule memory gr = 
            IShareholdersAgreement(sha).getRule(0).governanceRuleParser();

        _gk.getROM().setAmtBase(gr.basedOnPar);

        _gk.getROM().setVoteBase(gr.basedOnPar);

        // _gk.getBOD().setMaxQtyOfDirectors(gr.maxNumOfDirectors);

        if (IShareholdersAgreement(sha).hasTitle(uint8(IRegCenter.TypeOfDoc.LockUp)))
            _lockUpShares(sha);
        
        if (IShareholdersAgreement(sha).hasTitle(uint8(IRegCenter.TypeOfDoc.Options))) 
            _regOptionTerms(sha);

        _updatePositionSetting(sha);
        _updateGrouping(sha);
    }

    function _lockUpShares(address sha) private {
        uint256[] memory lockedShares = ILockUp(IShareholdersAgreement(sha).getTerm(
            uint8(IRegCenter.TypeOfDoc.Options))).lockedShares();
        uint256 len = lockedShares.length;
        while (len > 0) {
            SharesRepo.Share memory share = _gk.getBOS().getShare(lockedShares[len-1]);
            _gk.getBOS().decreaseCleanPaid(share.head.seqOfShare, share.body.paid);
            len--;
        }
    }

    function _regOptionTerms(address sha) private {
        address opts = IShareholdersAgreement(sha).
            getTerm(uint8(IRegCenter.TypeOfDoc.Options));
        _gk.getBOO().regOptionTerms(opts);
    }

    function _updatePositionSetting(address sha) private {
        uint256 len = IShareholdersAgreement(sha).getRule(256).positionAllocateRuleParser().qtyOfSubRule;
        uint256 i;
        IBookOfDirectors _bod = _gk.getBOD();
        while (i < len) {
            RulesParser.PositionAllocateRule memory rule = 
                IShareholdersAgreement(sha).getRule(256+i).positionAllocateRuleParser();

            if (rule.removePos) {
                _bod.removePosition(rule.seqOfPos);
            } else {
                OfficersRepo.Position memory pos = _bod.getPosition(rule.seqOfPos);
                pos = OfficersRepo.Position({
                    title: rule.titleOfPos,
                    seqOfPos: rule.seqOfPos,
                    acct: pos.acct,
                    nominator: rule.nominator,
                    startDate: pos.startDate,
                    endDate: rule.endDate,
                    seqOfVR: rule.seqOfVR,
                    para: rule.para,
                    arg: rule.arg
                });
                
                _bod.updatePosition(pos);
            }

            i++;
        }                
    }


    function _updateGrouping(address sha) private {
        uint256 len = IShareholdersAgreement(sha).getRule(768).groupUpdateOrderParser().qtyOfSubRule;
        uint256 i;
        IRegisterOfMembers _rom = _gk.getROM();
        while (i < len) {
            RulesParser.GroupUpdateOrder memory order = 
                IShareholdersAgreement(sha).getRule(768+i).groupUpdateOrderParser();

            uint256 j;        
            if (order.addMember) {
                while (j < 4) {
                    if (order.members[j] > 0)
                        _rom.addMemberToGroup(order.members[j], order.groupRep);
                    j++;
                }
            } else {
                while (j < 4) {
                    if (order.members[j] > 0)
                        _rom.removeMemberFromGroup(order.members[j], order.groupRep);
                    j++;
                }
            }

            i++;
        }        
    }

    function _allMembersSigned(address sha) private view returns (bool) {
        uint256[] memory members = _gk.getROM().membersList();
        uint256 len = members.length;
        while (len > 0) {            
            if (!ISigPage(sha).isParty(members[len - 1]))
                return false;
            len--;
        }
        return true;
    }

    function _reachedEffectiveThreshold(address sha) private view returns (bool) {
        uint256[] memory parties = ISigPage(sha).getParties();
        uint256 len = parties.length;
        
        RulesParser.GovernanceRule memory gr = _gk.getSHA().getRule(0).governanceRuleParser();

        uint64 threashold = uint64(gr.shaEffectiveRatio) * _gk.getROM().totalVotes() / 10000;
        
        uint64 supportWeight;        
        while (len > 0) {
            supportWeight += _gk.getROM().votesInHand(parties[len-1]);
            if (supportWeight > threashold) return true;
            len --;
        }
        return false;
    }

    function acceptSHA(bytes32 sigHash, uint256 caller) external onlyDirectKeeper {
        address sha = address(_gk.getSHA());
        ISigPage(sha).addBlank(false, 0, caller);
        ISigPage(sha).signDoc(false, caller, sigHash);
    }
}
