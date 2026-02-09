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

import "../books/cashier/ICashier.sol";
import "../keepers/ILOOKeeper.sol";

// import "../../lib/BooksRepo.sol";

/// @title ILOOKs
/// @notice Module interface for Listing/Order operations handled by LOOKeeper.
/// @dev Exposes order placement/withdrawal flows for initial offers and order book trading.
interface ILOOKs {

    // #################
    // ##  LOOKeeper  ##
    // #################

    /// @notice Place an initial offer into the order book.
    /// @param classOfShare Share class id (expected > 0).
    /// @param execHours Order validity window in hours (expected > 0).
    /// @param paid Quantity offered (uint, expected > 0).
    /// @param price Unit price (uint, expected > 0 for limit order).
    /// @param seqOfLR Listing rule sequence (uint, expected > 0).
    function placeInitialOffer(
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    /// @notice Withdraw a previously placed initial offer.
    /// @param classOfShare Share class id (expected > 0).
    /// @param seqOfOrder Order sequence id (expected > 0).
    /// @param seqOfLR Listing rule sequence (uint, expected > 0).
    function withdrawInitialOffer(
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external;

    /// @notice Place a sell order for a class.
    /// @param seqOfClass Share class id (expected > 0).
    /// @param execHours Order validity window in hours (expected > 0).
    /// @param paid Quantity to sell (uint, expected > 0).
    /// @param price Unit price (uint, expected > 0 for limit order).
    /// @param seqOfLR Listing rule sequence (uint, expected > 0).
    function placeSellOrder(
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    /// @notice Withdraw an existing sell order.
    /// @param classOfShare Share class id (expected > 0).
    /// @param seqOfOrder Order sequence id (expected > 0).
    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external;

    /// @notice Place a buy order funded by an authorized USD transfer.
    /// @param auth Transfer authorization (must be valid for Cashier).
    /// @param classOfShare Share class id (expected > 0).
    /// @param paid Quantity to buy (uint, expected > 0).
    /// @param price Unit price (uint, expected > 0 for limit order).
    /// @param execHours Order validity window in hours (expected > 0).
    function placeBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, 
        uint paid, uint price, uint execHours
    ) external;

    /// @notice Place a market buy order with a maximum USD budget.
    /// @param auth Transfer authorization (must be valid for Cashier).
    /// @param classOfShare Share class id (expected > 0).
    /// @param paid Budget or quantity cap (uint, expected > 0).
    /// @param execHours Order validity window in hours (expected > 0).
    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, 
        uint paid, uint execHours
    ) external;

    /// @notice Withdraw an existing buy order.
    /// @param classOfShare Share class id (expected > 0).
    /// @param seqOfOrder Order sequence id (expected > 0).
    function withdrawBuyOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external;
}
