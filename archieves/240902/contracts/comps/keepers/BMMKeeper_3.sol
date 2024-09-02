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

import "../common/access/RoyaltyCharge.sol";

import "./IBMMKeeper_2.sol";

contract BMMKeeper_3 is IBMMKeeper_2, RoyaltyCharge {

    using RulesParser for bytes32;

    //###############
    //##   Write   ##
    //###############

    // ==== CreateMotion ====

    // ---- Officers ----

    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);

        IRegisterOfDirectors _rod = _gk.getROD();
        
        require(_rod.hasNominationRight(seqOfPos, caller),
            "BMMKeeper.nominateOfficer: no rights");
     
        _gk.getBMM().nominateOfficer(seqOfPos, _rod.getPosition(seqOfPos).seqOfVR, candidate, caller);
    }

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);
        
        require(_gk.getROD().isDirector(caller), "BMMK: not director");

        IRegisterOfDirectors _rod = _gk.getROD();
        
        require(_rod.hasNominationRight(seqOfPos, caller),
            "BMMK.createMotionToRemoveOfficer: no rights");

        _gk.getBMM().createMotionToRemoveOfficer(seqOfPos, _rod.getPosition(seqOfPos).seqOfVR, caller);
    }

    // ---- Docs ----

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);        
        require(_gk.getROD().isDirector(caller), "BMMK: not director");

        _gk.getBMM().createMotionToApproveDoc(doc, seqOfVR, executor, caller);
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
        uint caller = _msgSender(msgSender, 66000);        
        require(_gk.getROD().isDirector(caller), "BMMK: not director");
        
        IMeetingMinutes _bmm = _gk.getBMM();

        require (amt < uint(_gk.getSHA().getRule(0).governanceRuleParser().fundApprovalThreshold) * 10 ** 18,
            "BMMK.transferFund: amt overflow");

        uint64 seqOfMotion = 
            _bmm.createMotionToTransferFund(to, isCBP, amt, expireDate, seqOfVR, executor, caller);
        _bmm.proposeMotionToBoard(seqOfMotion, caller);            
    }

    // ---- Actions ----

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 66000);        
        require(_gk.getROD().isDirector(caller), "BMMK: not director");

        _gk.getBMM().createAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            caller
        );
    }

    // ==== Cast Vote ====

    function entrustDelegaterForBoardMeeting(
        uint256 seqOfMotion,
        uint delegate,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);        
        require(_gk.getROD().isDirector(caller), "BMMK: not director");

        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToBoard (
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);        
        require(_gk.getROD().isDirector(caller), "BMMK: not director");

        _gk.getBMM().proposeMotionToBoard(seqOfMotion, caller);
    }

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);        

        _avoidanceCheck(seqOfMotion, caller);
        _gk.getBMM().castVoteInBoardMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint caller) private view {

        MotionsRepo.Motion memory motion = _gk.getBMM().getMotion(seqOfMotion);

        if (motion.head.typeOfMotion == 
                uint8(MotionsRepo.TypeOfMotion.ApproveDoc) &&
                motion.head.seqOfVR < 9) 
        {
            address doc = address(uint160(motion.contents));
            
            OfficersRepo.Position[] memory poses = 
                _gk.getROD().getFullPosInfoInHand(caller);
            uint256 len = poses.length;            
            while (len > 0) {
                require (!ISigPage(doc).isSigner(poses[len-1].nominator), 
                    "BMMK.RPC: is related party");
                len --;
            }
            require (!ISigPage(doc).isSigner(caller), 
                "BMMK.RPC: is related party");

        }
    }

    // ==== Vote Counting ====

    function voteCounting(uint256 seqOfMotion, address msgSender)
        external onlyDK
    {
        _msgSender(msgSender, 58000);
        
        IRegisterOfDirectors _rod = _gk.getROD();
        IMeetingMinutes _bmm = _gk.getBMM();
        
        MotionsRepo.Motion memory motion = 
            _bmm.getMotion(seqOfMotion);

        MotionsRepo.VoteCalBase memory base;
        BallotsBox.Case memory case0 = _bmm.getCaseOfAttitude(seqOfMotion, 0);
        BallotsBox.Case memory case3 = _bmm.getCaseOfAttitude(seqOfMotion, 3);

        uint32 numOfDirectors = uint32(_rod.getNumOfDirectors());
        base.attendHeadRatio = uint16(case0.sumOfHead * 10000 / numOfDirectors);

        if (motion.votingRule.onlyAttendance) {
            base.totalHead = case0.sumOfHead - case3.sumOfHead;
        } else {
            base.totalHead = numOfDirectors - case3.sumOfHead;
            if (motion.votingRule.impliedConsent) {
                base.supportHead = (base.totalHead - case0.sumOfHead);

                base.attendHeadRatio = 10000;                
            }
        }

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc)) 
        {
            uint256[] memory parties = 
                ISigPage((address(uint160(motion.contents)))).getParties();
            uint256 len = parties.length;

            while (len > 0) {
                uint32 voteHead = 
                    uint32(_rod.getBoardSeatsOccupied(uint40(parties[len - 1])));

                if (voteHead > 0) {
                    if (motion.votingRule.partyAsConsent) {

                        if (motion.votingRule.onlyAttendance) {
                            base.totalHead += voteHead;
                        }

                        if (!motion.votingRule.impliedConsent) {
                            base.supportHead += voteHead;

                            base.attendHeadRatio += uint16(voteHead * 10000 / numOfDirectors);
                        }
                    } else {
                        if (!motion.votingRule.onlyAttendance) {
                            base.totalHead -= voteHead;
                        }
                        
                        if (motion.votingRule.impliedConsent) {
                            base.supportHead -= voteHead;
                        } else {
                            base.attendHeadRatio += uint16(voteHead * 10000 / numOfDirectors);
                        }

                        if (base.totalHead == 0)
                            base.unaniConsent = true;
                    }
                }

                len--;
            }                
        }
        

        IShareholdersAgreement _sha = _gk.getSHA();

        bool quorumFlag = (address(_sha) == address(0) || 
            base.attendHeadRatio >= 
            _sha.getRule(0).governanceRuleParser().quorumOfBoardMeeting);

        _bmm.voteCounting(quorumFlag, seqOfMotion, base);
    }

    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 38000);        

        _gk.getBMM().transferFund(
            to,
            isCBP,
            amt,
            expireDate,
            seqOfMotion,
            caller
        );

        emit TransferFund(to, isCBP, amt, seqOfMotion, caller);
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        address msgSender
    ) external returns (uint) {
        uint caller = _msgSender(msgSender, 18000);        

        uint len = targets.length;
        while (len > 0) {
            emit ExecAction(targets[len-1], values[len-1], params[len-1], seqOfMotion, caller);
            len--;
        }

        return _gk.getBMM().execAction(
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion,
            caller
        );
    }
}
