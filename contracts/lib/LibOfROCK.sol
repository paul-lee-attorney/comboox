// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "./RulesParser.sol";
import "./ArrayUtils.sol";
import "./InterfacesHub.sol";

library LibOfROCK {
    using RulesParser for bytes32;
    using ArrayUtils for uint[];
    using InterfacesHub for address;
    
    error ROCKLib_NotPartyOf(address sha, uint caller);

    error ROCKLib_WrongFileState(address sha, uint state);

    error ROCKLib_ZeroAddr();

    function circulateSHA(
        uint caller,
        address sha,
        bytes32 docUrl,
        bytes32 docHash
    ) external {
        address gk = address(this);

        if (!ISigPage(sha).isParty(caller)) {
            revert ROCKLib_NotPartyOf(sha, caller);
        }

        if (!IDraftControl(sha).isFinalized()) {
            revert ROCKLib_WrongFileState(sha, 0);
        }
        
        IShareholdersAgreement _sha = IShareholdersAgreement(sha);

        _sha.circulateDoc();

        uint16 signingDays = _sha.getSigningDays();
        uint16 closingDays = _sha.getClosingDays();

        RulesParser.VotingRule memory vr = address(gk.getSHA()) == address(0) 
            ? _sha.getRule(8).votingRuleParser()
            : gk.getSHA().getRule(8).votingRuleParser();

        gk.getROC().circulateFile(sha, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        uint caller,
        address sha,
        bytes32 sigHash
    ) external {
        address gk = address(this);

        if (!ISigPage(sha).isParty(caller)) {
            revert ROCKLib_NotPartyOf(sha, caller);
        }

        if (
            gk.getROC().getHeadOfFile(sha).state != 
            uint8(FilesRepo.StateOfFile.Circulated)
        ) revert ROCKLib_WrongFileState(sha, gk.getROC().getHeadOfFile(sha).state);

        ISigPage(sha).signDoc(true, caller, sigHash);
    }

    function activateSHA(uint caller, address sha) external {
        address gk = address(this);

        if (!ISigPage(sha).isParty(caller)) {
            revert ROCKLib_NotPartyOf(sha, caller);
        }
        
        IRegisterOfConstitution _roc = gk.getROC();
        IRegisterOfMembers _rom = gk.getROM();

        if (sha == address(0)) {
            revert ROCKLib_ZeroAddr();
        }

        IShareholdersAgreement _sha = IShareholdersAgreement(sha);

        uint seqOfMotion = _roc.getHeadOfFile(sha).seqOfMotion;

        if (seqOfMotion > 0) {
            gk.getGMM().execResolution(
                seqOfMotion,
                uint(uint160(sha)),
                caller
            );
            _roc.execFile(sha);
        } else if (_membersAllSigned(_rom, _sha)) {
            _roc.setStateOfFile(sha, uint8(FilesRepo.StateOfFile.Closed));
        }

        _roc.changePointer(sha);

        RulesParser.GovernanceRule memory gr = 
            _sha.getRule(0).governanceRuleParser();

        if (_rom.maxQtyOfMembers() != gr.maxQtyOfMembers)
            _rom.setMaxQtyOfMembers(gr.maxQtyOfMembers);

        _rom.setVoteBase(gr.basedOnPar);

        if (_rom.minVoteRatioOnChain() != gr.minVoteRatioOnChain)
            _rom.setMinVoteRatioOnChain(gr.minVoteRatioOnChain);
        
        if (_sha.hasTitle(uint8(IShareholdersAgreement.TitleOfTerm.Options))) 
            _regOptionTerms(_sha);

        _updatePositionSetting(_sha);
        _updateGrouping(_sha);
    }

    function _membersAllSigned(
        IRegisterOfMembers _rom,
        IShareholdersAgreement _sha
    ) view private returns (bool) {
        uint[] memory members = _rom.membersList();
        uint[] memory parties = _sha.getParties();
        
        if (parties.length == 0 || parties.length != members.length) {
            return false;
        }

        return members.fullyCoveredBy(parties);
    }

    function _regOptionTerms(IShareholdersAgreement _sha) private {
        address opts = _sha.getTerm(uint8(IShareholdersAgreement.TitleOfTerm.Options));
        address(this).getROO().regOptionTerms(opts);
    }

    function _updatePositionSetting(IShareholdersAgreement _sha) private {
        IRegisterOfDirectors _rod = address(this).getROD();

        uint256 len = _sha.getRule(256).positionAllocateRuleParser().qtyOfSubRule;
        uint256 i;
        while (i < len) {
            RulesParser.PositionAllocateRule memory rule = 
                _sha.getRule(256+i).positionAllocateRuleParser();

            if (rule.removePos) {
                _rod.removePosition(rule.seqOfPos);
            } else {
                OfficersRepo.Position memory pos = _rod.getPosition(rule.seqOfPos);
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
                
                _rod.updatePosition(pos);
            }

            i++;
        }                
    }


    function _updateGrouping(IShareholdersAgreement _sha) private {
        IRegisterOfMembers _rom = address(this).getROM();

        uint256 len = _sha.getRule(768).groupUpdateOrderParser().qtyOfSubRule;
        uint256 i;

        while (i < len) {
            RulesParser.GroupUpdateOrder memory order = 
                _sha.getRule(768+i).groupUpdateOrderParser();

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
                        _rom.removeMemberFromGroup(order.members[j]);
                    j++;
                }
            }

            i++;
        }        
    }

    function acceptSHA(uint caller, bytes32 sigHash) external {
        address gk = address(this);
        IShareholdersAgreement _sha = gk.getSHA();
        _sha.addBlank(false, true, 1, caller);
        _sha.signDoc(false, caller, sigHash);
    }
}
