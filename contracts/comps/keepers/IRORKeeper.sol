// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "../../lib/RedemptionsRepo.sol";
import "../../lib/InterfacesHub.sol";
import "../../lib/SharesRepo.sol";

import "../books/ror/IRegisterOfRedemptions.sol";
import "../books/rom/IRegisterOfMembers.sol";
import "../books/ros/IRegisterOfShares.sol";
import "../books/cashier/ICashier.sol";


/// @title IRORKeeper
/// @notice Interface for redemption configuration and execution.
interface IRORKeeper {

    /// @notice Add a redeemable class.
    /// @param class Share class id.
    function addRedeemableClass(uint class) external;

    /// @notice Remove a redeemable class.
    /// @param class Share class id.
    function removeRedeemableClass(uint class) external;

    /// @notice Update NAV price for a class.
    /// @param class Share class id.
    /// @param price NAV price.
    function updateNavPrice(uint class, uint price) external;

    /// @notice Request redemption for a share.
    /// @param class Share class id.
    /// @param paid Paid amount to redeem.
    function requestForRedemption(
        uint class, uint paid
    ) external;

    /// @notice Redeem a pack for a class.
    /// @param class Share class id.
    /// @param seqOfPack Pack sequence.
    function redeem(uint class, uint seqOfPack) external;

}
