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

import "../common/access/RoyaltyCharge.sol";

import "./IUsdROMKeeper.sol";

contract UsdROMKeeper is IUsdROMKeeper, RoyaltyCharge {

    function payInCapital(
        ICashier.TransferAuth memory auth,
        uint seqOfShare, 
        uint paid, 
        address msgSender
    ) external onlyDK {
        
        uint caller = _msgSender(msgSender, 36000);
        IRegisterOfShares _ros = _gk.getROS();
        SharesRepo.Share memory share = _ros.getShare(seqOfShare);
        
        require(share.head.shareholder == caller,
            "UsdROMK.payInCap: not shareholder");

        auth.from = msgSender;
        auth.value = share.head.priceOfPaid * paid / 100;

        ICashier(_gk.getBook(11)).collectUsd(auth);

        _ros.payInCapital(seqOfShare, paid);

        emit PayInCapital(seqOfShare, paid, auth.value);
    }

}