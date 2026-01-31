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

pragma solidity ^0.8.8;

import "./IRegisterOfInvestors.sol";
import "../../common/access/AccessControl.sol";

contract RegisterOfInvestors is IRegisterOfInvestors, AccessControl {
    using InvestorsRepo for InvestorsRepo.Repo;
    using EnumerableSet for EnumerableSet.UintSet;

    InvestorsRepo.Repo private _investors;

    /// @dev mapping from seqOfShare to paid amount under frozen;
    mapping(uint => uint) private _frozenPaid;

    /// @dev mapping from userNo to seqOfShare under frozen;
    mapping(uint => EnumerableSet.UintSet) private _frozenShares;

    bool private _paused;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Pause LOO ====

    function pause(uint caller) external onlyDK {
        require(_paused == false, "already paused");
        _paused = true;
        emit Paused(caller);
    }

    function unPause(uint caller) external onlyDK {
        require(_paused == true, "not paused");
        _paused = false;
        emit UnPaused(caller);
    }

    // ==== Freeze Share ====

    function freezeShare(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external onlyDK {
        _frozenShares[userNo].add(seqOfShare);
        _frozenPaid[seqOfShare] += paid;
        emit FreezeShare(seqOfShare, paid, caller, hashOrder);
    }

    function unfreezeShare(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external onlyDK {
        _unfreezeShare(userNo, seqOfShare, paid);
        emit UnfreezeShare(seqOfShare, paid, caller, hashOrder);
    }

    function _unfreezeShare(
        uint userNo, uint seqOfShare, uint paid
    ) private {
        require(_frozenPaid[seqOfShare] >= paid,
            "LOO.unfreezeShare: insufficient fronzen paid");
        _frozenPaid[seqOfShare] -= paid;
        if (_frozenPaid[seqOfShare] == 0 )
            _frozenShares[userNo].remove(seqOfShare);
    }

    function forceTransfer(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external onlyDK {
        _unfreezeShare(userNo, seqOfShare, paid);
        emit ForceTransfer(seqOfShare, paid, caller, hashOrder);
    }

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


    // ==== Paused ====

    function isPaused() external view returns (bool) {
        return _paused;
    }

    // ==== Frozen ====

    function isFrozen(uint userNo) external view returns(bool) 
    {
        return _frozenShares[userNo].length() > 0;
    }

    function isFrozenShare(uint seqOfShare) external view returns(bool) 
    {
        return _frozenPaid[seqOfShare] > 0;
    }

    function frozenShares(uint userNo) external view returns(uint[] memory) 
    {
        return _frozenShares[userNo].values();
    }

    function frozenPaid(uint seqOfShare) external view returns(uint) 
    {
        return _frozenPaid[seqOfShare];
    }

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
