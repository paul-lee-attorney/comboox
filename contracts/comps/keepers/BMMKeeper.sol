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

import "../common/access/RoyaltyCharge.sol";

import "./IBMMKeeper.sol";
import "../../openzeppelin/utils/Address.sol";
import "../../lib/LibOfBMMK.sol";

contract BMMKeeper is IBMMKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    using InterfacesHub for address;
    using Address for address;

    //###############
    //##   Write   ##
    //###############

    // ==== CreateMotion ====

    // ---- Officers ----

    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);

        IRegisterOfDirectors _rod = gk.getROD();
        
        require(_rod.hasNominationRight(seqOfPos, caller),
            "BMMKeeper.nominateOfficer: no rights");
     
        gk.getBMM().nominateOfficer(seqOfPos, _rod.getPosition(seqOfPos).seqOfVR, candidate, caller);
    }

    function createMotionToRemoveOfficer(
        uint256 seqOfPos
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);
        
        require(gk.getROD().isDirector(caller), "BMMK: not director");

        IRegisterOfDirectors _rod = gk.getROD();
        
        require(_rod.hasNominationRight(seqOfPos, caller),
            "BMMK.createMotionToRemoveOfficer: no rights");

        gk.getBMM().createMotionToRemoveOfficer(seqOfPos, _rod.getPosition(seqOfPos).seqOfVR, caller);
    }

    // ---- Docs ----

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);        
        require(gk.getROD().isDirector(caller), "BMMK: not director");

        gk.getBMM().createMotionToApproveDoc(doc, seqOfVR, executor, caller);
    }

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 66000);        
        require(gk.getROD().isDirector(caller), "BMMK: not director");
        
        IMeetingMinutes _bmm = gk.getBMM();

        require (amt <= 
            uint(gk.getSHA().getRule(0).governanceRuleParser().fundApprovalThreshold) * 
            (isCBP ? 10 ** 18 : 10 ** 6), "BMMK.transferFund: amt overflow");

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
        uint executor
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 66000);        
        require(gk.getROD().isDirector(caller), "BMMK: not director");

        gk.getBMM().createAction(
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
        uint delegate
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);        
        require(gk.getROD().isDirector(caller), "BMMK: not director");

        _avoidanceCheck(seqOfMotion, caller);
        gk.getBMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToBoard (
        uint seqOfMotion
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);        
        require(gk.getROD().isDirector(caller), "BMMK: not director");

        gk.getBMM().proposeMotionToBoard(seqOfMotion, caller);
    }

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);        

        _avoidanceCheck(seqOfMotion, caller);
        gk.getBMM().castVoteInBoardMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint caller) private view {

        MotionsRepo.Motion memory motion = gk.getBMM().getMotion(seqOfMotion);

        if (motion.head.typeOfMotion == 
                uint8(MotionsRepo.TypeOfMotion.ApproveDoc) &&
                motion.head.seqOfVR < 9) 
        {
            address doc = address(uint160(motion.contents));
            
            OfficersRepo.Position[] memory poses = 
                gk.getROD().getFullPosInfoInHand(caller);
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

    function voteCounting(uint256 seqOfMotion) external  onlyGKProxy {
        _msgSender(msg.sender, 58000);
        LibOfBMMK.voteCounting(seqOfMotion);
    }

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);
        LibOfBMMK.execAction(
            caller, typeOfAction, targets, values, 
            params, desHash, seqOfMotion
        );
    }

}
