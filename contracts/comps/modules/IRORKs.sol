// SPDX-License-Identifier: UNLICENSED

/* *
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

import "../keepers/IRORKeeper.sol";

/// @title IRORKs
/// @notice Module interface for RORKeeper redemption workflows.
/// @dev Handles redeemable classes, NAV updates, and redemption execution.
interface IRORKs {

    // #################
    // ##  RORKeeper  ##
    // #################

    /// @notice Add a redeemable share class.
    /// @param class Share class id (expected > 0).
    function addRedeemableClass(uint class) external;

    /// @notice Remove a redeemable share class.
    /// @param class Share class id (expected > 0).
    function removeRedeemableClass(uint class) external;

    /// @notice Update NAV price for a class.
    /// @param class Share class id (expected > 0).
    /// @param price NAV price (uint, expected > 0).
    function updateNavPrice(uint class, uint price) external;

    /// @notice Request redemption for a paid amount in a class.
    /// @param class Share class id (expected > 0).
    /// @param paid Paid amount/quantity to redeem (uint, expected > 0).
    function requestForRedemption(uint class, uint paid) external;

    /// @notice Execute redemption for a request pack.
    /// @param class Share class id (expected > 0).
    /// @param seqOfPack Redemption pack sequence id (expected > 0).
    function redeem(uint class, uint seqOfPack) external;

}
