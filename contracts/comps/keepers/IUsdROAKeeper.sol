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

import "./IROAKeeper.sol";

import "../books/cashier/ICashier.sol";
import "../books/roa/IInvestmentAgreement.sol";
import "../books/roc/terms/ILockUp.sol";

import "../../lib/InvestorsRepo.sol";

interface IUsdROAKeeper{

    event PayOffSTDeal(uint indexed caller, uint indexed valueOfDeal);

    event PayOffCIDeal(uint indexed caller, uint indexed valueOfDeal);

    function payOffApprovedDeal(
       ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, 
       address to, address msgSender
    ) external;
}