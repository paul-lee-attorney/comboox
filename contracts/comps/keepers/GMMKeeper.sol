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

import "./IGMMKeeper.sol";
import "../common/access/RoyaltyCharge.sol";
import "../../lib/InterfacesHub.sol";
import "../../lib/LibOfGMMK.sol";

contract GMMKeeper is IGMMKeeper, RoyaltyCharge {
    using InterfacesHub for address;

    // ################
    // ##   Motion   ##
    // ################

    // ==== CreateMotion ====

    // ---- Officers ----
    function nominateDirector(
        uint256 seqOfPos,
        uint candidate
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 72000);

        IRegisterOfDirectors _rod = gk.getROD();

        require(_rod.hasNominationRight(seqOfPos, caller),
            "GMMK: has no right");

        gk.getGMM().nominateOfficer(
            seqOfPos, 
            _rod.getPosition(seqOfPos).seqOfVR, 
            candidate, 
            caller
        );
    }

    function createMotionToRemoveDirector(
        uint256 seqOfPos
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 116000);

        IRegisterOfDirectors _rod = gk.getROD();

        require(_rod.hasNominationRight(seqOfPos, caller),
            "GMMK: has no right");

        gk.getGMM().createMotionToRemoveOfficer(
            seqOfPos, 
            _rod.getPosition(seqOfPos).seqOfVR, 
            caller
        );
    }

    function proposeDocOfGM(
        uint doc,
        uint seqOfVR,
        uint executor
    ) external onlyGKProxy {
        
        uint caller = _msgSender(msg.sender, 116000);
        require(gk.getROM().isMember(caller), "GMMK: NOT Member");

        IMeetingMinutes _gmm = gk.getGMM();

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
                gk.getROC().proposeFile(addr, seqOfMotion);
            } else {
                require(gk.getROA().allClaimsAccepted(addr),
                    "GMMK: Claims outstanding");
                gk.getROA().proposeFile(addr, seqOfMotion);
            }
        }
    }

    function proposeToDistributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint seqOfDR,
        uint para,
        uint executor
    ) external onlyGKProxy {

        uint caller = _msgSender(msg.sender, 68000);
        require(gk.getROM().isMember(caller) || gk.getROD().isDirector(caller), 
            "GMMK: no right");

        IMeetingMinutes _gmm = gk.getGMM();

        uint64 seqOfMotion = 
            _gmm.createMotionToDistributeUsd(amt, expireDate, seqOfVR, seqOfDR, para, executor, caller);
            
        _gmm.proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external onlyGKProxy {

        uint caller = _msgSender(msg.sender, 99000);
        require(gk.getROM().isMember(caller) || gk.getROD().isDirector(caller), 
            "GMMK: no right");
        
        IMeetingMinutes _gmm = gk.getGMM();

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
        uint executor
    ) external onlyGKProxy {

        uint caller = _msgSender(msg.sender, 99000);
        require(gk.getROM().isMember(caller) || gk.getROD().isDirector(caller), 
            "GMMK: no right");

        gk.getGMM().createAction(
            seqOfVR,
            targets,
            values,
            params,
            desHash,
            executor,
            caller
        );
    }

    // ==== ProposeMotion ====

    function entrustDelegaterForGeneralMeeting(
        uint256 seqOfMotion,
        uint delegate
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);

        _avoidanceCheck(seqOfMotion, caller);
        gk.getGMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 72000);

        gk.getGMM().proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 72000);

        _avoidanceCheck(seqOfMotion, caller);
        gk.getGMM().castVoteInGeneralMeeting(seqOfMotion, attitude, sigHash, caller);
    }

    function _avoidanceCheck(uint256 seqOfMotion, uint caller) private view {
        MotionsRepo.Motion memory motion = gk.getGMM().getMotion(seqOfMotion);

        require( motion.votingRule.class == 0 ||
            gk.getROM().isClassMember(caller, motion.votingRule.class),
            "GMMK: not Class member");

        if (motion.head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ApproveDoc) && 
            motion.head.seqOfVR < 9) 
        {
            address doc = address(uint160(motion.contents));
            require (!ISigPage(doc).isSigner(caller),
                "GMMK: is related party");
        }
    }

    function voteCountingOfGM(uint256 seqOfMotion) external onlyGKProxy {
        _msgSender(msg.sender, 88000);
        LibOfGMMK.voteCountingOfGM(seqOfMotion);
    }
    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);
        LibOfGMMK.execActionOfGM(
            caller,
            typeOfAction,
            targets,
            values,
            params,
            desHash,
            seqOfMotion
        );
    }
}
