// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "./IAccountant.sol";


contract Accountant is IAccountant, RoyaltyCharge {
    using BooksRepo for IBaseKeeper;

    function initClass(uint class) external onlyDK {
        uint sum = _gk.getROS().getInfoOfClass(class).body.paid;
        _gk.getCashier().initClass(class, sum);
    }

    function distrProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        _gk.getGMM().distributeUsd(
            amt,
            expireDate,
            seqOfDR,
            0,
            seqOfMotion,
            caller
        );

        _gk.getCashier().distrProfits(amt, seqOfDR);
    }

    function distrIncome(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint fundManager,
        uint seqOfMotion,
        address msgSender        
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 18000);

        IRegisterOfShares _ros = _gk.getROS();
        ICashier _cashier = _gk.getCashier();

        _gk.getGMM().distributeUsd(
            amt,
            expireDate,
            seqOfDR,
            fundManager,
            seqOfMotion,
            caller
        );

        (,WaterfallsRepo.Drop[] memory list) =
            _cashier.distrIncome(amt, seqOfDR, fundManager);

        uint len = list.length;
        while(len > 0) {

            WaterfallsRepo.Drop memory drop = list[len-1];

            if (drop.principal > 0) {   
                SharesRepo.Share memory share = 
                    _ros.getShare(drop.distrDate);
                _ros.decreaseCapital(share.head.seqOfShare, drop.principal/100, 0);
            }

            len--;
        }
    }

    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 76000);

        if (fromBMM) {
            _gk.getBMM().transferFund(
                to,
                isCBP,
                amt,
                expireDate,
                seqOfMotion,
                caller
            );
        } else {
            _gk.getGMM().transferFund(
                to,
                isCBP,
                amt,
                expireDate,
                seqOfMotion,
                caller
            );
        }

        if (!isCBP) {
            _gk.getCashier().transferUsd(to, amt, bytes32(seqOfMotion));
        }
    }
}
