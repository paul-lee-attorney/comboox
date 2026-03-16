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

pragma solidity ^0.8.24;

import "../../openzeppelin/utils/structs/EnumerableSet.sol";

/// @title UsdLockersRepo
/// @notice Repository for time-locked USDC escrows keyed by hashLock.
/// @dev Stores locker metadata and optional cross-contract payloads for conditional release.
library UsdLockersRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Locker lifecycle states.
    enum StateOfLocker {
        empty,
        locked,
        picked,
        withdrawn
    }

    /// @notice Locker header metadata.
    /// @dev `expireDate/pickupDate` are unix timestamps; `amt` is USDC in smallest units.
    struct Head {
        address from;
        uint40 payer;
        uint48 expireDate;
        uint8 state;
        address to;
        uint40 payee;
        uint48 pickupDate;
        bool flag;
        uint256 amt;
    }

    /// @notice Optional conditional release payload.
    /// @dev `counterLocker` is the target contract invoked on release.
    struct Body {
        address counterLocker;
        bytes payload;
    }

    /// @notice Full locker record (header + body).
    struct Locker {
        Head head;
        Body body;
    }

    /// @notice Repository storage container.
    struct Repo {
        mapping(bytes32 => Locker) lockers;
        EnumerableSet.Bytes32Set snList;
    }

    //###############
    //##   Error   ##
    //###############

    error ULR_WrongInput(bytes32 reason);
    error ULR_WrongState(bytes32 reason);
    error ULR_Overflow(bytes32 reason);
    error ULR_WrongParty(bytes32 reason);


    /// @notice Create a locker header with basic validation.
    /// @param from Payer address (non-zero).
    /// @param to Payee address (non-zero).
    /// @param payer Payer userNo (uint40 in implementation).
    /// @param payee Payee userNo (uint40 in implementation).
    /// @param expireDate Unix timestamp (must be in the future).
    /// @param amt USDC amount (smallest units, must be > 0).
    /// @return head Newly created header.
    function _createHead(
        address from, address to, uint payer, 
        uint payee, uint expireDate, uint amt
    ) private view returns (Head memory head){
        if (from == address(0)) 
            revert ULR_WrongParty(bytes32("ULR_ZeroFrom"));

        if (to == address(0)) 
            revert ULR_WrongParty(bytes32("ULR_ZeroTo"));

        if (amt == 0) 
            revert ULR_WrongInput(bytes32("ULR_ZeroAmt"));

        if (expireDate <= block.timestamp) 
            revert ULR_WrongInput(bytes32("ULR_NotFuture"));

        head = Head({
            from: from,
            payer: uint40(payer),
            expireDate: uint48(expireDate),
            state: 1,
            to: to,
            payee: uint40(payee),
            pickupDate: 0,
            flag: true,
            amt: amt
        });
    }

    /// @notice Add a locker to storage.
    /// @param repo Repository storage.
    /// @param head Locker header.
    /// @param body Locker body.
    /// @param hashLock Unique hash key (must be unused).
    function _addLocker(
        Repo storage repo, Head memory head, 
        Body memory body, bytes32 hashLock
    ) private {
        if (repo.snList.add(hashLock)) {
            Locker storage locker = repo.lockers[hashLock];
            locker.head = head;
            locker.body = body;
        } else revert ULR_WrongState(bytes32("ULR_Occupied"));
    }

    /// @notice Lock USDC with an external conditional release hook.
    /// @param repo Repository storage.
    /// @param from Payer address.
    /// @param to Payee address.
    /// @param expireDate Unix timestamp when withdrawal is allowed.
    /// @param amt USDC amount (smallest units).
    /// @param counterLocker Target contract for conditional release.
    /// @param payload Calldata payload prefix for target.
    /// @param hashLock Unique hash key for this locker.
    function lockConsideration(
        Repo storage repo, address from, address to, 
        uint expireDate, uint amt, address counterLocker,
        bytes calldata payload, bytes32 hashLock
    ) public {
        Head memory head = 
            _createHead(from, to, 0, 0, expireDate, amt);

        Body memory body = Body({
            counterLocker: counterLocker,
            payload: payload
        });

        _addLocker(repo, head, body, hashLock);
    }

    /// @notice Lock USDC for later release by hash key.
    /// @param repo Repository storage.
    /// @param from Payer address.
    /// @param to Payee address.
    /// @param expireDate Unix timestamp when withdrawal is allowed.
    /// @param amt USDC amount (smallest units).
    /// @param hashLock Unique hash key for this locker.
    function lockUsd(
        Repo storage repo, address from, address to, 
        uint expireDate, uint amt, bytes32 hashLock
    ) public {
        Head memory head = 
            _createHead(from, to, 0, 0, expireDate, amt);
        Body memory body;

        _addLocker(repo, head, body, hashLock);
    }

    /// @notice Release a locker using the preimage of hashLock.
    /// @param repo Repository storage.
    /// @param lock Hash lock value.
    /// @param hashKey Preimage string (must hash to `lock`).
    /// @param msgSender Caller (must be payee for conditional lockers).
    /// @return head Updated locker header.
    function releaseUsd(
        Repo storage repo, bytes32 lock, 
        string memory hashKey, address msgSender
    ) public returns(Head memory){
        bytes memory key = bytes(hashKey);

        if (!isLocked(repo, lock)) 
            revert ULR_WrongState(bytes32("ULR_LockerNotExist"));

        if (lock != keccak256(key)) 
            revert ULR_WrongInput(bytes32("ULR_WrongKey"));

        Locker storage locker = repo.lockers[lock];

        if (locker.head.expireDate <= block.timestamp)
            revert ULR_WrongState(bytes32("ULR_LockExpired"));

        if (locker.head.state != 1) 
            revert ULR_WrongState(bytes32("ULR_LockerNotLocked"));

        locker.head.pickupDate = uint48(block.timestamp);
        locker.head.state = 2;
        locker.head.flag = false;

        if (locker.body.counterLocker != address(0)) {
            if (locker.head.to != msgSender) 
                revert ULR_WrongParty(bytes32("ULR_NotIntendedPayee"));

            uint len = key.length;
            bytes memory zero = new bytes(32 - (len % 32));

            bytes memory payload = abi.encodePacked(locker.body.payload, len, key, zero);
            (bool flag, ) = locker.body.counterLocker.call(payload);

            if (!flag) 
                revert ULR_WrongState(bytes32("ULR_CounterCallFailed"));
        }

        return locker.head;
    }

    /// @notice Withdraw a locker after expiry by the creator.
    /// @param repo Repository storage.
    /// @param lock Hash lock value.
    /// @param msgSender Caller (must be creator).
    /// @return head Updated locker header.
    function withdrawUsd(
        Repo storage repo, bytes32 lock, address msgSender
    ) public returns(Head memory){

        if (!isLocked(repo, lock)) 
            revert ULR_WrongState(bytes32("ULR_LockerNotExist"));

        Locker storage locker = repo.lockers[lock];

        if (locker.head.state != 1) 
            revert ULR_WrongState(bytes32("ULR_LockerNotLocked"));

        if (locker.head.expireDate > block.timestamp)
            revert ULR_WrongState(bytes32("ULR_LockerNotExpired"));

        if (locker.head.from != msgSender)
            revert ULR_WrongParty(bytes32("ULR_NotCreator"));

        locker.head.pickupDate = uint48(block.timestamp);
        locker.head.state = 3;
        locker.head.flag = false;

        return locker.head;
    }

    //##################
    //##   Read I/O   ##
    //##################

    /// @notice Check if a locker is currently locked.
    /// @param repo Repository storage.
    /// @param lock Hash lock value.
    /// @return True if state is `locked`.
    function isLocked(Repo storage repo, bytes32 lock) public view returns(bool){
        return repo.lockers[lock].head.state == uint8(StateOfLocker.locked);
    }

    /// @notice Get total number of lockers.
    /// @param repo Repository storage.
    /// @return Count of lockers.
    function counterOfLockers(Repo storage repo) public view returns(uint) {
        return repo.snList.length();
    }

    /// @notice Get locker header by hash.
    /// @param repo Repository storage.
    /// @param lock Hash lock value.
    /// @return Header record.
    function getHeadOfLocker(Repo storage repo, bytes32 lock) public view returns(Head memory) {
        if (!isLocked(repo, lock)) 
            revert ULR_WrongState(bytes32("ULR_LockerNotExist"));
        return repo.lockers[lock].head;
    }

    /// @notice Get full locker by hash.
    /// @param repo Repository storage.
    /// @param lock Hash lock value.
    /// @return Locker record.
    function getLocker(Repo storage repo, bytes32 lock) public view returns(Locker memory) {
        if (!isLocked(repo, lock)) 
            revert ULR_WrongState(bytes32("ULR_LockerNotExist"));
        return repo.lockers[lock];
    }

    /// @notice Get list of all hash locks.
    /// @param repo Repository storage.
    /// @return Array of hash locks.
    function getSnList(Repo storage repo) public view returns (bytes32[] memory) {
        return repo.snList.values();
    }

}