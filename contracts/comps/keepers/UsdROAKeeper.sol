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

import "./IUsdROAKeeper.sol";

contract UsdROAKeeper is IUsdROAKeeper, RoyaltyCharge {

    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal,
        address to, address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 58000);
        IInvestmentAgreement _ia = IInvestmentAgreement(ia);
        DealsRepo.Deal memory deal = _ia.getDeal(seqOfDeal);

        auth.value = (deal.body.paid * deal.head.priceOfPaid + 
            (deal.body.par - deal.body.paid) * deal.head.priceOfPar) / 100;
        auth.from = msgSender;

        if (deal.head.seqOfShare > 0) {
            require(deal.head.seller == _msgSender(to, 18000),
               "UsdROAK.payOffApprDealInUSD: wrong payee");

            // remark: PayOffShareTransferDeal
            ICashier(_gk.getBook(11)).forwardUsd(auth, to, bytes32(0x5061794f666653686172655472616e736665724465616c000000000000000000));
        } else {
            require(_gk.getBook(11) == to,
               "UsdROAK.payOffApprDealInUSD: wrong payee");

            // remark: PayOffCapIncreaseDeal
            ICashier(_gk.getBook(11)).forwardUsd(auth, to, bytes32(0x5061794f6666436170496e6372656173654465616c0000000000000000000000));            
        }

        IROAKeeper(_gk.getKeeper(6)).payOffApprovedDealInUSD(ia, seqOfDeal, auth.value, caller);
    }
}