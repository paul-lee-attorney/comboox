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

import "../../comps/common/access/RoyaltyCharge.sol";

import "../../comps/keepers/IROCKeeper.sol";
import "../../lib/TypesList.sol";

contract FundROCKeeper is IROCKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    using ArrayUtils for uint[];
    using InterfacesHub for address;
    
    // #############
    // ##   SHA   ##
    // #############

    function createSHA(
        uint version
    ) external onlyDK  onlyGKProxy {

        uint caller = _msgSender(msg.sender, 18000);

        require(gk.getROM().isClassMember(caller, 1), "not GP");

        DocsRepo.Doc memory doc = rc.getRC().cloneDoc(
            TypesList.ShareholdersAgreement, 
            version
        );

        IAccessControl(doc.body).initKeepers(
            address(this),
            address(gk)
        );

        IShareholdersAgreement(doc.body).initDefaultRules();

        gk.getROC().regFile(DocsRepo.codifyHead(doc.head), doc.body);

        IOwnable(doc.body).setNewOwner(msg.sender);
    }

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash
    ) external onlyDK  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);

        require(gk.getROM().isClassMember(caller, 1), "not GP");

        require(IDraftControl(sha).isFinalized(), 
            "BOHK.CSHA: SHA not finalized");
        
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
        address sha,
        bytes32 sigHash
    ) external onlyDK  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);

        require(ISigPage(sha).isParty(caller), "NOT Party of Doc");

        require(
            gk.getROC().getHeadOfFile(sha).state == uint8(FilesRepo.StateOfFile.Circulated),
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

    function activateSHA(address sha) external onlyDK  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);

        require(ISigPage(sha).isParty(caller), "NOT Party of Doc");
        
        IRegisterOfConstitution _roc = gk.getROC();
        IRegisterOfMembers _rom = gk.getROM();

        require(sha != address(0), "ROCK.actSHA: zero sha");
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

    function _regOptionTerms(IShareholdersAgreement _sha) private {
        address opts = _sha.getTerm(uint8(IShareholdersAgreement.TitleOfTerm.Options));
        gk.getROO().regOptionTerms(opts);
    }

    function _updatePositionSetting(IShareholdersAgreement _sha) private {
        IRegisterOfDirectors _rod = gk.getROD();

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
        IRegisterOfMembers _rom = gk.getROM();

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

    function acceptSHA(bytes32 sigHash) external onlyDK  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);

        IShareholdersAgreement _sha = gk.getSHA();
        _sha.addBlank(false, true, 1, caller);
        _sha.signDoc(false, caller, sigHash);
    }
}
