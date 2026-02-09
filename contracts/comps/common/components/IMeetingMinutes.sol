// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
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

import "../../../lib/BallotsBox.sol";
import "../../../lib/MotionsRepo.sol";
import "../../../lib/RulesParser.sol";
import "../../../lib/DelegateMap.sol";

import "../../books/roc/IShareholdersAgreement.sol";

/// @title IMeetingMinutes
/// @notice Interface for creating motions, voting, and executing resolutions.
interface IMeetingMinutes {

    //##################
    //##    events    ##
    //##################

    /// @notice Emitted when a motion is created.
    /// @param snOfMotion Encoded motion head (type/seq/VR/creator/executor/date).
    /// @param contents Encoded contents hash or payload.
    event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);

    /// @notice Emitted when a motion is proposed to the general meeting.
    /// @param seqOfMotion Motion sequence number.
    /// @param proposer Proposer account id.
    event ProposeMotionToGeneralMeeting(uint256 indexed seqOfMotion, uint256 indexed proposer);

    /// @notice Emitted when a motion is proposed to the board.
    /// @param seqOfMotion Motion sequence number.
    /// @param proposer Proposer account id.
    event ProposeMotionToBoard(uint256 indexed seqOfMotion, uint256 indexed proposer);

    /// @notice Emitted when a vote is delegated.
    /// @param seqOfMotion Motion sequence number.
    /// @param delegate Delegate account id.
    /// @param principal Principal account id.
    event EntrustDelegate(uint256 indexed seqOfMotion, uint256 indexed delegate, uint256 indexed principal);

    /// @notice Emitted when a vote is cast in the general meeting.
    /// @param seqOfMotion Motion sequence number.
    /// @param caller Voter account id.
    /// @param attitude Voting attitude (enum value defined by BallotsBox).
    /// @param sigHash Signature hash.
    event CastVoteInGeneralMeeting(uint256 indexed seqOfMotion, uint256 indexed caller, uint indexed attitude, bytes32 sigHash);    

    /// @notice Emitted when a vote is cast in the board meeting.
    /// @param seqOfMotion Motion sequence number.
    /// @param caller Voter account id.
    /// @param attitude Voting attitude (enum value defined by BallotsBox).
    /// @param sigHash Signature hash.
    event CastVoteInBoardMeeting(uint256 indexed seqOfMotion, uint256 indexed caller, uint indexed attitude, bytes32 sigHash);    

    /// @notice Emitted when vote counting completes.
    /// @param seqOfMotion Motion sequence number.
    /// @param result Vote counting result code.
    event VoteCounting(uint256 indexed seqOfMotion, uint8 indexed result);            

    /// @notice Emitted when a resolution is executed.
    /// @param seqOfMotion Motion sequence number.
    /// @param caller Executor account id.
    event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);

    //#################
    //##  Write I/O  ##
    //#################

    /// @notice Nominate an officer for a position.
    /// @param seqOfPos Position sequence number (> 0).
    /// @param seqOfVR Voting rule sequence number (> 0).
    /// @param canidate Candidate account id (> 0).
    /// @param nominator Nominator account id (> 0).
    function nominateOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint canidate,
        uint nominator
    ) external returns(uint64);

    /// @notice Create a motion to remove an officer.
    /// @param seqOfPos Position sequence number (> 0).
    /// @param seqOfVR Voting rule sequence number (> 0).
    /// @param nominator Nominator account id (> 0).
    function createMotionToRemoveOfficer(
        uint256 seqOfPos,
        uint seqOfVR,
        uint nominator    
    ) external returns(uint64);

    /// @notice Create a motion to approve a document.
    /// @param doc Document identifier (encoded or sequence number, > 0).
    /// @param seqOfVR Voting rule sequence number (> 0).
    /// @param executor Executor account id (> 0).
    /// @param proposer Proposer account id (> 0).
    function createMotionToApproveDoc(
        uint doc,
        uint seqOfVR,
        uint executor,
        uint proposer    
    ) external returns(uint64);

    /// @notice Create a motion to distribute USD profits.
    /// @param amt Amount to distribute (>= 0, in smallest unit).
    /// @param expireDate Expiration timestamp (> current time).
    /// @param seqOfVR Voting rule sequence number (> 0).
    /// @param seqOfDR Distribution rule sequence number (> 0).
    /// @param para Extra parameter encoded by rule (>= 0).
    /// @param executor Executor account id (> 0).
    /// @param proposer Proposer account id (> 0).
    function createMotionToDistributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint seqOfDR,
        uint para,
        uint executor,
        uint proposer
    ) external returns (uint64);

    /// @notice Create a motion to transfer funds.
    /// @param to Recipient address (non-zero).
    /// @param isCBP True if CBP token, false if USD.
    /// @param amt Amount to transfer (>= 0, in smallest unit).
    /// @param expireDate Expiration timestamp (> current time).
    /// @param seqOfVR Voting rule sequence number (> 0).
    /// @param executor Executor account id (> 0).
    /// @param proposer Proposer account id (> 0).
    function createMotionToTransferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external returns (uint64);

    /// @notice Create a motion to approve an action bundle.
    /// @param seqOfVR Voting rule sequence number (> 0).
    /// @param targets Target contract addresses (non-zero).
    /// @param values ETH values for each call (>= 0).
    /// @param params Calldata for each call.
    /// @param desHash Description hash (bytes32).
    /// @param executor Executor account id (> 0).
    /// @param proposer Proposer account id (> 0).
    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external returns(uint64);

    // function createMotionToDeprecateGK(address receiver,uint proposer) external returns(uint64);

    /// @notice Propose a motion to the general meeting.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param proposer Proposer account id (> 0).
    function proposeMotionToGeneralMeeting(
        uint256 seqOfMotion,
        uint proposer
    ) external;

    /// @notice Propose a motion to the board.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param caller Proposer account id (> 0).
    function proposeMotionToBoard (
        uint seqOfMotion,
        uint caller
    ) external;

    /// @notice Delegate voting power for a motion.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param delegate Delegate account id (> 0).
    /// @param principal Principal account id (> 0).
    function entrustDelegate(
        uint256 seqOfMotion,
        uint delegate, 
        uint principal
    ) external;

    // ==== Vote ====

    /// @notice Cast a vote in the general meeting.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param attitude Voting attitude (enum value defined by BallotsBox).
    /// @param sigHash Signature hash.
    /// @param caller Voter account id (> 0).
    function castVoteInGeneralMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    /// @notice Cast a vote in the board meeting.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param attitude Voting attitude (enum value defined by BallotsBox).
    /// @param sigHash Signature hash.
    /// @param caller Voter account id (> 0).
    function castVoteInBoardMeeting(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    // ==== UpdateVoteResult ====

    /// @notice Count votes for a motion.
    /// @param flag0 Context flag (implementation-defined).
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param base Vote calculation base data.
    function voteCounting(bool flag0, uint256 seqOfMotion, MotionsRepo.VoteCalBase memory base) 
        external returns(uint8);

    // ==== ExecResolution ====

    /// @notice Execute a resolution with verified contents.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param contents Encoded contents hash or payload.
    /// @param caller Executor account id (> 0).
    function execResolution(uint256 seqOfMotion, uint256 contents, uint caller)
        external;

    /// @notice Execute a USD distribution motion.
    /// @param amt Amount to distribute (>= 0, in smallest unit).
    /// @param expireDate Expiration timestamp (> current time).
    /// @param seqOfDR Distribution rule sequence number (> 0).
    /// @param para Extra parameter encoded by rule (>= 0).
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param caller Executor account id (> 0).
    function distributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint para,
        uint seqOfMotion,
        uint caller
    ) external;

    /// @notice Execute a fund transfer motion.
    /// @param to Recipient address (non-zero).
    /// @param isCBP True if CBP token, false if USD.
    /// @param amt Amount to transfer (>= 0, in smallest unit).
    /// @param expireDate Expiration timestamp (> current time).
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param caller Executor account id (> 0).
    function transferFund(
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        uint caller
    ) external;

    /// @notice Execute an approved action bundle.
    /// @param seqOfVR Voting rule sequence number (> 0).
    /// @param targets Target contract addresses (non-zero).
    /// @param values ETH values for each call (>= 0).
    /// @param params Calldata for each call.
    /// @param desHash Description hash (bytes32).
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param caller Executor account id (> 0).
    function execAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns(uint contents);

    /// @notice Deprecate the general keeper and set a receiver.
    /// @param receiver Receiver address (non-zero).
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param executor Executor account id (> 0).
    function deprecateGK(address receiver, uint seqOfMotion, uint executor) external;

    //################
    //##    Read    ##
    //################


    // ==== Motions ====

    /// @notice Check whether a motion is proposed.
    /// @param seqOfMotion Motion sequence number (> 0).
    function isProposed(uint256 seqOfMotion) external view returns (bool);

    /// @notice Check whether voting has started.
    /// @param seqOfMotion Motion sequence number (> 0).
    function voteStarted(uint256 seqOfMotion) external view returns (bool);

    /// @notice Check whether voting has ended.
    /// @param seqOfMotion Motion sequence number (> 0).
    function voteEnded(uint256 seqOfMotion) external view returns (bool);

    // ==== Delegate ====

    /// @notice Get the voter record for a delegate.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param acct Delegate account id (> 0).
    function getVoterOfDelegateMap(uint256 seqOfMotion, uint256 acct)
        external view returns (DelegateMap.Voter memory);

    /// @notice Get delegate of an account for a motion.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param acct Account id (> 0).
    function getDelegateOf(uint256 seqOfMotion, uint acct)
        external view returns (uint);

    // ==== motion ====

    /// @notice Get motion details.
    /// @param seqOfMotion Motion sequence number (> 0).
    function getMotion(uint256 seqOfMotion)
        external view returns (MotionsRepo.Motion memory motion);

    // ==== voting ====

    /// @notice Check whether an account has voted.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param acct Account id (> 0).
    function isVoted(uint256 seqOfMotion, uint256 acct) external view returns (bool);

    /// @notice Check whether an account voted for a specific attitude.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param acct Account id (> 0).
    /// @param atti Attitude value (enum value defined by BallotsBox).
    function isVotedFor(
        uint256 seqOfMotion,
        uint256 acct,
        uint atti
    ) external view returns (bool);

    /// @notice Get vote case for an attitude.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param atti Attitude value (enum value defined by BallotsBox).
    function getCaseOfAttitude(uint256 seqOfMotion, uint atti)
        external view returns (BallotsBox.Case memory );

    /// @notice Get ballot of an account for a motion.
    /// @param seqOfMotion Motion sequence number (> 0).
    /// @param acct Account id (> 0).
    function getBallot(uint256 seqOfMotion, uint256 acct)
        external view returns (BallotsBox.Ballot memory);

    /// @notice Check whether a motion has passed.
    /// @param seqOfMotion Motion sequence number (> 0).
    function isPassed(uint256 seqOfMotion) external view returns (bool);

    /// @notice Get list of motion sequence numbers.
    function getSeqList() external view returns (uint[] memory);

}
