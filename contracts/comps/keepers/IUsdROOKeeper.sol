// SPDX-License-Identifier: UNLICENSED

/* *
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


import "../books/cashier/ICashier.sol";
import "../../lib/SwapsRepo.sol";

interface IUsdROOKeeper{

    event PayOffSwap(
        uint seqOfOpt, uint seqOfSwap, address indexed from, 
        address indexed to, uint indexed valueOfDeal
    );

    event PayOffRejectedDeal(
        address ia, uint seqOfDeal, uint seqOfSwap, address indexed from, 
        address indexed to, uint indexed valueOfDeal
    );

    function payOffSwap(
        ICashier.TransferAuth memory auth, uint256 seqOfOpt, uint256 seqOfSwap, address to, address msgSender
    ) external;

    function payOffRejectedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, 
        uint seqOfSwap, address to, address msgSender
    ) external;
}