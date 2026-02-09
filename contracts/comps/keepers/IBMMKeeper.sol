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

pragma solidity ^0.8.8;

import "../../lib/ArrayUtils.sol";
import "../../lib/BallotsBox.sol";
import "../../lib/InterfacesHub.sol";
import "../../lib/MotionsRepo.sol";
import "../../lib/OfficersRepo.sol";
import "../../lib/RulesParser.sol";

import "../common/components/IMeetingMinutes.sol";
import "../common/components/ISigPage.sol";

import "../books/roc/IShareholdersAgreement.sol";
import "../books/rod/IRegisterOfDirectors.sol";

/// @title IBMMKeeper
/// @notice Interface for board meeting motions and executions.
interface IBMMKeeper {

    /// @notice Emitted when a board motion transfers funds.
    /// @param to Recipient address.
    /// @param isCBP True if paid in CBP, false for USDC.
    /// @param amt Amount transferred.
    /// @param seqOfMotion Motion sequence.
    /// @param caller Caller user number.
    event TransferFund(address indexed to, bool indexed isCBP, uint indexed amt, uint seqOfMotion, uint caller);
    /// @notice Emitted when a board motion executes an action.
    /// @param targets Target contract address.
    /// @param values ETH value.
    /// @param params Encoded parameters blob.
    /// @param seqOfMotion Motion sequence.
    /// @param caller Caller user number.
    event ExecAction(address indexed targets, uint indexed values, bytes indexed params, uint seqOfMotion, uint caller);

    /// @notice Nominate an officer for a position.
    /// @param seqOfPos Position sequence.
    /// @param candidate Candidate user number.
    /// @param msgSender Caller address.
    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate,
        address msgSender
    ) external;

    /// @notice Create a motion to remove an officer.
    /// @param seqOfPos Position sequence.
    /// @param msgSender Caller address.
    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        address msgSender
    ) external;

    // ---- Docs ----

    /// @notice Create a motion to approve a document.
    /// @param doc Document id.
    /// @param seqOfVR Voting rule sequence.
    /// @param executor Executor user number.
    /// @param msgSender Caller address.
    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        address msgSender
    ) external;

    // ---- TransferFund ----

    /// @notice Propose a fund transfer motion.
    /// @param to Recipient address.
    /// @param isCBP True if paid in CBP, false for USDC.
    /// @param amt Amount to transfer.
    /// @param expireDate Motion expiry timestamp.
    /// @param seqOfVR Voting rule sequence.
    /// @param executor Executor user number.
    /// @param msgSender Caller address.
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

    /// @notice Create a motion to execute an arbitrary action.
    /// @param seqOfVR Voting rule sequence.
    /// @param targets Target contract list.
    /// @param values ETH values list.
    /// @param params Encoded params list.
    /// @param desHash Description hash.
    /// @param executor Executor user number.
    /// @param msgSender Caller address.
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

    /// @notice Entrust voting to a delegate.
    /// @param seqOfMotion Motion sequence.
    /// @param delegate Delegate user number.
    /// @param msgSender Caller address.
    function entrustDelegaterForBoardMeeting(
        uint256 seqOfMotion,
        uint delegate,
        address msgSender
    ) external;

    /// @notice Propose a motion to the board.
    /// @param seqOfMotion Motion sequence.
    /// @param msgSender Caller address.
    function proposeMotionToBoard (
        uint seqOfMotion,
        address msgSender
    ) external;

    /// @notice Cast vote on a motion.
    /// @param seqOfMotion Motion sequence.
    /// @param attitude Vote attitude.
    /// @param sigHash Signature hash.
    /// @param msgSender Caller address.
    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        address msgSender
    ) external;

    // ==== Vote Counting ====

    /// @notice Count votes for a motion.
    /// @param seqOfMotion Motion sequence.
    /// @param msgSender Caller address.
    function voteCounting(uint256 seqOfMotion, address msgSender) external;

    // ==== Exec Motion ====

    /// @notice Execute a transfer fund motion.
    /// @param to Recipient address.
    /// @param isCBP True if paid in CBP, false for USDC.
    /// @param amt Amount to transfer.
    /// @param expireDate Motion expiry timestamp.
    /// @param seqOfMotion Motion sequence.
    /// @param msgSender Caller address.
    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        address msgSender
    ) external;

    /// @notice Execute an action motion.
    /// @param typeOfAction Action type.
    /// @param targets Target contract list.
    /// @param values ETH values list.
    /// @param params Encoded params list.
    /// @param desHash Description hash.
    /// @param seqOfMotion Motion sequence.
    /// @param msgSender Caller address.
    /// @return result Execution result code.
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
