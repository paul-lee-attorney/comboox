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

import "./IROOKeeper.sol";

import "../../comps/common/access/RoyaltyCharge.sol";

contract ROOKeeper is IROOKeeper, RoyaltyCharge {
    using InterfacesHub for address;

    // ##################
    // ##    Option    ##
    // ##################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK  onlyGKProxy {
        gk.getROO().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);

        gk.getROO().execOption(seqOfOpt, caller);
    }

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);

        uint closingDate = gk.getROO().getOption(seqOfOpt).body.closingDeadline;

        IRegisterOfOptions _roo = gk.getROO(); 
        IRegisterOfShares _ros = gk.getROS();

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
        ICashier.TransferAuth memory auth, 
        uint256 seqOfOpt, 
        uint256 seqOfSwap, 
        address to
    ) external  onlyGKProxy {

        uint caller = _msgSender(msg.sender, 40000);

        IRegisterOfShares _ros = gk.getROS();
        SwapsRepo.Swap memory swap = 
            gk.getROO().getSwap(seqOfOpt, seqOfSwap);

        uint seller = _msgSender(to, 18000);

        require(seller == _ros.getShare(swap.seqOfTarget).head.shareholder,
            "UsdROOK.payOffSwap: wrong payee");

        uint valueOfDeal = swap.paidOfTarget * swap.priceOfDeal / 100;

        auth.from = msg.sender;
        auth.value = valueOfDeal;

        // remark: PayOffSwap
        gk.getCashier().forwardUsd(
            auth, 
            to, 
            bytes32(0x5061794f66665377617000000000000000000000000000000000000000000000)
        );
        emit PayOffSwap(seqOfOpt, seqOfSwap, msg.sender, to, auth.value);

        _payOffSwap(seqOfOpt, seqOfSwap, caller);
    }

    function _payOffSwap(
        uint seqOfOpt, uint seqOfSwap, uint caller
    ) private {

        IRegisterOfShares _ros = gk.getROS();

        SwapsRepo.Swap memory swap =
            gk.getROO().payOffSwap(seqOfOpt, seqOfSwap);

        require(_ros.notLocked(swap.seqOfTarget, block.timestamp),
            "ROOK.payOffSwap: target locked");

        uint buyer = _ros.getShare(swap.seqOfPledge).head.shareholder;
        
        require (caller == buyer, "ROOK.payOffSwap: wrong payer");

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.transferShare(
            swap.seqOfTarget, swap.paidOfTarget, swap.paidOfTarget, 
            buyer, swap.priceOfDeal, swap.priceOfDeal
        );

        if (swap.isPutOpt) {
            _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);
        }
    }

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);
    
        SwapsRepo.Swap memory swap = 
            gk.getROO().terminateSwap(seqOfOpt, seqOfSwap);

        IRegisterOfShares _ros = gk.getROS();
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
}
