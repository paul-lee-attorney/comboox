// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

pragma solidity ^0.8.8;

import "../common/access/RoyaltyCharge.sol";

import "./IROCKeeper_2.sol";

contract ROCKeeper_3 is IROCKeeper_2, RoyaltyCharge {
    using RulesParser for bytes32;
    using ArrayUtils for uint[];
    
    // #############
    // ##   SHA   ##
    // #############

    function createSHA(
        uint version, 
        address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 18000);

        require(_gk.getROM().isMember(caller), "not MEMBER");

        bytes32 snOfDoc = bytes32((uint256(uint8(IRegCenter.TypeOfDoc.SHA)) << 224) +
            uint224(version << 192)); 

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, msgSender);

        IAccessControl(doc.body).initKeepers(
            address(this),
            address(_gk)
        );

        IShareholdersAgreement(doc.body).initDefaultRules();

        _gk.getROC().regFile(DocsRepo.codifyHead(doc.head), doc.body);
    }

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        require(ISigPage(sha).isParty(caller), "NOT Party of Doc");

        require(IAccessControl(sha).isFinalized(), 
            "BOHK.CSHA: SHA not finalized");

        
        IShareholdersAgreement _sha = IShareholdersAgreement(sha);

        _sha.circulateDoc();

        uint16 signingDays = _sha.getSigningDays();
        uint16 closingDays = _sha.getClosingDays();

        RulesParser.VotingRule memory vr = address(_gk.getSHA()) == address(0) 
            ? _sha.getRule(8).votingRuleParser()
            : _gk.getSHA().getRule(8).votingRuleParser();

        _gk.getROC().circulateFile(sha, signingDays, closingDays, vr, docUrl, docHash);
    }

    // ======== Sign SHA ========

    function signSHA(
        address sha,
        bytes32 sigHash,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        require(ISigPage(sha).isParty(caller), "NOT Party of Doc");

        require(
            _gk.getROC().getHeadOfFile(sha).state == uint8(FilesRepo.StateOfFile.Circulated),
            "SHA not in Circulated State"
        );

        ISigPage(sha).signDoc(true, caller, sigHash);
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

    function activateSHA(address sha, address msgSender) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);

        require(ISigPage(sha).isParty(caller), "NOT Party of Doc");
        
        IRegisterOfConstitution _roc = _gk.getROC();
        IRegisterOfMembers _rom = _gk.getROM();

        require(sha != address(0), "ROCK.actSHA: zero sha");
        IShareholdersAgreement _sha = IShareholdersAgreement(sha);

        uint seqOfMotion = _roc.getHeadOfFile(sha).seqOfMotion;

        if (seqOfMotion > 0) {
            _gk.getGMM().execResolution(
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

    function _regOptionTerms(IShareholdersAgreement _sha) private {
        address opts = _sha.getTerm(uint8(IShareholdersAgreement.TitleOfTerm.Options));
        _gk.getROO().regOptionTerms(opts);
    }

    function _updatePositionSetting(IShareholdersAgreement _sha) private {
        IRegisterOfDirectors _rod = _gk.getROD();

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
        IRegisterOfMembers _rom = _gk.getROM();

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

    function acceptSHA(bytes32 sigHash, address msgSender) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);

        IShareholdersAgreement _sha = _gk.getSHA();
        _sha.addBlank(false, true, 1, caller);
        _sha.signDoc(false, caller, sigHash);
    }
}
