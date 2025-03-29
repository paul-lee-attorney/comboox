// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
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

import "./IUsdROOKeeper.sol";

contract UsdROOKeeper is IUsdROOKeeper, RoyaltyCharge {

    function _cashier() private view returns(ICashier) {
        return ICashier(_gk.getBook(11));
    }

    function payOffSwap(
        ICashier.TransferAuth memory auth, uint256 seqOfOpt, uint256 seqOfSwap, 
        address to, address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 40000);

        IRegisterOfShares _ros = _gk.getROS();
        SwapsRepo.Swap memory swap = 
            _gk.getROO().getSwap(seqOfOpt, seqOfSwap);

        uint seller = _msgSender(to, 18000);

        require(seller == _ros.getShare(swap.seqOfTarget).head.shareholder,
            "UsdROOK.payOffSwap: wrong payee");

        uint valueOfDeal = swap.paidOfTarget * swap.priceOfDeal / 100;

        auth.from = msgSender;
        auth.value = valueOfDeal;

        // remark: PayOffSwap
        _cashier().forwardUsd(
            auth, 
            to, 
            bytes32(0x5061794f66665377617000000000000000000000000000000000000000000000)
        );
        emit PayOffSwap(seqOfOpt, seqOfSwap, msgSender, to, auth.value);

        IROOKeeper(_gk.getKeeper(7)).payOffSwapInUSD(
            seqOfOpt, seqOfSwap, caller
        );

    }

    function payOffRejectedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, uint seqOfSwap, 
        address to, address msgSender
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 40000);
        IRegisterOfShares _ros = _gk.getROS();
        SwapsRepo.Swap memory swap = 
            IInvestmentAgreement(ia).getSwap(seqOfDeal, seqOfSwap);

        uint seller = _msgSender(to, 18000);
        require(seller == _ros.getShare(swap.seqOfTarget).head.shareholder,
            "UsdROOK.payOffSwap: wrong payee");

        uint valueOfDeal = (swap.paidOfTarget * swap.priceOfDeal) / 100;

        auth.value = valueOfDeal;
        auth.from = msgSender;

        // remark: PayOffRejectedDeal
        _cashier().forwardUsd(
            auth, 
            to, 
            bytes32(0x5061794f666652656a65637465644465616c0000000000000000000000000000)
        );
        emit PayOffRejectedDeal(ia, seqOfDeal, seqOfSwap, msgSender, to, auth.value);

        IROOKeeper(_gk.getKeeper(7)).payOffRejectedDealInUSD(
            ia, seqOfDeal, seqOfSwap, caller
        );
    }

}