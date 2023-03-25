// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boh/IShareholdersAgreement.sol";
import "../books/boh/terms/ILockUp.sol";

import "../common/components/ISigPage.sol";

import "../common/lib/RulesParser.sol";

import "../common/ruting/BODSetting.sol";
import "../common/ruting/BOOSetting.sol";
import "../common/ruting/BOSSetting.sol";
import "../common/ruting/ROMSetting.sol";
import "../common/ruting/BOHSetting.sol";

import "../common/access/AccessControl.sol";

import "./IBOHKeeper.sol";

contract BOHKeeper is
    IBOHKeeper,
    BODSetting,
    BOHSetting,
    BOOSetting,
    BOSSetting,
    ROMSetting,
    AccessControl
{
    using RulesParser for uint256;

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier notEstablished(address body) {
        require(_boh.getHeadOfDoc(body).state != 
            uint8(IRepoOfDocs.RODStates.Established), 
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

    function setTempOfBOH(address temp, uint8 typeOfDoc) external onlyDirectKeeper {
        _boh.setTemplate(temp, typeOfDoc);
    }

    function createSHA(uint8 typeOfDoc, uint256 caller) external onlyDirectKeeper {
        require(_rom.isMember(caller), "not MEMBER");
        address sha = _boh.createDoc(typeOfDoc, caller);

        IAccessControl(sha).init(
            caller,
            address(this),
            address(_rc),
            address(_gk)
        );
    }

    function removeSHA(address sha, uint256 caller)
        external
        onlyDirectKeeper
        onlyOwnerOf(sha, caller)
        notEstablished(sha)
    {
        _boh.removeDoc(sha);
    }

    function circulateSHA(
        address sha,
        uint256 seqOfRule,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external onlyDirectKeeper onlyOwnerOf(sha, caller) {
        IShareholdersAgreement(sha).finalizeTerms();
        IAccessControl(sha).setOwner(0);

        RulesParser.VotingRule memory vr = 
            _getSHA().getRule(seqOfRule).votingRuleParser();

        _boh.circulateDoc(sha, vr, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external onlyDirectKeeper onlyPartyOf(sha, caller) {
        require(
            _boh.getHeadOfDoc(sha).state == uint8(IRepoOfDocs.RODStates.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(true, caller, sigHash);

        if (ISigPage(sha).established()) 
            _boh.setStateOfDoc(sha, uint8(IRepoOfDocs.RODStates.Established));
    }

    function effectiveSHA(address sha, uint256 caller)
        external
        onlyDirectKeeper
        onlyPartyOf(sha, caller)
    {
        require(
            _boh.getHeadOfDoc(sha).state ==
                uint8(IRepoOfDocs.RODStates.Established),
            "BOHK.ES: SHA not executed yet"
        );

        require(_allMembersSigned(sha) || _reachedEffectiveThreshold(sha), 
            "BOHK.ES: SHA effective conditions not reached");

        _boh.changePointer(sha);

        RulesParser.GovernanceRule memory gr = 
            IShareholdersAgreement(sha).getRule(0).governanceRuleParser();

        _rom.setAmtBase(gr.basedOnPar);

        _rom.setVoteBase(gr.basedOnPar);

        _bod.setMaxQtyOfDirectors(gr.maxNumOfDirectors);

        if (IShareholdersAgreement(sha).hasTitle(uint8(IShareholdersAgreement.TermTitle.LockUp)))
            _lockUpShares(sha);
        
        if (IShareholdersAgreement(sha).hasTitle(uint8(IShareholdersAgreement.TermTitle.Options))) 
            _regOptionTerms(sha);

        _updateGrouping(sha, _rom);
    }

    function _lockUpShares(address sha) private {
        uint256[] memory lockedShares = ILockUp(IShareholdersAgreement(sha).getTerm(
            uint8(IShareholdersAgreement.TermTitle.Options))).lockedShares();
        uint256 len = lockedShares.length;
        while (len > 0) {
            SharesRepo.Share memory share = _bos.getShare(lockedShares[len-1]);
            _bos.decreaseCleanPaid(share.head.seqOfShare, share.body.paid);
            len--;
        }
    }

    function _regOptionTerms(address sha) private {
        address opts = IShareholdersAgreement(sha).
            getTerm(uint8(IShareholdersAgreement.TermTitle.Options));
        _boo.regOptionTerms(opts);
    }

    function _updateGrouping(address sha, IRegisterOfMembers _rom) private {
        uint256 len = IShareholdersAgreement(sha).getRule(768).groupUpdateOrderParser().qtyOfSubRule;
        uint256 i;
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
        uint256[] memory members = _rom.membersList();
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
        
        RulesParser.GovernanceRule memory gr = _getSHA().getRule(0).governanceRuleParser();

        uint64 threashold = uint64(gr.shaEffectiveRatio) * _rom.totalVotes() / 10000;
        
        uint64 supportWeight;        
        while (len > 0) {
            supportWeight += _rom.votesInHand(parties[len-1]);
            if (supportWeight > threashold) return true;
            len --;
        }
        return false;
    }

    function acceptSHA(bytes32 sigHash, uint256 caller) external onlyDirectKeeper {
        ISigPage(address(_getSHA())).addBlank(false, 0, caller);
        ISigPage(address(_getSHA())).signDoc(false, caller, sigHash);
    }
}
