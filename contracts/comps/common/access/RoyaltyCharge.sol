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

import "./AnyKeeper.sol";
import "../../../lib/DocsRepo.sol";

contract RoyaltyCharge is AnyKeeper {

    event ChargeRoyalty(
        uint indexed typeOfDoc, uint version, uint indexed rate, 
        uint indexed user, uint author
    );

    function _msgSender(
        address msgSender,
        uint rate
    ) internal returns(uint40 usr) {
        DocsRepo.Head memory head = _rc.getHeadByBody(address(this));
        head.author = _rc.getAuthorByBody(address(this));
        usr = _rc.getUserNo(
            msgSender, rate * (10 ** 10), head.author
        );
        emit ChargeRoyalty(
            head.typeOfDoc, head.version, rate, usr, head.author
        );
    }
}