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

import "./IROOKs.sol";

abstract contract ROOKs is IROOKs, AccessControl {
    // using BooksRepo for IBaseKeeper;

    // #################
    // ##  ROOKeeper  ##
    // #################

    function _getROOKeeper() private view returns(IROOKeeper) {
        return IROOKeeper(_gk.getKeeper(7));
    }

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK {
       _getROOKeeper().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external{
       _getROOKeeper().execOption(seqOfOpt, msg.sender);
    }

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge
    ) external{
       _getROOKeeper().createSwap(seqOfOpt, seqOfTarget, paidOfTarget, seqOfPledge, msg.sender);
    }

    function payOffSwap(
        ICashier.TransferAuth memory auth, uint256 seqOfOpt, uint256 seqOfSwap, address to
    ) external {
       _getROOKeeper().payOffSwap(
            auth, seqOfOpt, seqOfSwap, to, msg.sender
        );
    }

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external{
       _getROOKeeper().terminateSwap(seqOfOpt, seqOfSwap, msg.sender);
    }

    function requestToBuy(address ia, uint seqOfDeal, uint paidOfTarget, uint seqOfPledge) external{
       _getROOKeeper().requestToBuy(ia, seqOfDeal, paidOfTarget, seqOfPledge, msg.sender);
    }

    function payOffRejectedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, uint seqOfSwap, address to
    ) external {
       _getROOKeeper().payOffRejectedDeal(
            auth, ia, seqOfDeal, seqOfSwap, to, msg.sender
        );
    }

    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap
    ) external {
       _getROOKeeper().pickupPledgedShare(ia, seqOfDeal, seqOfSwap, msg.sender);        
    }

}
