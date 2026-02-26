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

import "../books/cashier/ICashier.sol";

/// @title ILOOKeeper
/// @notice Interface for placing and withdrawing LOO orders.
interface ILOOKeeper {

    //###############
    //##   Error   ##
    //###############

    error LOOK_WrongState(bytes32 reason);

    error LOOK_WrongParty(bytes32 reason);

    error LOOK_WrongInput(bytes32 reason);


    //###############
    //##   Write   ##
    //###############

    /// @notice Place an initial offer for a class.
    /// @param classOfShare Share class id.
    /// @param execHours Execution window in hours.
    /// @param paid Paid amount.
    /// @param price Unit price.
    /// @param seqOfLR Listing rule sequence.
    function placeInitialOffer(
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    /// @notice Withdraw an initial offer.
    /// @param classOfShare Share class id.
    /// @param seqOfOrder Order sequence.
    /// @param seqOfLR Listing rule sequence.
    function withdrawInitialOffer(
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external;

    /// @notice Place a sell order.
    /// @param seqOfClass Share class id.
    /// @param execHours Execution window in hours.
    /// @param paid Paid amount.
    /// @param price Unit price.
    /// @param seqOfLR Listing rule sequence.
    function placeSellOrder(
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    /// @notice Withdraw a sell order.
    /// @param classOfShare Share class id.
    /// @param seqOfOrder Order sequence.
    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external;

    /// @notice Place a buy order with transfer authorization.
    /// @param auth Transfer authorization.
    /// @param classOfShare Share class id.
    /// @param paid Paid amount.
    /// @param price Unit price.
    /// @param execHours Execution window in hours.
    function placeBuyOrder(
        ICashier.TransferAuth memory auth,
        uint classOfShare, uint paid, uint price, uint execHours
    ) external;

    /// @notice Place a market buy order with transfer authorization.
    /// @param auth Transfer authorization.
    /// @param classOfShare Share class id.
    /// @param paid Paid amount.
    /// @param execHours Execution window in hours.
    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth,
        uint classOfShare, uint paid, uint execHours
    ) external;

    /// @notice Withdraw a buy order.
    /// @param classOfShare Share class id.
    /// @param seqOfOrder Order sequence.
    function withdrawBuyOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external;

}
