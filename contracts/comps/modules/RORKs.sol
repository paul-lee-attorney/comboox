// SPDX-License-Identifier: UNLICENSED

/* *
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

import "./IRORKs.sol";

abstract contract RORKs is IRORKs, AccessControl {
    // using BooksRepo for IBaseKeeper;

    // #################
    // ##  RORKeeper  ##
    // #################

    function _getRORKeeper() private view returns(IRORKeeper) {
        return IRORKeeper(_gk.getKeeper(16));
    }

    function addRedeemableClass(uint class) external {
        _getRORKeeper().addRedeemableClass(class, msg.sender);
    }

    function removeRedeemableClass(uint class) external {
        _getRORKeeper().removeRedeemableClass(class, msg.sender);
    }

    function updateNavPrice(uint class, uint price) external {
        _getRORKeeper().updateNavPrice(class, price, msg.sender);
    }

    function requestForRedemption(uint class, uint paid) external {
        _getRORKeeper().requestForRedemption(class, paid, msg.sender);
    }

    function redeem(uint class, uint seqOfPack) external {
        _getRORKeeper().redeem(class, seqOfPack, msg.sender);
    }


}
