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

import "./ICashLockers.sol";

contract CashLockers is ICashLockers {

    using UsdLockersRepo for UsdLockersRepo.Repo;

    IUSDC immutable public usdc;

    constructor(address _usdc) {
        usdc = IUSDC(_usdc);
    }

    mapping(address => uint256) private _coffers;
    UsdLockersRepo.Repo private _lockers;

    //###############
    //##   Write   ##
    //###############

    function _transferWithAuthorization(TransferAuth memory auth) private {
        usdc.transferWithAuthorization(
            auth.from, 
            address(this), 
            auth.value,
            auth.validAfter, 
            auth.validBefore, 
            auth.nonce, 
            auth.v,
            auth.r,
            auth.s
        );
    }

    function lockUsd(
        TransferAuth memory auth, address to, uint expireDate, bytes32 lock
    ) external {

        auth.from = msg.sender;

        _transferWithAuthorization(auth);

        _coffers[auth.from] += auth.value;
        _coffers[address(1)] += auth.value;

        _lockers.lockUsd(auth.from, to, expireDate, auth.value, lock);

        emit LockUsd(auth.from, to, auth.value, expireDate, lock);
    }

    function lockConsideration(
        TransferAuth memory auth, 
        address to, 
        uint expireDate,  
        address target, 
        bytes calldata payload, 
        bytes32 hashLock
    ) external {

        auth.from = msg.sender;

        _transferWithAuthorization(auth);

        _lockers.lockConsideration(
            auth.from, to, expireDate, auth.value, 
            target, payload, hashLock
        );
        
        emit LockConsideration(auth.from, to, auth.value, expireDate, hashLock);
    }

    function unlockUsd(bytes32 lock, string memory key) external {

        UsdLockersRepo.Head memory head =
            _lockers.releaseUsd(lock, key, msg.sender);

        require(_coffers[head.from] >= head.amt,
            "CashLocker.releaseUsd: insufficient balance");

        _coffers[head.from] -= head.amt;
        _coffers[address(1)] -= head.amt;

        emit UnlockUsd(head.from, head.to, head.amt, lock);

        require(usdc.transfer(head.to, head.amt),
            "CashLocker.releaseUsd: transfer failed");
    }

    function withdrawUsd(bytes32 lock) external {

        UsdLockersRepo.Head memory head =
            _lockers.withdrawUsd(lock, msg.sender);

        require(_coffers[head.from] >= head.amt,
            "CashLocker.withdrawUsd: insufficient amt");

        _coffers[head.from] -= head.amt;
        _coffers[address(1)] -= head.amt;

        emit WithdrawUsd(head.from, head.amt, lock);

        require(usdc.transfer(head.from, head.amt),
            "CashLocker.withdrawUsd: transfer failed");
    }

    //##################
    //##   Read I/O   ##
    //##################

    function isLocked(bytes32 lock) external view returns(bool) {
        return _lockers.isLocked(lock);
    }

    function counterOfLockers() external view returns(uint) {
        return _lockers.counterOfLockers();
    }

    function getHeadOfLocker(bytes32 lock) external view returns(UsdLockersRepo.Head memory) {
        return _lockers.getHeadOfLocker(lock);
    }

    function getLocker(bytes32 lock) external view returns(UsdLockersRepo.Locker memory) {
        return _lockers.getLocker(lock);
    }

    function getLockersList() external view returns (bytes32[] memory) {
        return _lockers.getSnList();
    }

    function custodyOf(address acct) external view returns(uint) {
        return _coffers[acct];
    }

    function totalCustody() external view returns(uint) {
        return _coffers[address(1)];
    }
}