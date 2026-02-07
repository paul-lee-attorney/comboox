// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
 *
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

pragma solidity ^0.8.8;

import "./IBMMKs.sol";
import "../common/access/AccessControl.sol";

contract BMMKs is IBMMKs, AccessControl {
    
    // ###################
    // ##   BMMKeeper   ##
    // ###################

    function _getBMMK() private view returns(IBMMKeeper) {
        return IBMMKeeper(gk.getKeeper(uint8(Keepers.BMMK)));
    }

    function nominateOfficer(uint256 seqOfPos, uint candidate) external {
        _getBMMK().nominateOfficer(msg.sender, seqOfPos, candidate);
    }

    function createMotionToRemoveOfficer(uint256 seqOfPos) external {
        _getBMMK().createMotionToRemoveOfficer(msg.sender, seqOfPos);
    }

    function createMotionToApproveDoc(uint doc, uint seqOfVR, uint executor) external{
        _getBMMK().createMotionToApproveDoc(msg.sender, doc, seqOfVR, executor); 
    }

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external{
        _getBMMK().createAction(msg.sender, seqOfVR, targets, values, params, desHash, executor);
    }

    function entrustDelegaterForBoardMeeting(uint256 seqOfMotion, uint delegate) external {
        _getBMMK().entrustDelegaterForBoardMeeting(msg.sender, seqOfMotion, delegate); 
    }

    function proposeMotionToBoard (uint seqOfMotion) external {
        _getBMMK().proposeMotionToBoard(msg.sender, seqOfMotion);
    }

    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external{
        _getBMMK().castVote(msg.sender, seqOfMotion, attitude, sigHash);
    }

    function voteCounting(uint256 seqOfMotion) external{
        _getBMMK().voteCounting(msg.sender, seqOfMotion);
    }

}
