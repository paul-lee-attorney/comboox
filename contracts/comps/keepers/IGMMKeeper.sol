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
import "../../lib/SharesRepo.sol";
import "../../lib/WaterfallsRepo.sol";
import "../../lib/RulesParser.sol";

import "../common/components/IMeetingMinutes.sol";
import "../common/components/ISigPage.sol";

import "../books/rod/IRegisterOfDirectors.sol";
import "../books/rom/IRegisterOfMembers.sol";

/// @title IGMMKeeper
/// @notice Interface for general meeting motions and executions.
interface IGMMKeeper {
    // event DistributeProfits(uint256 indexed sum, uint indexed seqOfMotion, uint indexed caller);
    // event TransferFund(address indexed to, bool indexed isCBP, uint indexed amt, uint seqOfMotion, uint caller);
    /// @notice Emitted when a general meeting action is executed.
    /// @param targets Target contract address.
    /// @param values ETH value.
    /// @param params Encoded parameters blob.
    /// @param seqOfMotion Motion sequence.
    /// @param caller Caller user number.
    event ExecAction(address indexed targets, uint indexed values, bytes indexed params, uint seqOfMotion, uint caller);

    // ################
    // ##   Motion   ##
    // ################

    /// @notice Nominate a director for a position.
    /// @param seqOfPos Position sequence.
    /// @param candidate Candidate user number.
    /// @param msgSender Caller address.
    function nominateDirector(
        uint256 seqOfPos,
        uint candidate,
        address msgSender
    ) external;

    /// @notice Create a motion to remove a director.
    /// @param seqOfPos Position sequence.
    /// @param msgSender Caller address.
    function createMotionToRemoveDirector(
        uint256 seqOfPos,
        address msgSender
    ) external;

    /// @notice Propose a document for general meeting approval.
    /// @param doc Document id.
    /// @param seqOfVR Voting rule sequence.
    /// @param executor Executor user number.
    /// @param msgSender Caller address.
    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor,  address msgSender) external;

    /// @notice Propose a USDC distribution motion.
    /// @param amt Amount to distribute.
    /// @param expireDate Motion expiry timestamp.
    /// @param seqOfVR Voting rule sequence.
    /// @param seqOfDR Distribution rule sequence.
    /// @param para Extra parameter.
    /// @param executor Executor user number.
    /// @param msgSender Caller address.
    function proposeToDistributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint seqOfDR,
        uint para,
        uint executor,
        address msgSender
    ) external;

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

    /// @notice Create a general meeting action motion.
    /// @param seqOfVR Voting rule sequence.
    /// @param targets Target contract list.
    /// @param values ETH values list.
    /// @param params Encoded params list.
    /// @param desHash Description hash.
    /// @param executor Executor user number.
    /// @param msgSender Caller address.
    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        address msgSender
    ) external;

    /// @notice Propose deprecating the general keeper.
    /// @param receiver New receiver address.
    /// @param msgSender Caller address.
    function proposeToDeprecateGK(address receiver,address msgSender) external;

    /// @notice Entrust voting to a delegate for GM.
    /// @param seqOfMotion Motion sequence.
    /// @param delegate Delegate user number.
    /// @param msgSender Caller address.
    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate, address msgSender) external;

    /// @notice Propose a motion to general meeting.
    /// @param seqOfMotion Motion sequence.
    /// @param msgSender Caller address.
    function proposeMotionToGeneralMeeting(uint256 seqOfMotion, address msgSender) external;

    /// @notice Cast vote on a GM motion.
    /// @param seqOfMotion Motion sequence.
    /// @param attitude Vote attitude.
    /// @param sigHash Signature hash.
    /// @param msgSender Caller address.
    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        address msgSender
    ) external;

    /// @notice Count votes for a GM motion.
    /// @param seqOfMotion Motion sequence.
    /// @param msgSender Caller address.
    function voteCountingOfGM(uint256 seqOfMotion, address msgSender) external;

    /// @notice Execute a GM action motion.
    /// @param typeOfAction Action type.
    /// @param targets Target contract list.
    /// @param values ETH values list.
    /// @param params Encoded params list.
    /// @param desHash Description hash.
    /// @param seqOfMotion Motion sequence.
    /// @param msgSender Caller address.
    /// @return result Execution result code.
    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        address msgSender
    ) external returns(uint);

    /// @notice Deprecate the general keeper.
    /// @param receiver New receiver address.
    /// @param seqOfMotion Motion sequence.
    /// @param msgSender Caller address.
    function deprecateGK(address receiver, uint seqOfMotion, address msgSender) external;
}
