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

// import "../../lib/ArrayUtils.sol";
// import "../../lib/BallotsBox.sol";
import "../../lib/InterfacesHub.sol";
// import "../../lib/MotionsRepo.sol";
// import "../../lib/OfficersRepo.sol";
// import "../../lib/RulesParser.sol";

// import "../common/components/IMeetingMinutes.sol";
// import "../common/components/ISigPage.sol";

// import "../books/roc/IShareholdersAgreement.sol";
// import "../books/rod/IRegisterOfDirectors.sol";

/// @title IBMMKeeper
/// @notice Interface for board meeting motions and executions.
interface IBMMKeeper {

    /// @notice Nominate an officer for a position.
    /// @param seqOfPos Position sequence.
    /// @param candidate Candidate user number.
    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate
    ) external;

    /// @notice Create a motion to remove an officer.
    /// @param seqOfPos Position sequence.
    function createMotionToRemoveOfficer(
        uint256 seqOfPos
    ) external;

    // ---- Docs ----

    /// @notice Create a motion to approve a document.
    /// @param doc Document id.
    /// @param seqOfVR Voting rule sequence.
    /// @param executor Executor user number.
    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor
    ) external;

    // ---- TransferFund ----

    /// @notice Propose a fund transfer motion.
    /// @param to Recipient address.
    /// @param isCBP True if paid in CBP, false for USDC.
    /// @param amt Amount to transfer.
    /// @param expireDate Motion expiry timestamp.
    /// @param seqOfVR Voting rule sequence.
    /// @param executor Executor user number.
    function proposeToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external;

    // ---- Action ----

    /// @notice Create a motion to execute an arbitrary action.
    /// @param seqOfVR Voting rule sequence.
    /// @param targets Target contract list.
    /// @param values ETH values list.
    /// @param params Encoded params list.
    /// @param desHash Description hash.
    /// @param executor Executor user number.
    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    // ==== Cast Vote ====

    /// @notice Entrust voting to a delegate.
    /// @param seqOfMotion Motion sequence.
    /// @param delegate Delegate user number.
    function entrustDelegaterForBoardMeeting(
        uint256 seqOfMotion,
        uint delegate
    ) external;

    /// @notice Propose a motion to the board.
    /// @param seqOfMotion Motion sequence.
    function proposeMotionToBoard (
        uint seqOfMotion
    ) external;

    /// @notice Cast vote on a motion.
    /// @param seqOfMotion Motion sequence.
    /// @param attitude Vote attitude.
    /// @param sigHash Signature hash.
    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external;

    /// @notice Count votes for a motion.
    /// @param seqOfMotion Motion sequence.
    function voteCounting(uint256 seqOfMotion) external;

    // ==== Exec Motion ====

    /// @notice Execute an action motion.
    /// @param typeOfAction Action type.
    /// @param targets Target contract list.
    /// @param values ETH values list.
    /// @param params Encoded params list.
    /// @param desHash Description hash.
    /// @param seqOfMotion Motion sequence.
    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

}
