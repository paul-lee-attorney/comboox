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

import "./ICashLockers.sol";

/// @title CashLockers
/// @notice Escrow contract that locks USDC using EIP-3009 authorizations and releases by hash-lock or expiry.
/// @dev Tracks per-user custody and total custody for locked balances.
contract CashLockers is ICashLockers {

    using UsdLockersRepo for UsdLockersRepo.Repo;

    /// @notice USDC token with transferWithAuthorization support.
    IUSDC immutable public usdc;

    /// @notice Deploy with USDC token address.
    /// @param _usdc USDC contract address.
    constructor(address _usdc) {
        usdc = IUSDC(_usdc);
    }

    /// @notice Custody balances per address.
    mapping(address => uint256) private _coffers;
    UsdLockersRepo.Repo private _lockers;

    //###############
    //##   Write   ##
    //###############

    /// @notice Pull USDC using an EIP-3009 authorization.
    /// @param auth Authorization data structure.
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

    /// @notice Lock USDC with a hash-lock until released or expired.
    /// @param auth USDC authorization (EIP-3009 style).
    /// @param to Payee address.
    /// @param expireDate Unix timestamp when withdrawal is allowed.
    /// @param lock Hash lock value (keccak256 of the secret key).
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

    /// @notice Lock USDC with an external conditional release hook.
    /// @param auth USDC authorization (EIP-3009 style).
    /// @param to Payee address.
    /// @param expireDate Unix timestamp when withdrawal is allowed.
    /// @param target Counter-locker contract to call on release.
    /// @param payload Calldata payload prefix for counter-locker.
    /// @param hashLock Hash lock value (keccak256 of the secret key).
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

        _coffers[auth.from] += auth.value;
        _coffers[address(1)] += auth.value;

        _lockers.lockConsideration(
            auth.from, to, expireDate, auth.value, 
            target, payload, hashLock
        );
                
        emit LockConsideration(auth.from, to, auth.value, expireDate, hashLock);
    }

    /// @notice Release a lock using the preimage string.
    /// @param lock Hash lock value.
    /// @param key Preimage string (must hash to `lock`).
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

    /// @notice Withdraw a lock after expiry by the creator.
    /// @param lock Hash lock value.
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

    /// @notice Check if a lock is currently locked.
    /// @param lock Hash lock value.
    function isLocked(bytes32 lock) external view returns(bool) {
        return _lockers.isLocked(lock);
    }

    /// @notice Get total number of lockers.
    function counterOfLockers() external view returns(uint) {
        return _lockers.counterOfLockers();
    }

    /// @notice Get locker header by hash.
    /// @param lock Hash lock value.
    function getHeadOfLocker(bytes32 lock) external view returns(UsdLockersRepo.Head memory) {
        return _lockers.getHeadOfLocker(lock);
    }

    /// @notice Get full locker by hash.
    /// @param lock Hash lock value.
    function getLocker(bytes32 lock) external view returns(UsdLockersRepo.Locker memory) {
        return _lockers.getLocker(lock);
    }

    /// @notice Get list of all hash locks.
    function getLockersList() external view returns (bytes32[] memory) {
        return _lockers.getSnList();
    }

    /// @notice Get custody balance for an address.
    /// @param acct Address to query.
    function custodyOf(address acct) external view returns(uint) {
        return _coffers[acct];
    }

    /// @notice Get total custody balance.
    function totalCustody() external view returns(uint) {
        return _coffers[address(1)];
    }
}