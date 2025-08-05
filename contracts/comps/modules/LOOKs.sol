// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
 *
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

import "../common/access/AccessControl.sol";

import "./ILOOKs.sol";

abstract contract LOOKs is ILOOKs, AccessControl {
    // using BooksRepo for IBaseKeeper;

    // #################
    // ##  LOOKeeper  ##
    // #################

    function _getLOOKeeper() private view returns(ILOOKeeper) {
        return ILOOKeeper(_gk.getKeeper(10));
    }

    function placeInitialOffer(
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external{
        _getLOOKeeper().placeInitialOffer(
            msg.sender,
            classOfShare,
            execHours,
            paid,
            price,
            seqOfLR
        );
    }

    function withdrawInitialOffer(
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external{
        _getLOOKeeper().withdrawInitialOffer(
            msg.sender,
            classOfShare,
            seqOfOrder,
            seqOfLR
        );        
    }

    function placeSellOrder(
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external{
        _getLOOKeeper().placeSellOrder(
            msg.sender,
            seqOfClass,
            execHours,
            paid,
            price,
            seqOfLR
        );
    }

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external{
        _getLOOKeeper().withdrawSellOrder(
            msg.sender,
            classOfShare,
            seqOfOrder
        );        
    }

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, 
        uint paid, uint price, uint execHours
    ) external {
        _getLOOKeeper().placeBuyOrder(
            auth, msg.sender, classOfShare, paid, price, execHours
        );
    }

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, uint classOfShare, 
        uint paid, uint execHours
    ) external{
        _getLOOKeeper().placeMarketBuyOrder(
            auth, msg.sender, classOfShare, paid, execHours
        );
    }

    function withdrawBuyOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external {
        _getLOOKeeper().withdrawBuyOrder(
            msg.sender,
            classOfShare,
            seqOfOrder
        );
    }
}
