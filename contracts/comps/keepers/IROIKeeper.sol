// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

pragma solidity ^0.8.8;

import "../books/roi/IRegisterOfInvestors.sol";
import "../books/ros/IRegisterOfShares.sol";

import "../../lib/RulesParser.sol";
import "../../lib/BooksRepo.sol";

interface IROIKeeper {

    //###############
    //##   Write   ##
    //###############

    // ==== Pause LOO ====

    function pause(uint seqOfLR, address msgSender) external;

    function unPause(uint seqOfLR, address msgSender) external;

    // ==== Freeze Share ====

    function freezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address msgSender, bytes32 hashOrder
    ) external;

    function unfreezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address msgSender, bytes32 hashOrder
    ) external;

    function forceTransfer(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address addrTo, address msgSender, bytes32 hashOrder
    ) external;

    // ==== Investor ====

    function regInvestor(address msgSender, address bKey, uint groupRep, bytes32 idHash) external;

    function approveInvestor(uint userNo, address msgSender,uint seqOfLR) external;

    function revokeInvestor(uint userNo,address msgSender,uint seqOfLR) external;

}
