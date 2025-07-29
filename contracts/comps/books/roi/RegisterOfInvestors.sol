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

import "./IRegisterOfInvestors.sol";
import "../../common/access/AccessControl.sol";

contract RegisterOfInvestors is IRegisterOfInvestors, AccessControl {
    using InvestorsRepo for InvestorsRepo.Repo;

    InvestorsRepo.Repo private _investors;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Investor ====

    function regInvestor(
        uint userNo,
        uint groupRep,
        bytes32 idHash
    ) external onlyDK {
        _investors.regInvestor(userNo, groupRep, idHash);
        emit RegInvestor(userNo, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        uint verifier
    ) external onlyDK {
        _investors.approveInvestor(userNo, verifier);
        emit ApproveInvestor(userNo, verifier);
    }        

    function revokeInvestor(
        uint userNo,
        uint verifier
    ) external onlyDK {
        _investors.revokeInvestor(userNo, verifier);
        emit RevokeInvestor(userNo, verifier);
    }

    function restoreInvestorsRepo(
        InvestorsRepo.Investor[] memory list, uint qtyOfInvestors
    ) external onlyDK {
        _investors.restoreRepo(list, qtyOfInvestors);
    }

    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        uint userNo
    ) external view returns(bool) {
        return _investors.isInvestor(userNo);
    }

    function getInvestor(
        uint userNo
    ) external view returns(InvestorsRepo.Investor memory) {
        return _investors.getInvestor(userNo);
    }

    function getQtyOfInvestors() 
        external view returns(uint) 
    {
        return _investors.getQtyOfInvestors();
    }

    function investorList() 
        external view returns(uint[] memory) 
    {
        return _investors.investorList();
    }

    function investorInfoList() 
        external view returns(InvestorsRepo.Investor[] memory) 
    {
        return _investors.investorInfoList();
    }

}
