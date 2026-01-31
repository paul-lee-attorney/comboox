// SPDX-License-Identifier: UNLICENSED

/* *
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

import "../../../lib/InvestorsRepo.sol";
import "../../../lib/EnumerableSet.sol";

interface IRegisterOfInvestors {

    event Paused(uint indexed agent);

    event UnPaused(uint indexed agent);

    event FreezeShare(uint indexed seqOfShare, uint indexed paid, uint indexed caller, bytes32 hashOrder);
    
    event UnfreezeShare(uint indexed seqOfShare, uint indexed paid, uint indexed caller, bytes32 hashOrder);
    
    event ForceTransfer(uint indexed seqOfShare, uint indexed paid, uint indexed caller, bytes32 hashOrder);

    event RegInvestor(uint indexed investor, uint indexed groupRep, bytes32 indexed idHash);

    event ApproveInvestor(uint indexed investor, uint indexed verifier);

    event RevokeInvestor(uint indexed investor, uint indexed verifier);

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Pause LOO ====

    function pause(uint caller) external;

    function unPause(uint caller) external;

    // ==== Freeze Share ====

    function freezeShare(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external;

    function unfreezeShare(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external;

    function forceTransfer(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external;

    // ==== Investor ====

    function regInvestor(uint userNo,uint groupRep,bytes32 idHash) external;

    function approveInvestor(uint userNo,uint verifier) external;

    function revokeInvestor(uint userNo,uint verifier) external;

    function restoreInvestorsRepo(InvestorsRepo.Investor[] memory list, uint qtyOfInvestors) external;

    //################
    //##  Read I/O  ##
    //################

    // ==== Paused ====

    function isPaused() external view returns (bool);

    // ==== Freeze ====

    function isFrozen(uint userNo) external view returns(bool); 

    function isFrozenShare(uint seqOfShare) external view returns(bool);

    function frozenShares(uint userNo) external view returns(uint[] memory); 
    
    function frozenPaid(uint seqOfShare) external view returns(uint);

    // ==== Investor ====

    function isInvestor(uint userNo) external view returns(bool);

    function getInvestor(uint userNo) external view returns(InvestorsRepo.Investor memory);

    function getQtyOfInvestors() external view returns(uint);

    function investorList() external view returns(uint[] memory);

    function investorInfoList() external view returns(InvestorsRepo.Investor[] memory);

}
