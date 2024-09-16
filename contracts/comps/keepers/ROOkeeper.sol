// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

import "./IROOKeeper.sol";

import "../common/access/RoyaltyCharge.sol";

contract ROOKeeper is IROOKeeper, RoyaltyCharge {

    // ##################
    // ##    Option    ##
    // ##################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK {
        _gk.getROO().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt, address msgSender)
        external onlyDK
    {
        uint caller = _msgSender(msgSender, 18000);

        _gk.getROO().execOption(seqOfOpt, caller);
    }

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);

        uint closingDate = _gk.getROO().getOption(seqOfOpt).body.closingDeadline;

        IRegisterOfOptions _roo = _gk.getROO(); 
        IRegisterOfShares _ros = _gk.getROS();

        require(_ros.notLocked(seqOfTarget, closingDate),
            "ROOK.CreateSwap: target share locked");

        require(_ros.notLocked(seqOfPledge, closingDate),
            "ROOK.CreateSwap: pledged share locked");

        SwapsRepo.Swap memory swap = 
            _roo.createSwap(seqOfOpt, seqOfTarget, paidOfTarget, seqOfPledge, caller);

        _ros.decreaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        if (swap.isPutOpt)
            _ros.decreaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);        
    }

    function payOffSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap,
        uint msgValue,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);
        
        IRegisterOfShares _ros = _gk.getROS();

        uint centPrice = _gk.getCentPrice();

        SwapsRepo.Swap memory swap =
            _gk.getROO().payOffSwap(seqOfOpt, seqOfSwap, msgValue, centPrice);

        require(_ros.notLocked(swap.seqOfTarget, block.timestamp),
            "ROOK.payOffSwap: target locked");

        uint valueOfDeal = uint(swap.paidOfTarget) * uint(swap.priceOfDeal) / 10 ** 4 * 
            centPrice / 100;

        uint buyer = _ros.getShare(swap.seqOfPledge).head.shareholder;
        
        require (caller == buyer, "ROOK.payOffSwap: wrong payer");

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.transferShare(swap.seqOfTarget, swap.paidOfTarget, swap.paidOfTarget, buyer, swap.priceOfDeal, swap.priceOfDeal);

        if (swap.isPutOpt)
            _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);

        msgValue -= valueOfDeal;

        uint seller = _ros.getShare(swap.seqOfTarget).head.shareholder;

        _gk.saveToCoffer(
            seller,valueOfDeal, 
            bytes32(0x4465706f736974436f6e73696465726174696f6e4f6653776170000000000000)
        ); // reason: DepositConsiderationOfSwap
 
        if (msgValue > 0) {
            _gk.saveToCoffer(
                caller, msgValue, 
                bytes32(0x4465706f73697442616c616e63654f6653776170000000000000000000000000)
            ); // reason: DepositBalanceOfSwap
        }
    }

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);        
    
        SwapsRepo.Swap memory swap = 
            _gk.getROO().terminateSwap(seqOfOpt, seqOfSwap);

        IRegisterOfShares _ros = _gk.getROS();
        uint seller = _ros.getShare(swap.seqOfTarget).head.shareholder;

        require (caller == seller, "ROOK.terminateSwap: wrong ");

        require(_ros.notLocked(swap.seqOfPledge, block.timestamp),
            "ROOK.terminateSwap: pledge share locked");

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        
        if(swap.isPutOpt) {
            _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);
            _ros.transferShare(swap.seqOfPledge, swap.paidOfPledge, swap.paidOfPledge, 
                seller, swap.priceOfDeal, swap.priceOfDeal);
        }
    }

    // ==== AgainstToBuy ====

    function requestToBuy(
        address ia,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);

        IRegisterOfShares _ros = _gk.getROS();

        SwapsRepo.Swap memory swap =
            IInvestmentAgreement(ia).createSwap(_gk.getROA().getFile(ia).head.seqOfMotion, 
                seqOfDeal, paidOfTarget, seqOfPledge, caller);

        require(_ros.notLocked(swap.seqOfPledge, block.timestamp),
            "ROOK.requestToBuy: pledge share locked");

        _ros.decreaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.decreaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);
    }

    function payOffRejectedDeal(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap,
        uint msgValue,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);
        
        IRegisterOfShares _ros = _gk.getROS();

        uint centPrice = _gk.getCentPrice();

        SwapsRepo.Swap memory swap = 
            IInvestmentAgreement(ia).payOffSwap(_gk.getROA().getFile(ia).head.seqOfMotion, 
                seqOfDeal, seqOfSwap, msgValue, centPrice);

        require(_ros.notLocked(swap.seqOfTarget, block.timestamp),
            "ROOK.payOffRejectedDeal: target locked");

        uint valueOfDeal = uint(swap.paidOfTarget) * uint(swap.priceOfDeal) / 10 ** 4 * 
            centPrice / 100;        
        
        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);

        uint40 buyer = _ros.getShare(swap.seqOfPledge).head.shareholder;

        require(caller == buyer, "ROAK.payOffRD: not buyer");

        _ros.transferShare(swap.seqOfTarget, swap.paidOfTarget, swap.paidOfTarget, 
            buyer, swap.priceOfDeal, swap.priceOfDeal);

        uint seller = _ros.getShare(swap.seqOfTarget).head.shareholder;

        _gk.saveToCoffer(
            seller,valueOfDeal,
            bytes32(0x4465706f736974436f6e73696465724f6652656a65637465644465616c000000)
        ); // reason: DepositConsiderOfRejectedDeal

        msgValue -= valueOfDeal;
        if (msgValue > 0) {
            _gk.saveToCoffer(
                caller, msgValue, 
                bytes32(0x4465706f73697442616c616e63654f6652656a65637465644465616c00000000)
            ); // reason: DepositBalanceOfRejectedDeal
        }
    }

    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);
        
        IRegisterOfShares _ros = _gk.getROS();

        SwapsRepo.Swap memory swap = 
            IInvestmentAgreement(ia).terminateSwap(_gk.getROA().getFile(ia).head.seqOfMotion, 
                seqOfDeal, seqOfSwap);

        uint40 seller = _ros.getShare(swap.seqOfTarget).head.shareholder;

        require(caller == seller, "ROAK.pickupPledgedShare: not seller");

        require(_ros.notLocked(swap.seqOfPledge, block.timestamp),
            "ROOK.pickUpPledged: share locked");

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);

        _ros.transferShare(swap.seqOfPledge, swap.paidOfPledge, swap.paidOfPledge, seller, swap.priceOfDeal, swap.priceOfDeal);

    }

}
