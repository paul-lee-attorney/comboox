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

import "../../comps/keepers/IGMMKeeper.sol";

import "../../comps/common/access/RoyaltyCharge.sol";
import "../../lib/LibOfGMMK.sol";

contract FundGMMKeeper is IGMMKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    using ArrayUtils for uint[];
    using InterfacesHub for address;

    function _gpOrManager(uint caller) private view{
        require(gk.getROM().isClassMember(caller, 1) || 
            gk.getROD().isDirector(caller), 
            "GMMK: no right");
    }

    function _onlyGP(uint caller) private view{
        require(gk.getROM().isClassMember(caller, 1), 
            "GMMK: not GP");
    }

    // ==== CreateMotion ====

    // ---- Officers ----
    function nominateDirector(
        uint256 seqOfPos,
        uint candidate
    ) external onlyDK  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 72000);

        _onlyGP(caller);

        gk.getGMM().nominateOfficer(
            seqOfPos, 
            gk.getROD().getPosition(seqOfPos).seqOfVR, 
            candidate, 
            caller
        );
    }

    function createMotionToRemoveDirector(
        uint256 seqOfPos
    ) external onlyDK  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 116000);

        require(gk.getROM().isMember(caller), 
            "GMMK: has no right");

        uint seqOfVR = gk.getROD().getPosition(seqOfPos).seqOfVR;

        // _onlyVRClass(seqOfVR, caller);

        gk.getGMM().createMotionToRemoveOfficer(
            seqOfPos, 
            seqOfVR, 
            caller
        );
    }

    function proposeDocOfGM(
        uint doc,
        uint seqOfVR,
        uint executor
    ) external onlyDK  onlyGKProxy {
        
        uint caller = _msgSender(msg.sender, 116000);

        require(gk.getROM().isMember(caller), "GMMK: NOT Member");

        // _onlyVRClass(seqOfVR, caller);

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
    ) external onlyDK  onlyGKProxy {

        uint caller = _msgSender(msg.sender, 68000);

        _gpOrManager(caller);

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
    ) external onlyDK  onlyGKProxy {

        uint caller = _msgSender(msg.sender, 99000);

        _gpOrManager(caller);        

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
    ) external onlyDK  onlyGKProxy {

        uint caller = _msgSender(msg.sender, 99000);

        _gpOrManager(caller);

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
    ) external onlyDK  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);

        _avoidanceCheck(seqOfMotion, caller);

        gk.getGMM().entrustDelegate(seqOfMotion, delegate, caller);
    }

    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion
    ) external onlyDK  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 72000);

        gk.getGMM().proposeMotionToGeneralMeeting(seqOfMotion, caller);
    }

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external onlyDK  onlyGKProxy {
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

    function voteCountingOfGM(uint256 seqOfMotion) external onlyDK  onlyGKProxy {
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
    ) external onlyDK  onlyGKProxy {
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
