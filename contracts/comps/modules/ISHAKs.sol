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

import "../keepers/ISHAKeeper.sol";

/// @title ISHAKs
/// @notice Module interface for SHAKeeper shareholder agreement actions.
/// @dev Covers tag-along, drag-along, anti-dilution, and first-refusal flows.
interface ISHAKs {

    // ###################
    // ##   SHAKeeper   ##
    // ###################

    // ======= TagAlong ========

    /// @notice Execute tag-along rights for a deal.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param paid Paid amount/quantity (uint, expected > 0).
    /// @param par Par value (uint, expected > 0).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function execTagAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external;

    // ======= DragAlong ========

    /// @notice Execute drag-along rights for a deal.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param paid Paid amount/quantity (uint, expected > 0).
    /// @param par Par value (uint, expected > 0).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function execDragAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external;

    /// @notice Accept a tag/drag-along deal.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external;

    // ======== AntiDilution ========

    /// @notice Execute anti-dilution adjustment for a deal.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param seqOfShare Share sequence id (expected > 0).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external;

    /// @notice Claim gifted shares from an anti-dilution adjustment.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    function takeGiftShares(address ia, uint256 seqOfDeal) external;

    // ======== First Refusal ========

    /// @notice Execute a first-refusal right.
    /// @param seqOfRule Rule sequence id (expected > 0).
    /// @param seqOfRightholder Right-holder sequence id (expected > 0).
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param sigHash Signature hash (bytes32, non-zero expected).
    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external;

    /// @notice Compute the first-refusal allocation for a deal.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external;

}
