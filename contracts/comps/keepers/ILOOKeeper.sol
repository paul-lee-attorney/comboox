// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2025 LI LI @ JINGTIAN & GONGCHENG.
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

import "../../lib/BooksRepo.sol";
import "../../lib/GoldChain.sol";
import "../../lib/InvestorsRepo.sol";
import "../../lib/RulesParser.sol";
import "../../lib/SharesRepo.sol";
import "../../lib/UsdOrdersRepo.sol";

import "../books/cashier/ICashier.sol";
import "../books/loo/IListOfOrders.sol";
import "../books/rom/IRegisterOfMembers.sol";
import "../books/ros/IRegisterOfShares.sol";


interface ILOOKeeper {

    //###############
    //##   Write   ##
    //###############

    function placeInitialOffer(
        address msgSender,
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    function withdrawInitialOffer(
        address msgSender,
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external;

    function placeSellOrder(
        address msgSender,
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    function withdrawSellOrder(
        address msgSender,
        uint classOfShare,
        uint seqOfOrder
    ) external;

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, address msgSender, 
        uint classOfShare, uint paid, uint price, uint execHours
    ) external;

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, address msgSender, 
        uint classOfShare, uint paid, uint execHours
    ) external;

    function withdrawBuyOrder(
        address msgSender,
        uint classOfShare,
        uint seqOfOrder
    ) external;

}
