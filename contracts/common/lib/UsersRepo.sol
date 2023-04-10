// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/LockersRepo.sol";

library UsersRepo {
    using LockersRepo for LockersRepo.Repo;

    struct User {
        bool isCOA;
        uint32 counterOfV;
        uint216 balance;
        address primeKey;
        uint96 attr;
        address backupKey;
        uint96 para;
    }

    struct Reward {
        uint32 eoaRewards;
        uint32 coaRewards;
        uint32 offAmt;
        uint16 discRate;
        uint16 distRatio;
        uint64 ceiling;
        uint64 floor;
    }

    struct Repo {
        // userNo => User
        mapping(uint256 => User) users;
        // key => userNo
        mapping(address => uint40) userNo;
        Reward reward;
        LockersRepo.Repo lockers;       
    }

    // #################
    // ##   modifier  ##
    // #################

    modifier onlyPrimeKey(Repo storage repo, address msgSender) {
        require(
            msgSender == repo.users[repo.userNo[msgSender]].primeKey,
            "UR.mf.OP: not primeKey"
        );
        _;
    }

    modifier onlyEOA(Repo storage repo, address key) {
        require(
            !repo.users[repo.userNo[msg.sender]].isCOA,
            "UR.mf.OE: not EOA"
        );
        _;
    }

    // ##################
    // ##    Points    ##
    // ##################

    function rewardParser(uint256 sn) public pure 
        returns(Reward memory reward) 
    {
        reward = Reward({
            eoaRewards: uint32(sn >> 224),
            coaRewards: uint32(sn >> 192),
            offAmt: uint32(sn >> 160),
            discRate: uint16(sn >> 144),
            distRatio: uint16(sn >> 128),
            ceiling: uint64(sn >> 64),
            floor: uint64(sn)
        });
    }

    function mintAndLockPoints(Repo storage repo, uint256 snOfLocker, uint amt) 
        public returns (bool flag) 
    {
        flag = repo.lockers.lockValue(snOfLocker, amt, 0);
    }

    function transferPoints(
        Repo storage repo, 
        address msgSender, 
        uint256 to, 
        uint amt
    ) public returns (bool flag)
    {
        uint40 from = repo.userNo[msgSender];

        if (repo.users[from].balance >= uint216(amt)) {
            repo.users[from].balance -= uint216(amt);
            repo.users[to].balance += uint216(amt);
            flag = true;
        }
    }

    function lockPoints(Repo storage repo, address msgSender, uint256 snOfLocker, uint amt) 
        public returns (bool flag)
    {
        uint caller = repo.userNo[msgSender];
        User storage user = repo.users[caller];

        if (user.balance >= amt) {
            user.balance -= uint216(amt);

            flag = repo.lockers.lockValue(snOfLocker, amt, caller);
        }
    }

    function releasePoints(
        Repo storage repo, 
        address msgSender, 
        uint256 snOfLocker, 
        string memory hashKey, 
        uint salt
    ) public returns (uint216 value) {
        uint caller = repo.userNo[msgSender];
        value = uint216(repo.lockers.releaseValue(snOfLocker, hashKey, salt, caller));
        if (value > 0) {
            repo.users[caller].balance += value;
        }
    }

    function withdrawPoints(
        Repo storage repo, 
        address msgSender, 
        uint256 snOfLocker, 
        string memory hashKey, 
        uint salt
    ) public returns (uint216 value) {
        uint caller = repo.userNo[msgSender];
        value = uint216(repo.lockers.withdrawValue(snOfLocker, hashKey, salt, caller));
        if (value > 0) {
            repo.users[caller].balance += value;
        }
    }

    function checkLocker(
        Repo storage repo,
        address msgSender,
        uint256 snOfLocker
    ) public view returns (uint216 value) {
        uint caller = repo.userNo[msgSender];
        value = uint216(repo.lockers.checkLocker(snOfLocker, caller));
    }

    // ##########################
    // ##    User & Members    ##
    // ##########################

    // ==== reg user ====

    function _increaseCounterOfUsers(Repo storage repo) private returns (uint40 seq) {
        repo.users[0].attr++;
        seq = uint40(repo.users[0].attr);
    }

    function regUser(Repo storage repo, address msgSender) public {

        require(!isKey(repo, msgSender), "UR.RU: used key");

        uint40 seqOfUser = _increaseCounterOfUsers(repo);

        repo.userNo[msgSender] = seqOfUser;

        User storage user = repo.users[seqOfUser];

        user.primeKey = msgSender;

        if (_isContract(msgSender)) {
            user.isCOA = true;
            user.balance = repo.reward.coaRewards;
        } else user.balance = repo.reward.eoaRewards;
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    function setBackupKey(Repo storage repo, address msgSender, address bKey) 
        public 
    {
        require (!isKey(repo, bKey), "UR.SBK: used key");

        uint40 caller = repo.userNo[msgSender];

        User storage user = repo.users[caller];

        require(user.backupKey == address(0), 
            "UR.SBK: already set backupKey");
        
        user.backupKey = bKey;

        repo.userNo[bKey] = caller;
    }

    // ##################
    // ##   Read I/O   ##
    // ##################

    // ==== options ====

    function counterOfUsers(Repo storage repo) public view returns (uint40) {
        return uint40(repo.users[0].attr);
    }

    function getOwner(Repo storage repo) public view returns (address) {
        return repo.users[0].primeKey;
    }

    function getBookeeper(Repo storage repo) public view returns (address) {
        return repo.users[0].backupKey;
    }

    function getRewardSetting(Repo storage repo) 
        public view returns (Reward memory)
    {
        return repo.reward;
    }

    // ==== register ====

    function isKey(Repo storage repo, address key) public view returns (bool) {
        return repo.userNo[key] > 0;
    }

    function getUser(Repo storage repo, address msgSender) 
        public view returns (User memory)
    {
        return repo.users[repo.userNo[msgSender]];
    }

    function getUserNo(Repo storage repo, address msgSender, address targetAddr) 
        public returns (uint40) 
    {
        uint40 target = repo.userNo[targetAddr];

        if (msgSender != targetAddr) {
            uint64 fee = _chargeFee(repo, target);

            if (tx.origin != targetAddr) _chargeFee(repo, repo.userNo[tx.origin]);
            else _awardBonus(repo, msgSender, fee);
        } else return getMyUserNo(repo, msgSender);

        return target;
    }

    function getMyUserNo(Repo storage repo, address msgSender) 
        public view returns(uint40) 
    {
        return repo.userNo[msgSender];
    }

    function _awardBonus(Repo storage repo, address querySender, uint fee) 
        private 
    {
        uint sender = repo.userNo[querySender];
        if (sender > 0) {
            repo.users[sender].balance += uint64(fee * repo.reward.distRatio / 10000);
        }
    }

    function _chargeFee(Repo storage repo, uint user) 
        private returns (uint64 fee) 
    {
        User storage u = repo.users[user];

        uint32 coupon = u.counterOfV * repo.reward.discRate + repo.reward.offAmt;
        fee = (coupon < (repo.reward.ceiling - repo.reward.floor)) ? 
                    (repo.reward.ceiling - coupon) : 
                    repo.reward.floor;

        if (u.balance >= fee) {
            u.balance -= fee;
            u.counterOfV++;
        } else revert("RC.chargeFee: insufficient balance");
    }
}
