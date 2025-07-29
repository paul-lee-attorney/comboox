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

import "../../comps/books/cashier/ICashier.sol";

import "../../lib/SwapsRepo.sol";

interface IROOKeeper {

    // #################
    // ##  ROOKeeper  ##
    // #################

    event PayOffSwap(
        uint seqOfOpt, uint seqOfSwap, address indexed from, 
        address indexed to, uint indexed valueOfDeal
    );

    event PayOffRejectedDeal(
        address ia, uint seqOfDeal, uint seqOfSwap, address indexed from, 
        address indexed to, uint indexed valueOfDeal
    );

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    function execOption(uint256 seqOfOpt, address msgSender)external;

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge,
        address msgSender
    ) external;

    function payOffSwap(
        ICashier.TransferAuth memory auth, uint256 seqOfOpt, uint256 seqOfSwap, address to, address msgSender
    ) external;

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap,
        address msgSender
    ) external;

    // ==== Swap ====

    function requestToBuy(
        address ia,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        address msgSender
    ) external;

    function payOffRejectedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, 
        uint seqOfSwap, address to, address msgSender
    ) external;

    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap,
        address msgSender
    ) external;

}
