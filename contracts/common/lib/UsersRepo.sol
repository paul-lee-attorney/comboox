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
        uint16 refund;
        uint16 discount;
        uint32 gift; 
        uint32 coupon;
    }

    struct User {
        bool isCOA;
        uint32 counterOfV;
        uint216 balance;
        Key primeKey;
        Key backupKey;
    }

    struct Rule {
        uint32 eoaRewards;
        uint32 coaRewards;
        uint32 ceiling;
        uint32 floor;
        uint16 rate;
        uint16 para;
        uint16 argu;
        uint16 seq;
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

    function ruleParser(bytes32 sn) public pure 
        returns(Rule memory rule) 
    {
        uint _sn = uint(sn);

        rule = Rule({
            eoaRewards: uint32(_sn >> 224),
            coaRewards: uint32(_sn >> 192),
            ceiling: uint32(_sn >> 160),
            floor: uint32(_sn >> 128),
            rate: uint16(_sn >> 112),
            para: uint16(_sn >> 96),
            argu: uint16(_sn >> 80),
            seq: uint16(_sn >> 64)
        });
    }

    function setPlatformRule(Repo storage repo, bytes32 snOfRule, address msgSender) 
        public onlyOwner(repo, msgSender) onlyPrimeKey(repo, msgSender) 
    {

        Rule memory rule = ruleParser(snOfRule);

        require(rule.floor < rule.ceiling, "UR.setPlatformRule: floor heigher than ceiling"); 

        User storage opt = repo.users[0];

        opt.primeKey = Key({
            pubKey : address(0),
            refund: rule.rate,
            discount: rule.para,
            gift: rule.eoaRewards,
            coupon: rule.coaRewards
        }); 

        opt.backupKey = Key({
            pubKey : address(0),
            refund: rule.argu,
            discount: rule.seq,
            gift: rule.ceiling,
            coupon: rule.floor
        });
    }

    function getPlatformRule(Repo storage repo) public view 
        returns (Rule memory rule) 
    {
        User storage opt = repo.users[0];

        rule = Rule({
            eoaRewards: opt.primeKey.gift,
            coaRewards: opt.primeKey.coupon,
            ceiling: opt.backupKey.gift,
            floor: opt.backupKey.coupon,
            rate: opt.primeKey.refund,
            para: opt.primeKey.discount,
            argu: opt.backupKey.refund,
            seq: opt.backupKey.discount
        });
    }

    function transferOwnership(Repo storage repo, address newOwner, address msgSender) 
        public onlyOwner(repo, msgSender)
    {
        repo.users[1].primeKey.pubKey = newOwner;
    }

    function handoverCenterKey(Repo storage repo, address newKeeper, address msgSender) 
        public onlyKeeper(repo, msgSender) 
    {
        repo.users[1].backupKey.pubKey = newKeeper;
    }

    // ==== Author Setting ====

    function infoParser(bytes32 info) public pure returns(Key memory)
    {
        uint _info = uint(info);

        Key memory out = Key({
            pubKey: address(0),
            refund: uint16(_info >> 80),
            discount: uint16(_info >> 64),
            gift: uint32(_info >> 32),
            coupon: uint32(_info)
        });

        return out;
    }

    function setRoyaltyRule(
        Repo storage repo,
        bytes32 snOfRoyalty,
        address msgSender
    ) public onlyPrimeKey(repo, msgSender) {

        Key memory rule = infoParser(snOfRoyalty);

        uint author = getMyUserNo(repo, msgSender);
        User storage a = repo.users[author];

        a.backupKey.refund = rule.refund;
        a.backupKey.discount = rule.discount;
        a.backupKey.gift = rule.gift;
        a.backupKey.coupon = rule.coupon;

    }

    function getRoyaltyRule(Repo storage repo, uint author)
        public view returns (Key memory) 
    {
        require (author > 0, 'zero author');

        Key memory rule = repo.users[author].backupKey;
        delete rule.pubKey;

        return rule;
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
        repo.users[0].balance++;
        seq = uint40(repo.users[0].balance);
    }

    function regUser(Repo storage repo, address msgSender) public {

        require(!isKey(repo, msgSender), "UserRepo.RegUser: used key");

        uint seqOfUser = _increaseCounterOfUsers(repo);

        repo.userNo[msgSender] = seqOfUser;

        User memory user;

        user.primeKey.pubKey = msgSender;

        Rule memory rule = getPlatformRule(repo);

        if (_isContract(msgSender)) {
            user.isCOA = true;
            user.balance = rule.coaRewards;
        } else user.balance = rule.eoaRewards;

        repo.users[seqOfUser] = user;
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    function updateUserInfo(Repo storage repo, bytes32 snOfInfo, address msgSender) 
        public onlyPrimeKey(repo, msgSender)
    {
        Key memory info = infoParser(snOfInfo);

        uint caller = getMyUserNo(repo, msgSender);
        Key storage primeKey = repo.users[caller].primeKey;

        primeKey.refund = info.refund;
        primeKey.discount = info.discount;
        primeKey.gift = info.gift;
        primeKey.coupon = info.coupon;
        
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

    // ##############
    // ## Read I/O ##
    // ##############

    // ==== options ====

    function counterOfUsers(Repo storage repo) public view returns (uint40) {
        return uint40(repo.users[0].balance);
    }

    function getOwner(Repo storage repo) public view returns (address) {
        return repo.users[1].primeKey.pubKey;
    }

    function getBookeeper(Repo storage repo) public view returns (address) {
        return repo.users[1].backupKey.pubKey;
    }

    // function getRewardSetting(Repo storage repo) 
    //     public view returns (Reward memory rw)
    // {
    //     User memory opt = repo.users[0];

    //     rw = Reward({
    //         eoaRewards: opt.primeKey.dataOfKey,
    //         coaRewards: opt.backupKey.dataOfKey,
    //         offAmt: opt.counterOfV,
    //         discRate: opt.primeKey.seqOfKey,
    //         refundRatio: opt.backupKey.seqOfKey,
    //         ceiling: uint64(uint160(opt.primeKey.pubKey)),
    //         floor: uint64(uint160(opt.backupKey.pubKey)) 
    //     });
    // }

    // ==== register ====

    function isKey(Repo storage repo, address key) public view returns (bool) {
        return repo.userNo[key] > 0;
    }

    function getUser(Repo storage repo, address msgSender) 
        public view returns (User memory)
    {
        return repo.users[getMyUserNo(repo, msgSender)];
    }

    function getUserNo(Repo storage repo, address targetAddr, uint fee, uint author, address msgSender) 
        public returns (uint40) 
    {
        uint40 target = getMyUserNo(repo, targetAddr);

        if (msgSender != targetAddr && author > 0) {
            _chargeFee(repo, target, fee, author);

            if (tx.origin != targetAddr) 
                _chargeFee(repo, getMyUserNo(repo, tx.origin), fee, author);
            else _refundBonus(repo, msgSender, fee, author);
        }

        return target;
    }

    function getMyUserNo(Repo storage repo, address msgSender) 
        public view returns(uint40) 
    {
        uint40 user = uint40(repo.userNo[msgSender]);

        if (user > 0) return user;
        else revert ("UR.getMyUserNo: not registered");
    }

    function _refundBonus(Repo storage repo, address querySender, uint fee, uint author) 
        private 
    {
        Key memory rt = getRoyaltyRule(repo, author);
        uint sender = repo.userNo[querySender];

        if (sender > 0 && author > 0 && (rt.refund > 0 || rt.gift > 0)) {
            uint32 bonus = uint32(fee) * uint32(rt.refund) / 10000 + rt.gift;

            uint216 balance = repo.users[author].balance;

            bonus = balance > bonus ? bonus : uint32(balance);

            repo.users[author].balance -= bonus;
            repo.users[sender].balance += bonus;
        }
    }

    function _chargeFee(Repo storage repo, uint target, uint fee, uint author) 
        private
    {
        User storage t = repo.users[target];
        User storage a = repo.users[author];
        User storage o = repo.users[1];

        Rule memory pf = getPlatformRule(repo);
        Key memory rt =  getRoyaltyRule(repo, author);
        
        uint32 unitPrice = uint32(fee);
        require(unitPrice >= pf.floor, "UR.chargeFee: unitPrice lower than floor");

        uint32 offAmt = t.counterOfV * uint32(rt.discount) * unitPrice / 10000 + rt.coupon;
        
        unitPrice = (offAmt < (unitPrice - pf.floor)) 
            ? (unitPrice - offAmt) 
            : pf.floor;

        if (unitPrice > pf.ceiling) unitPrice = pf.ceiling;

        if (t.balance >= unitPrice) {
            t.balance -= unitPrice;
            t.counterOfV++;

            o.balance += unitPrice * pf.rate / 10000;
            a.balance += unitPrice * (10000 - pf.rate) / 10000;
        } else revert("RC.chargeFee: insufficient balance");
    }
}
