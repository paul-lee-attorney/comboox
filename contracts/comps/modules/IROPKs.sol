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

import "../keepers/IROPKeeper.sol";

/// @title IROPKs
/// @notice Module interface for ROPKeeper pledge management.
/// @dev Covers pledge creation, transfer, debt operations, and enforcement.
interface IROPKs {
    
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
    function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) external;

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
}
