// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/LockersRepo.sol";

library UsersRepo {
    using LockersRepo for LockersRepo.Repo;

    struct Key {
        address pubKey;
        uint16 seqOfKey;
        uint32 dataOfKey;
        uint48 dateOfKey;        
    }

    struct User {
        bool isCOA;
        uint32 counterOfV;
        uint216 balance;
        Key primeKey;
        Key backupKey;
    }

    struct Reward {
        uint32 eoaRewards;
        uint32 coaRewards;
        uint32 offAmt;
        uint16 discRate;
        uint16 refundRatio;
        uint64 ceiling;
        uint64 floor;
    }

    struct Repo {
        // userNo => User
        mapping(uint256 => User) users;
        // key => userNo
        mapping(address => uint) userNo;
        LockersRepo.Repo lockers;       
    }

    // ####################
    // ##    Modifier    ##
    // ####################

    modifier onlyOwner(Repo storage repo, address msgSender) {
        require(msgSender == getOwner(repo), 
            "UR.mf.OO: not owner");
        _;
    }

    modifier onlyKeeper(Repo storage repo, address msgSender) {
        require(msgSender == getBookeeper(repo), 
            "UR.mf.OK: not bookeeper");
        _;
    }

    modifier onlyPrimeKey(Repo storage repo, address msgSender) {
        require(msgSender == repo.users[getMyUserNo(repo, msgSender)].primeKey.pubKey, 
            "UR.mf.OPK: not primeKey");
        _;
    }

    // ########################
    // ##    Opts Setting    ##
    // ########################

    function rewardParser(bytes32 sn) public pure 
        returns(Reward memory reward) 
    {
        uint _sn = uint(sn);

        reward = Reward({
            eoaRewards: uint32(_sn >> 224),
            coaRewards: uint32(_sn >> 192),
            offAmt: uint32(_sn >> 160),
            discRate: uint16(_sn >> 144),
            refundRatio: uint16(_sn >> 128),
            ceiling: uint64(_sn >> 64),
            floor: uint64(_sn)
        });
    }

    function setReward(Repo storage repo, bytes32 snOfReward, address msgSender) 
        public onlyOwner(repo, msgSender) 
    {
        Reward memory rw = rewardParser(snOfReward);
                
        User storage opt = repo.users[0];

        opt.counterOfV = rw.offAmt;
        opt.primeKey = Key({
            pubKey : address(uint160(rw.ceiling)),
            seqOfKey: rw.discRate,
            dataOfKey: rw.eoaRewards,
            dateOfKey: 0
        }); 
        opt.backupKey = Key({
            pubKey : address(uint160(rw.floor)),
            seqOfKey : rw.refundRatio,
            dataOfKey : rw.coaRewards,
            dateOfKey: 0
        });
    }

    function transferOwnership(Repo storage repo, address newOwner, address msgSender) 
        public onlyOwner(repo, msgSender)
    {
        repo.users[1].primeKey.pubKey = newOwner;
    }

    function turnOverCenterKey(Repo storage repo, address newKeeper, address msgSender) 
        public onlyKeeper(repo, msgSender) 
    {
        repo.users[1].backupKey.pubKey = newKeeper;
    }

    // ##################
    // ##    Points    ##
    // ##################

    function mintPoints(Repo storage repo, uint256 to, uint amt, address msgSender) 
        public onlyOwner(repo, msgSender) 
    {
        repo.users[to].balance += uint216(amt);
    }

    function mintAndLockPoints(Repo storage repo, uint to, uint amt, uint expireDate, bytes32 hashLock, address msgSender) 
        public onlyOwner(repo, msgSender) returns (LockersRepo.Head memory head)
    {
        head = _prepareLockerHead(repo, to, amt, expireDate, msgSender);
        repo.lockers.lockPoints(head, hashLock);
    }

    function _prepareLockerHead(
        Repo storage repo, 
        uint to, 
        uint amt, 
        uint expireDate, 
        address msgSender
    ) private returns (LockersRepo.Head memory head) {
        uint40 caller = getMyUserNo(repo, msgSender);

        User storage user = repo.users[caller];

        head = LockersRepo.Head({
            from: caller,
            to: uint40(to),
            expireDate: uint48(expireDate),
            value: uint128(amt)
        });

        if (msgSender != getOwner(repo)) { 
            if (user.balance >= amt) user.balance -= uint128(amt);
            else revert("UR.lockAssets: insufficient balance");
        }
    }

    function transferPoints(
        Repo storage repo, 
        address msgSender, 
        uint256 to, 
        uint amt
    ) public onlyPrimeKey(repo, msgSender)
    {
        uint40 from = getMyUserNo(repo, msgSender);

        if (repo.users[from].balance >= uint216(amt)) {
            repo.users[from].balance -= uint216(amt);
            repo.users[to].balance += uint216(amt);
        } else revert ("UR.transPoints: insufficient balance");
    }

    function lockPoints(Repo storage repo, uint to, uint amt, uint expireDate, bytes32 hashLock, address msgSender) 
        public onlyPrimeKey(repo, msgSender) returns (LockersRepo.Head memory head)
    {
        head = _prepareLockerHead(repo, to, amt, expireDate, msgSender);
        repo.lockers.lockPoints(head, hashLock);
    }

    function lockConsideration(
        Repo storage repo, 
        uint to, 
        uint amt, 
        uint expireDate, 
        address counterLocker, 
        bytes calldata payload, 
        bytes32 hashLock, 
        address msgSender
    ) public onlyPrimeKey(repo, msgSender) returns (LockersRepo.Head memory head) {
        head = _prepareLockerHead(repo, to, amt, expireDate, msgSender);
        LockersRepo.Body memory body = LockersRepo.Body({
            counterLocker: counterLocker,
            payload: payload[ :payload.length - 0x40] // cut off last 2x32 bytes for mock hashKey and its length 
        });
        repo.lockers.lockConsideration(head, body, hashLock);
    }

    function pickupPoints(
        Repo storage repo, 
        bytes32 hashLock, 
        string memory hashKey,
        address msgSender
    ) public returns (LockersRepo.Head memory head) 
    {
        uint caller = getMyUserNo(repo, msgSender);
        head = repo.lockers.pickupPoints(hashLock, hashKey, caller);
        
        if (head.value > 0) {
            repo.users[head.to].balance += head.value;
        }
    }

    function withdrawDeposit(
        Repo storage repo, 
        bytes32 hashLock, 
        address msgSender
    ) public onlyPrimeKey(repo, msgSender) returns (LockersRepo.Head memory head) {
        uint caller = getMyUserNo(repo, msgSender);
        head = repo.lockers.withdrawDeposit(hashLock, caller);
        if (head.value > 0) {
            repo.users[caller].balance += head.value;
        }
    }

    function getLocker(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (LockersRepo.Locker memory locker) 
    {
        locker = repo.lockers.getLocker(hashLock);
    }

    function getLocksList(
        Repo storage repo
    ) public view returns (bytes32[] memory) 
    {
        return repo.lockers.getSnList();
    }

    // ##########################
    // ##    User & Members    ##
    // ##########################

    // ==== reg user ====

    function _increaseCounterOfUsers(Repo storage repo) private returns (uint40 seq) {
        repo.users[0].primeKey.dateOfKey++;
        seq = uint40(repo.users[0].primeKey.dateOfKey);
    }

    function regUser(Repo storage repo, address msgSender) public {

        require(!isKey(repo, msgSender), "UserRepo.RegUser: used key");

        uint seqOfUser = _increaseCounterOfUsers(repo);

        repo.userNo[msgSender] = seqOfUser;

        // User memory user = infoParser(info);
        User memory user;

        user.primeKey.pubKey = msgSender;

        Reward memory rw = getRewardSetting(repo);

        if (_isContract(msgSender)) {
            user.isCOA = true;
            user.balance = rw.coaRewards;
        } else user.balance = rw.eoaRewards;

        repo.users[seqOfUser] = user;
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    function updateUserInfo(Repo storage repo, bytes32 info, address msgSender) 
        public onlyPrimeKey(repo, msgSender)
    {
        uint _info = uint(info);

        uint caller = getMyUserNo(repo, msgSender);
        User storage user = repo.users[caller];

        user.primeKey.seqOfKey = uint16(_info >> 240);
        user.primeKey.dataOfKey = uint32(_info >> 208);
        user.primeKey.dateOfKey = uint48(_info >> 160);

        user.backupKey.seqOfKey = uint16(_info >> 144);
        user.backupKey.dataOfKey = uint32(_info >> 112);
        user.backupKey.dateOfKey = uint48(_info >> 64);

    }

    function setBackupKey(Repo storage repo, address bKey, address msgSender) 
        public onlyPrimeKey(repo, msgSender)
    {
        require (!isKey(repo, bKey), "UR.SBK: used key");

        uint caller = getMyUserNo(repo, msgSender);

        User storage user = repo.users[caller];

        require(user.backupKey.pubKey == address(0), 
            "UR.SBK: already set backupKey");
        
        user.backupKey.pubKey = bKey;

        repo.userNo[bKey] = caller;
    }

    // ##################
    // ##   Read I/O   ##
    // ##################

    // ==== options ====

    function counterOfUsers(Repo storage repo) public view returns (uint40) {
        return uint40(repo.users[0].primeKey.dateOfKey);
    }

    function getOwner(Repo storage repo) public view returns (address) {
        return repo.users[1].primeKey.pubKey;
    }

    function getBookeeper(Repo storage repo) public view returns (address) {
        return repo.users[1].backupKey.pubKey;
    }

    function getRewardSetting(Repo storage repo) 
        public view returns (Reward memory rw)
    {
        User memory opt = repo.users[0];

        rw = Reward({
            eoaRewards: opt.primeKey.dataOfKey,
            coaRewards: opt.backupKey.dataOfKey,
            offAmt: opt.counterOfV,
            discRate: opt.primeKey.seqOfKey,
            refundRatio: opt.backupKey.seqOfKey,
            ceiling: uint64(uint160(opt.primeKey.pubKey)),
            floor: uint64(uint160(opt.backupKey.pubKey)) 
        });
    }

    // ==== register ====

    function isKey(Repo storage repo, address key) public view returns (bool) {
        return repo.userNo[key] > 0;
    }

    function isCOA(Repo storage repo, uint256 acct) external view returns (bool) {
        return repo.users[acct].isCOA;
    }

    function getUser(Repo storage repo, address msgSender) 
        public view returns (User memory)
    {
        return repo.users[getMyUserNo(repo, msgSender)];
    }

    function getUserNo(Repo storage repo, address targetAddr, uint fee, address msgSender) 
        public returns (uint40) 
    {
        uint40 target = getMyUserNo(repo, msgSender);

        if (msgSender != targetAddr) {
            _chargeFee(repo, target, fee);

            if (tx.origin != targetAddr) _chargeFee(repo, getMyUserNo(repo, tx.origin), fee);
            else _awardBonus(repo, msgSender, fee);
        } else return target;

        return uint40(target);
    }

    function getMyUserNo(Repo storage repo, address msgSender) 
        public view returns(uint40) 
    {
        uint40 user = uint40(repo.userNo[msgSender]);

        if (user > 0) return user;
        else revert ("UR.getMyUserNo: not registered");
    }

    function _awardBonus(Repo storage repo, address querySender, uint fee) 
        private 
    {
        Reward memory rw = getRewardSetting(repo);

        uint sender = getMyUserNo(repo, querySender);
        if (sender > 0) {
            repo.users[sender].balance += uint64(fee * rw.refundRatio / 10000);
        }
    }

    function _chargeFee(Repo storage repo, uint user, uint fee) 
        private returns (uint64 afterReward)
    {
        User storage u = repo.users[user];

        Reward memory rw = getRewardSetting(repo);

        uint64 unitPrice = uint64(fee);
        
        uint32 coupon = u.counterOfV * rw.discRate + rw.offAmt;
        afterReward = (coupon < (unitPrice - rw.floor)) 
            ? (unitPrice - coupon) 
            : rw.floor;

        if (u.balance >= afterReward) {
            u.balance -= afterReward;
            u.counterOfV++;
        } else revert("RC.chargeFee: insufficient balance");
    }
}
