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

import "../keepers/IROCKeeper.sol";
import "../keepers/IBMMKeeper.sol";
import "../keepers/IRODKeeper.sol";
import "../keepers/IGMMKeeper.sol";
import "../keepers/IROMKeeper.sol";
import "../keepers/IROAKeeper.sol";
import "../keepers/IROPKeeper.sol";
import "../keepers/IAccountant.sol";
import "../keepers/IROIKeeper.sol";

/// @title ICoreKeeper
/// @notice Aggregated module interface for core keeper operations across books.
/// @dev Groups keeper actions for governance, registry, funds, and investor controls.
interface ICoreKeeper {
    
    // ##################
    // ##  ROCKeeper   ##
    // ##################

    /// @notice Create a Shareholders Agreement (SHA) document by template version.
    /// @param version Template version (uint, expected > 0).
    function createSHA(uint version) external;

    /// @notice Circulate a SHA document for signing.
    /// @param body SHA contract address (non-zero).
    /// @param docUrl Document URL hash/pointer (bytes32, non-zero expected).
    /// @param docHash Content hash (bytes32, non-zero expected).
    function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external;

    /// @notice Sign a SHA document.
    /// @param sha SHA contract address (non-zero).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function signSHA(address sha, bytes32 sigHash) external;

    /// @notice Activate a SHA document.
    /// @param body SHA contract address (non-zero).
    function activateSHA(address body) external;

    /// @notice Accept a SHA by signature hash.
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function acceptSHA(bytes32 sigHash) external;

    // ###################
    // ##   BMMKeeper   ##
    // ###################

    /// @notice Nominate an officer for a position.
    /// @param seqOfPos Position sequence id (expected > 0).
    /// @param candidate Candidate userNo (expected > 0).
    function nominateOfficer(uint256 seqOfPos, uint candidate) external;

    /// @notice Create a motion to remove an officer.
    /// @param seqOfPos Position sequence id (expected > 0).
    function createMotionToRemoveOfficer(uint256 seqOfPos) external;

    /// @notice Create a motion to approve a document.
    /// @param doc Document sequence id (expected > 0).
    /// @param seqOfVR Voting rule sequence id (expected > 0).
    /// @param executor Executor userNo (expected > 0).
    function createMotionToApproveDoc(uint doc, uint seqOfVR, uint executor) external;

    /// @notice Create an action batch to be executed after approval.
    /// @param seqOfVR Voting rule sequence id (expected > 0).
    /// @param targets Target contract addresses (non-zero expected).
    /// @param values ETH values for each call (uint, >= 0).
    /// @param params Calldata for each call (bytes).
    /// @param desHash Description hash (bytes32, non-zero expected).
    /// @param executor Executor userNo (expected > 0).
    function createAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    /// @notice Delegate voting power for a board meeting motion.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    /// @param delegate Delegate userNo (expected > 0).
    function entrustDelegaterForBoardMeeting(uint256 seqOfMotion, uint delegate) external;

    /// @notice Propose a motion to the board meeting.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function proposeMotionToBoard (uint seqOfMotion) external;

    /// @notice Cast a vote for a board motion.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    /// @param attitude Voting attitude (uint, implementation-defined enum).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;

    /// @notice Count votes for a board motion.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function voteCounting(uint256 seqOfMotion) external;

    /// @notice Execute an approved action batch.
    /// @param typeOfAction Action type (uint, implementation-defined range).
    /// @param targets Target contract addresses (non-zero expected).
    /// @param values ETH values for each call (uint, >= 0).
    /// @param params Calldata for each call (bytes).
    /// @param desHash Description hash (bytes32, non-zero expected).
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

    // ###################
    // ##   RODKeeper   ##
    // ###################

    /// @notice Take a director seat after approval.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    /// @param seqOfPos Position sequence id (expected > 0).
    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external;

    /// @notice Remove a director after approval.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    /// @param seqOfPos Position sequence id (expected > 0).
    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external;

    /// @notice Take an officer position after approval.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    /// @param seqOfPos Position sequence id (expected > 0).
    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external;

    /// @notice Remove an officer after approval.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    /// @param seqOfPos Position sequence id (expected > 0).
    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external;

    /// @notice Resign from a position.
    /// @param seqOfPos Position sequence id (expected > 0).
    function quitPosition(uint256 seqOfPos) external;    

    // ###################
    // ##   GMMKeeper   ##
    // ###################

    /// @notice Nominate a director for a position.
    /// @param seqOfPos Position sequence id (expected > 0).
    /// @param candidate Candidate userNo (expected > 0).
    function nominateDirector(uint256 seqOfPos, uint candidate) external;

    /// @notice Create a motion to remove a director.
    /// @param seqOfPos Position sequence id (expected > 0).
    function createMotionToRemoveDirector(uint256 seqOfPos) external;

    /// @notice Propose a document for the general meeting.
    /// @param doc Document sequence id (expected > 0).
    /// @param seqOfVR Voting rule sequence id (expected > 0).
    /// @param executor Executor userNo (expected > 0).
    function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external;

    /// @notice Create an action batch for the general meeting.
    /// @param seqOfVR Voting rule sequence id (expected > 0).
    /// @param targets Target contract addresses (non-zero expected).
    /// @param values ETH values for each call (uint, >= 0).
    /// @param params Calldata for each call (bytes).
    /// @param desHash Description hash (bytes32, non-zero expected).
    /// @param executor Executor userNo (expected > 0).
    function createActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor
    ) external;

    /// @notice Delegate voting power for a general meeting motion.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    /// @param delegate Delegate userNo (expected > 0).
    function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external;

    /// @notice Propose a motion to the general meeting.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external;

    /// @notice Cast a vote for a general meeting motion.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    /// @param attitude Voting attitude (uint, implementation-defined enum).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash
    ) external;

    /// @notice Count votes for a general meeting motion.
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function voteCountingOfGM(uint256 seqOfMotion) external;

    /// @notice Execute an approved general meeting action batch.
    /// @param seqOfVR Voting rule sequence id (expected > 0).
    /// @param targets Target contract addresses (non-zero expected).
    /// @param values ETH values for each call (uint, >= 0).
    /// @param params Calldata for each call (bytes).
    /// @param desHash Description hash (bytes32, non-zero expected).
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function execActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion
    ) external;

    // ---- Fund & Distribution ----

    /// @notice Propose a USD distribution.
    /// @param amt Amount to distribute (uint, expected > 0).
    /// @param expireDate Expiration timestamp (unix seconds, > now expected).
    /// @param seqOfVR Voting rule sequence id (expected > 0).
    /// @param seqOfDR Distribution rule sequence id (expected > 0).
    /// @param fundManager Fund manager userNo (expected > 0).
    /// @param executor Executor userNo (expected > 0).
    function proposeToDistributeUsd(
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint seqOfDR,
        uint fundManager,
        uint executor
    ) external;

    /// @notice Propose a fund transfer.
    /// @param toBMM True if transfer to BMM book.
    /// @param to Recipient address (non-zero).
    /// @param isCBP True if transfer is CBP type.
    /// @param amt Amount to transfer (uint, expected > 0).
    /// @param expireDate Expiration timestamp (unix seconds, > now expected).
    /// @param seqOfVR Voting rule sequence id (expected > 0).
    /// @param executor Executor userNo (expected > 0).
    function proposeToTransferFund(
        bool toBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfVR,
        uint executor
    ) external;

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    /// @notice Set maximum number of members.
    /// @param max Maximum members (uint, expected > 0).
    function setMaxQtyOfMembers(uint max) external;

    /// @notice Set payable capital amount for a share.
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param amt Pay-in amount (uint, expected > 0).
    /// @param expireDate Expiration timestamp (unix seconds, > now expected).
    /// @param hashLock Hash lock (bytes32, non-zero expected).
    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external;

    /// @notice Request paid-in capital by providing hash preimage.
    /// @param hashLock Hash lock (bytes32, non-zero expected).
    /// @param hashKey Preimage string (non-empty expected).
    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    /// @notice Withdraw a pay-in amount after expiry or cancellation.
    /// @param hashLock Hash lock (bytes32, non-zero expected).
    /// @param seqOfShare Share sequence id (expected > 0).
    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;

    /// @notice Pay in capital via authorized USD transfer.
    /// @param auth Transfer authorization (must be valid for Cashier).
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param paid Paid amount (uint, expected > 0).
    function payInCapital(ICashier.TransferAuth memory auth, uint seqOfShare, uint paid) external;

    // ###################
    // ##   ROAKeeper   ##
    // ###################

    /// @notice Create an Investment Agreement (IA) document.
    /// @param snOfIA Encoded IA serial (uint256, non-zero expected).
    function createIA(uint256 snOfIA) external;

    /// @notice Circulate an IA document for signing.
    /// @param body IA contract address (non-zero).
    /// @param docUrl Document URL hash/pointer (bytes32, non-zero expected).
    /// @param docHash Content hash (bytes32, non-zero expected).
    function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external;

    /// @notice Sign an IA document.
    /// @param ia IA contract address (non-zero).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function signIA(address ia, bytes32 sigHash) external;

    // ======== Deal Closing ========

    /// @notice Push deal funds into escrow (coffer) with a hash lock.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param hashLock Hash lock (bytes32, non-zero expected).
    /// @param closingDeadline Deadline timestamp (unix seconds, > now expected).
    function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) 
    external;

    /// @notice Close a deal by providing hash preimage.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param hashKey Preimage string (non-empty expected).
    function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) 
    external;

    /// @notice Issue new shares as part of a deal closing.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    function issueNewShare(address ia, uint256 seqOfDeal) external;

    /// @notice Transfer target shares as part of a deal closing.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    function transferTargetShare(address ia, uint256 seqOfDeal) external;

    /// @notice Terminate a deal.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    function terminateDeal(address ia, uint256 seqOfDeal) external;

    /// @notice Pay off an approved deal to a recipient.
    /// @param auth Transfer authorization (must be valid for Cashier).
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param to Recipient address (non-zero).
    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, address to
    ) external;

    // ###################
    // ##   ROPKeeper   ##
    // ###################

    /// @notice Create a pledge record.
    /// @param snOfPld Encoded pledge serial (bytes32, non-zero expected).
    /// @param paid Paid amount/quantity (uint, expected > 0).
    /// @param par Par value (uint, expected > 0).
    /// @param guaranteedAmt Guaranteed amount (uint, expected > 0).
    /// @param execDays Execution window in days (uint, expected > 0).
    function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external;

    /// @notice Transfer a pledge to a buyer.
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param seqOfPld Pledge sequence id (expected > 0).
    /// @param buyer Buyer userNo (expected > 0).
    /// @param amt Transfer amount/quantity (uint, expected > 0).
    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) 
    external;

    /// @notice Refund debt against a pledge.
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param seqOfPld Pledge sequence id (expected > 0).
    /// @param amt Refund amount (uint, expected > 0).
    function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external;

    /// @notice Extend pledge expiry.
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param seqOfPld Pledge sequence id (expected > 0).
    /// @param extDays Extension in days (uint, expected > 0).
    function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external;

    /// @notice Lock a pledge with a hash lock.
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param seqOfPld Pledge sequence id (expected > 0).
    /// @param hashLock Hash lock (bytes32, non-zero expected).
    function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external;

    /// @notice Release a locked pledge with a preimage.
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param seqOfPld Pledge sequence id (expected > 0).
    /// @param hashKey Preimage string (non-empty expected).
    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external;

    /// @notice Execute a pledge transfer to a buyer group.
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param seqOfPld Pledge sequence id (expected > 0).
    /// @param buyer Buyer userNo (expected > 0).
    /// @param groupOfBuyer Buyer group id (uint, expected > 0).
    function execPledge(uint seqOfShare, uint256 seqOfPld, uint buyer, uint groupOfBuyer) external;

    /// @notice Revoke a pledge.
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param seqOfPld Pledge sequence id (expected > 0).
    function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external;

    // ##################
    // ##  Accountant  ##
    // ##################
    
    /// @notice Initialize a distribution class for accounting.
    /// @param class Class id (expected > 0).
    function initClass(uint class) external;

    /// @notice Distribute profits under a distribution rule.
    /// @param amt Amount to distribute (uint, expected > 0).
    /// @param expireDate Expiration timestamp (unix seconds, > now expected).
    /// @param seqOfDR Distribution rule sequence id (expected > 0).
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function distributeProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion
    ) external;

    /// @notice Distribute income under a distribution rule.
    /// @param amt Amount to distribute (uint, expected > 0).
    /// @param expireDate Expiration timestamp (unix seconds, > now expected).
    /// @param seqOfDR Distribution rule sequence id (expected > 0).
    /// @param fundManager Fund manager userNo (expected > 0).
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function distributeIncome(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint fundManager,
        uint seqOfMotion
    ) external;

    /// @notice Transfer funds after approval.
    /// @param fromBMM True if source is BMM book.
    /// @param to Recipient address (non-zero).
    /// @param isCBP True if transfer is CBP type.
    /// @param amt Amount to transfer (uint, expected > 0).
    /// @param expireDate Expiration timestamp (unix seconds, > now expected).
    /// @param seqOfMotion Motion sequence id (expected > 0).
    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external;

    // #################
    // ##  ROIKeeper  ##
    // #################

    /// @notice Pause investor actions under a legal rule.
    /// @param seqOfLR Legal rule sequence id (expected > 0).
    function pause(uint seqOfLR) external;

    /// @notice Unpause investor actions under a legal rule.
    /// @param seqOfLR Legal rule sequence id (expected > 0).
    function unPause(uint seqOfLR) external;

    /// @notice Freeze shares by legal rule.
    /// @param seqOfLR Legal rule sequence id (expected > 0).
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param paid Paid amount/quantity to freeze (uint, expected > 0).
    /// @param hashOrder Order hash (bytes32, non-zero expected).
    function freezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, bytes32 hashOrder
    ) external;

    /// @notice Unfreeze shares by legal rule.
    /// @param seqOfLR Legal rule sequence id (expected > 0).
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param paid Paid amount/quantity to unfreeze (uint, expected > 0).
    /// @param hashOrder Order hash (bytes32, non-zero expected).
    function unfreezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, bytes32 hashOrder
    ) external;

    /// @notice Force transfer shares under a legal rule.
    /// @param seqOfLR Legal rule sequence id (expected > 0).
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param paid Paid amount/quantity (uint, expected > 0).
    /// @param addrTo Recipient address (non-zero).
    /// @param hashOrder Order hash (bytes32, non-zero expected).
    function forceTransfer(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address addrTo, bytes32 hashOrder
    ) external;

    /// @notice Register an investor by address key.
    /// @param bKey Investor address key (non-zero).
    /// @param groupRep Group representative userNo (expected > 0).
    /// @param idHash Identity hash (bytes32, non-zero expected).
    function regInvestor(address bKey, uint groupRep, bytes32 idHash) external;

    /// @notice Approve an investor under a legal rule.
    /// @param userNo Investor userNo (expected > 0).
    /// @param seqOfLR Legal rule sequence id (expected > 0).
    function approveInvestor(uint userNo, uint seqOfLR) external;

    /// @notice Revoke an investor under a legal rule.
    /// @param userNo Investor userNo (expected > 0).
    /// @param seqOfLR Legal rule sequence id (expected > 0).
    function revokeInvestor(uint userNo, uint seqOfLR) external;

}
