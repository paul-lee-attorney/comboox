// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IBOHKeeper.sol";

contract BOHKeeper is IBOHKeeper, AccessControl {
    using RulesParser for bytes32;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier notEstablished(address body) {
        require(_gk.getBOH().getHeadOfFile(body).state != 
            uint8(FilesRepo.StateOfFile.Established), 
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

    function createSHA(uint version, address primeKeyOfCaller, uint caller) external onlyDirectKeeper {
        require(_gk.getROM().isMember(caller), "not MEMBER");

        bytes32 snOfDoc = bytes32((uint256(uint8(IRegCenter.TypeOfDoc.ShareholdersAgreement)) << 240) +
            (version << 224)); 

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, primeKeyOfCaller);

        IAccessControl(doc.body).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );

        _gk.getBOH().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external onlyDirectKeeper onlyPartyOf(sha, caller) {
        require(IAccessControl(sha).finalized(), 
            "BOHK.CSHA: SHA not finalized");

        ISigPage(sha).circulateDoc();

        uint16 signingDays = ISigPage(sha).getSigningDays();
        uint16 closingDays = ISigPage(sha).getClosingDays();

        IShareholdersAgreement _sha = _gk.getSHA();

        RulesParser.VotingRule memory vr = 
            address(_sha) == address(0) ?
                RulesParser.SHA_INIT_VR.votingRuleParser() :
                _gk.getSHA().getRule(8).votingRuleParser();
        
        ISigPage(sha).setTiming(false, signingDays + vr.shaExecDays + vr.shaConfirmDays, closingDays);

        _gk.getBOH().circulateFile(sha, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper onlyPartyOf(sha, caller) {
        require(
            _gk.getBOH().getHeadOfFile(sha).state == uint8(FilesRepo.StateOfFile.Circulated),
            "SHA not in Circulated State"
        );

        if (ISigPage(sha).signDoc(true, caller, sigHash) &&
            ISigPage(sha).established())
        {
            _gk.getBOH().establishFile(sha);
        }
    }

    function activateSHA(address sha, uint256 caller)
        external
        onlyDirectKeeper
        onlyPartyOf(sha, caller)
    {
        IBookOfSHA _boh = _gk.getBOH();

        _boh.execFile(sha);

        _boh.changePointer(sha);

        RulesParser.GovernanceRule memory gr = 
            IShareholdersAgreement(sha).getRule(0).governanceRuleParser();

        IRegisterOfMembers _rom = _gk.getROM();

        if (_rom.maxQtyOfMembers() != gr.maxQtyOfMembers)
            _rom.setMaxQtyOfMembers(gr.maxQtyOfMembers);

        _rom.setAmtBase(gr.basedOnPar);

        _rom.setVoteBase(gr.basedOnPar);


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
                    titleOfNominator: rule.titleOfNominator,
                    argu: rule.argu
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

    function acceptSHA(bytes32 sigHash, uint256 caller) external onlyDirectKeeper {
        address sha = address(_gk.getSHA());
        ISigPage(sha).addBlank(false, true, 1, caller);
        ISigPage(sha).signDoc(false, caller, sigHash);
    }
}
