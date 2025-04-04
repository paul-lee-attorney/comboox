// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
 *
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

import "./IGMMKeeper.sol";

import "../common/access/RoyaltyCharge.sol";

contract GMMKeeper is IGMMKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    using ArrayUtils for uint[];

    // ################
    // ##   Motion   ##
    // ################

    // ==== CreateMotion ====

    // ---- Officers ----
    function nominateDirector(
        uint256 seqOfPos,
        uint candidate,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 72000);

        IRegisterOfDirectors _rod = _gk.getROD();

        require(_rod.hasNominationRight(seqOfPos, caller),
            "GMMK: has no right");

        _gk.getGMM().nominateOfficer(
            seqOfPos, 
            _rod.getPosition(seqOfPos).seqOfVR, 
            candidate, 
            caller
        );
    }

    function createMotionToRemoveDirector(
        uint256 seqOfPos,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 116000);

        IRegisterOfDirectors _rod = _gk.getROD();

        require(_rod.hasNominationRight(seqOfPos, caller),
            "GMMK: has no right");

        _gk.getGMM().createMotionToRemoveOfficer(
            seqOfPos, 
            _rod.getPosition(seqOfPos).seqOfVR, 
            caller
        );
    }

    function proposeDocOfGM(
        uint doc,
        uint seqOfVR,
        uint executor,
        address msgSender
    ) external onlyDK {
        
        uint caller = _msgSender(msgSender, 116000);
        require(_gk.getROM().isMember(caller), "GMMK: NOT Member");

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToApproveDoc(doc, seqOfVR, executor, caller);
            
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, caller);            

        if (seqOfVR < 9) {

            address addr = address(uint160(doc));

            require(ISigPage(addr).isSigner(caller), 
                "GMMK: not signer");

            require(ISigPage(addr).established(),
                "GMMK: not established");

            if (seqOfVR == 8) {
                _gk.getROC().proposeFile(addr, seqOfMotion);
            } else {
                require(_gk.getROA().allClaimsAccepted(addr),
                    "GMMK: Claims outstanding");
                _gk.getROA().proposeFile(addr, seqOfMotion);
            }
        }
    }

    function proposeToDistributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 68000);
        require(_gk.getROM().isMember(caller) || _gk.getROD().isDirector(caller), 
            "GMMK: no right");

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToDistributeProfits(amt, expireDate, seqOfVR, executor, caller);
            
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 99000);
        require(_gk.getROM().isMember(caller) || _gk.getROD().isDirector(caller), 
            "GMMK: no right");
        
        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToTransferFund(to, isCBP, amt, expireDate, seqOfVR, executor, caller);

        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, caller);            
    }

    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 99000);
        require(_gk.getROM().isMember(caller) || _gk.getROD().isDirector(caller), 
            "GMMK: no right");

        _gk.getGMM().createAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            caller
        );
    }

    function proposeToDeprecateGK(
        address receiver,
        address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 88000);
        require(_gk.getROM().isMember(caller) || _gk.getROD().isDirector(caller), 
            "GMMK: no right");

        IMeetingMinutes _gmm = _gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToDeprecateGK(receiver, caller);
            
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    // ==== ProposeMotion ====

    function entrustDelegaterForGeneralMeeting(
        uint256 seqOfMotion,
        uint delegate,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);

        _avoidanceCheck(seqOfMotion, caller);
        _gk.getGMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        address msgSender
    ) external onlyKeeper {
        uint caller = _msgSender(msgSender, 72000);

        _gk.getGMM().proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 72000);

        _avoidanceCheck(seqOfMotion, caller);
        _gk.getGMM().castVoteInGeneralMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint caller) private view {
        MotionsRepo.Motion memory motion = _gk.getGMM().getMotion(seqOfMotion);

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc) && 
            motion.head.seqOfVR < 9) 
        {
            address doc = address(uint160(motion.contents));
            require (!ISigPage(doc).isSigner(caller),
                "GMMK: is related party");
        }
    }

    // ==== VoteCounting ====

    function _allConsent(
        IMeetingMinutes _gmm, 
        IRegisterOfMembers _rom, 
        MotionsRepo.Motion memory motion,
        BallotsBox.Case memory case0
    ) private view returns(bool) {

        BallotsBox.Case memory case1 = _gmm.getCaseOfAttitude(motion.head.seqOfMotion, 1);         
        uint[] memory consentVoters = case1.voters.combine(case1.principals);

        uint[] memory allVoters = case0.voters.combine(case0.principals);

        if (allVoters.length > consentVoters.length) return false;

        uint[] memory members = _rom.membersList();
        uint[] memory restMembers = members.minus(consentVoters);

        if (restMembers.length == 0) return true;
            
        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) {

            uint256[] memory parties = 
                ISigPage(address(uint160(motion.contents))).getParties();

            uint[] memory vetoMembers = restMembers.minus(parties);

            uint len = vetoMembers.length;

            while (len > 0) { 
                if (_rom.votesAtDate(vetoMembers[len - 1], motion.body.shareRegDate) > 0) return false;
                len--;
            }

            return true;
        }

        return false;
    } 

    function _calBase(
        IMeetingMinutes _gmm,
        IRegisterOfMembers _rom,
        MotionsRepo.Motion memory motion,
        MotionsRepo.VoteCalBase memory base,
        BallotsBox.Case memory case0
    ) private view returns (MotionsRepo.VoteCalBase memory){

        BallotsBox.Case memory case3 = _gmm.getCaseOfAttitude(motion.head.seqOfMotion, 3);

        uint64 votesOfMembers = _rom.totalVotes();

        base.attendWeightRatio = uint16(case0.sumOfWeight * 10000 / votesOfMembers);

        if (motion.votingRule.onlyAttendance) {

            base.totalHead = (case0.sumOfHead - case3.sumOfHead);
            base.totalWeight = (case0.sumOfWeight - case3.sumOfWeight);

        } else {

            base.totalHead = uint32(_rom.qtyOfMembers());
            base.totalWeight = votesOfMembers; 

            if (motion.votingRule.impliedConsent) {

                base.supportHead = base.totalHead - case0.sumOfHead;                
                base.supportWeight = base.totalWeight > case0.sumOfWeight
                        ? (base.totalWeight - case0.sumOfWeight)
                        : 0;
                base.attendWeightRatio = 10000;
            }

            base.totalHead -= case3.sumOfHead;
            base.totalWeight = base.totalWeight > case3.sumOfWeight
                    ? base.totalWeight - case3.sumOfWeight
                    : 0 ;
        }

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) {

            uint256[] memory parties = 
                ISigPage(address(uint160(motion.contents))).getParties();
            uint256 len = parties.length;

            while (len > 0) {
                uint64 votesAtDate = 
                    _rom.votesAtDate(parties[len - 1], motion.body.shareRegDate);

                if (votesAtDate > 0) {
                    if (motion.votingRule.partyAsConsent) {

                        if (motion.votingRule.onlyAttendance) {
                            base.totalHead++;
                            base.totalWeight += votesAtDate;
                        }

                        if (!motion.votingRule.impliedConsent) {
                            base.supportHead ++;
                            base.supportWeight += votesAtDate;

                            base.attendWeightRatio += uint16(votesAtDate * 10000 / votesOfMembers);
                        }
                        
                    } else {

                        if (!motion.votingRule.onlyAttendance) {
                            base.totalHead --;

                            base.totalWeight = base.totalWeight > votesAtDate
                                    ? base.totalWeight - votesAtDate
                                    : 0;
                        }

                        if (motion.votingRule.impliedConsent) {
                            base.supportHead --;

                            base.supportWeight = base.supportWeight > votesAtDate
                                    ? base.supportWeight - votesAtDate
                                    : 0;
                        } else {
                            base.attendWeightRatio += uint16(votesAtDate * 10000 / votesOfMembers);
                        }
                    }
                }

                len--;
            }                
        }

        return base;
    }


    function voteCountingOfGM(uint256 seqOfMotion, address msgSender) external onlyDK {
        _msgSender(msgSender, 88000);
        
        IRegisterOfMembers _rom = _gk.getROM();
        IMeetingMinutes _gmm = _gk.getGMM();

        MotionsRepo.Motion memory motion = 
            _gmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;

        BallotsBox.Case memory case0 = _gmm.getCaseOfAttitude(motion.head.seqOfMotion, 0);

        if (_allConsent(_gmm, _rom, motion, case0)) {
            base.unaniConsent = true;
        } else {
            base = _calBase(_gmm, _rom, motion, base, case0);
        }

        bool quorumFlag = (address(_gk.getSHA()) == address(0)|| 
            base.attendWeightRatio >= 
            _gk.getSHA().getRule(0).governanceRuleParser().quorumOfGM);

        bool approved = _gmm.voteCounting(quorumFlag, seqOfMotion, base) == 
            uint8(MotionsRepo.StateOfMotion.Passed);

        if (motion.head.seqOfVR < 9) {

            address doc = address(uint160(motion.contents));

            if (motion.head.seqOfVR == 8)
                _gk.getROC().voteCountingForFile(doc, approved);
            else _gk.getROA().voteCountingForFile(doc, approved);
        }
    }

    // ==== execute ====

    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        IRegisterOfMembers _rom = _gk.getROM();

        _gk.getGMM().distributeProfits(
            amt,
            expireDate,
            seqOfMotion,
            caller
        );

        uint[] memory members = _rom.membersList();
        uint len = members.length;

        uint totalPoints = _rom.ownersPoints().points;
        uint sum = 0;

        while (len > 1) {
            uint member = members[len - 1];
            uint pointsOfMember = _rom.pointsOfMember(member).points;
            uint value = pointsOfMember * amt / totalPoints;
            
            // reason: DistributeProfits
            _gk.saveToCoffer(member, value, bytes32(0x4469737472696275746550726f66697473000000000000000000000000000000));
            sum += value;

            len--;
        }
            // reason: DistributeProfits
        _gk.saveToCoffer(members[0], amt-sum, bytes32(0x4469737472696275746550726f66697473000000000000000000000000000000));

        emit DistributeProfits(amt, seqOfMotion, caller);
    }

    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 76000);

        _gk.getGMM().transferFund(
            to,
            isCBP,
            amt,
            expireDate,
            seqOfMotion,
            caller
        );

        emit TransferFund(to, isCBP, amt, seqOfMotion, caller);
    }

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        address msgSender
    ) external onlyDK returns (uint){
        uint caller = _msgSender(msgSender, 36000);

        uint len = targets.length;
        while (len > 0) {
            emit ExecAction(targets[len-1], values[len-1], params[len-1], seqOfMotion, caller);
            len--;
        }

        return _gk.getGMM().execAction(
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            caller
        );
    }

    function deprecateGK(
        address receiver,
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        _gk.getGMM().deprecateGK(
            receiver,
            seqOfMotion,
            caller
        );
    }

}
