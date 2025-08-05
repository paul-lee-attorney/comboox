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

import "../../lib/ArrayUtils.sol";
import "../../lib/BallotsBox.sol";
import "../../lib/BooksRepo.sol";
import "../../lib/MotionsRepo.sol";
import "../../lib/OfficersRepo.sol";
import "../../lib/RulesParser.sol";

import "../common/components/IMeetingMinutes.sol";
import "../common/components/ISigPage.sol";

import "../books/roc/IShareholdersAgreement.sol";
import "../books/rod/IRegisterOfDirectors.sol";

interface IBMMKeeper {

    event TransferFund(address indexed to, bool indexed isCBP, uint indexed amt, uint seqOfMotion, uint caller);
    event ExecAction(address indexed targets, uint indexed values, bytes indexed params, uint seqOfMotion, uint caller);

    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate,
        address msgSender
    ) external;

    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        address msgSender
    ) external;

    // ---- Docs ----

    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        address msgSender
    ) external;

    // ---- TransferFund ----

    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        address msgSender
    ) external;

    // ---- Action ----

    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        address msgSender
    ) external;

    // ==== Cast Vote ====

    function entrustDelegaterForBoardMeeting(
        uint256 seqOfMotion,
        uint delegate,
        address msgSender
    ) external;

    function proposeMotionToBoard (
        uint seqOfMotion,
        address msgSender
    ) external;

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        address msgSender
    ) external;

    // ==== Vote Counting ====

    function voteCounting(uint256 seqOfMotion, address msgSender) external;

    // ==== Exec Motion ====

    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        address msgSender
    ) external;

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        address msgSender
    ) external returns (uint);
}
