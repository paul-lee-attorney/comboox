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

import "./EnumerableSet.sol";

library UsdLockersRepo {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    enum StateOfLocker {
        empty,
        locked,
        picked,
        withdrawn
    }

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

    struct Body {
        address counterLocker;
        bytes payload;
    }

    struct Locker {
        Head head;
        Body body;
    }

    struct Repo {
        mapping(bytes32 => Locker) lockers;
        EnumerableSet.Bytes32Set snList;
    }

    function _createHead(
        address from, address to, uint payer, 
        uint payee, uint expireDate, uint amt
    ) private view returns (Head memory head){
        require(from != address(0), "ULR.lockUsd: zero from");
        require(to != address(0), "ULR.lockUsd: zero to");
        require(amt > 0, "ULR.lockUsd: zero amt");

        require(expireDate > block.timestamp, 
            "ULR.lockUsd: not future");

        head = Head({
            from: from,
            payer: uint40(payer),
            expireDate: uint40(expireDate),
            state: 1,
            to: to,
            payee: uint40(payee),
            pickupDate: 0,
            flag: true,
            amt: amt
        });
    }

    function _addLocker(
        Repo storage repo, Head memory head, 
        Body memory body, bytes32 hashLock
    ) private {
        if (repo.snList.add(hashLock)) {
            Locker storage locker = repo.lockers[hashLock];
            locker.head = head;
            locker.body = body;
        } else revert ("ULR.addLocker: occupied");
    }

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

    function lockUsd(
        Repo storage repo, address from, address to, 
        uint expireDate, uint amt, bytes32 hashLock
    ) public {

        Head memory head = 
            _createHead(from, to, 0, 0, expireDate, amt);
        Body memory body;

        _addLocker(repo, head, body, hashLock);
    }

    function releaseUsd(
        Repo storage repo, bytes32 lock, 
        string memory hashKey, address msgSender
    ) public returns(Head memory){

        bytes memory key = bytes(hashKey);

        require(isLocked(repo, lock), 
            "ULR.releaseUsd: not exist");

        require(lock == keccak256(key), 
            "ULR.releaseUsd: wrong key");

        Locker storage locker = repo.lockers[lock];

        require(locker.head.expireDate > block.timestamp,
            "ULR.releaseUsd: lock expired");

        if (locker.body.counterLocker != address(0)) {
            require(locker.head.to == msgSender, 
                "ULR.releaseUSD: wrong msgSender");

            uint len = key.length;
            bytes memory zero = new bytes(32 - (len % 32));

            bytes memory payload = abi.encodePacked(locker.body.payload, len, key, zero);
            (bool flag, ) = locker.body.counterLocker.call(payload);
            require(flag, "ULR.releaseUSD: counter call failed");
        }

        locker.head.pickupDate = uint48(block.timestamp);
        locker.head.state = 2;

        return locker.head;
    }

    function withdrawUsd(
        Repo storage repo, bytes32 lock, address msgSender
    ) public returns(Head memory){

        require(isLocked(repo, lock), 
            "ULR.withdrawUsd: not exist");

        Locker storage locker = repo.lockers[lock];

        require(locker.head.expireDate <= block.timestamp,
            "ULR.withdrawUsd: locker not expired");

        require(locker.head.from == msgSender,
            "ULR.withdrawUsd: not creator");

        locker.head.pickupDate = uint48(block.timestamp);
        locker.head.state = 3;

        return locker.head;
    }

    //##################
    //##   Read I/O   ##
    //##################

    function isLocked(Repo storage repo, bytes32 lock) public view returns(bool){
        return repo.lockers[lock].head.flag;
    }

    function counterOfLockers(Repo storage repo) public view returns(uint) {
        return repo.snList.length();
    }

    function getHeadOfLocker(Repo storage repo, bytes32 lock) public view returns(Head memory) {
        require(isLocked(repo, lock), "ULR.getLocker: not exist");
        return repo.lockers[lock].head;
    }

    function getLocker(Repo storage repo, bytes32 lock) public view returns(Locker memory) {
        require(isLocked(repo, lock), "ULR.getLocker: not exist");
        return repo.lockers[lock];
    }

    function getSnList(Repo storage repo) public view returns (bytes32[] memory) {
        return repo.snList.values();
    }

}