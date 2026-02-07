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

import "../openzeppelin/utils/structs/EnumerableSet.sol";

library UsersRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Key {
        address pubKey;
        uint16 discount;
        uint40 gift; 
        uint40 coupon;
    }

    struct User {
        Key primeKey;
        Key backupKey;
    }

    struct Rule {
        uint40 eoaRewards;
        uint40 coaRewards;
        uint40 floor;
        uint16 rate;
        uint16 para;
    }

    struct Repo {
        // userNo => User
        mapping(uint256 => User) users;
        // key => userNo
        mapping(address => uint) userNo;
        // userNo set        
        EnumerableSet.UintSet usersList;
    }

    // platformRule: Rule({
    //     eoaRewards: users[0].primeKey.gift,
    //     coaRewards: users[0].backupKey.gift,
    //     floor: users[0].backupKey.coupon,
    //     rate: users[0].primeKey.discount,
    //     para: users[0].backupKey.discount
    // });

    // counterOfUers: users[0].primeKey.coupon;
    
    // owner: users[0].primeKey.pubKey;
    // bookeeper: users[0].backupKey.pubKey;

    // ########################
    // ##  Config Setting    ##
    // ########################

    // ==== Platform  ====

    function ruleParser(bytes32 sn) public pure 
        returns(Rule memory rule) 
    {
        uint _sn = uint(sn);

        rule = Rule({
            eoaRewards: uint40(_sn >> 216),
            coaRewards: uint40(_sn >> 176),
            floor: uint40(_sn >> 136),
            rate: uint16(_sn >> 120),
            para: uint16(_sn >> 96)
        });
    }

    function transferOwnership(Repo storage repo, address newOwner) public {
        require(newOwner != address(0), "UR.TO: zero address");
        repo.users[0].primeKey.pubKey = newOwner;
    }

    function handoverCenterKey(Repo storage repo, address newKeeper) public {
        require(newKeeper != address(0), "UR.HCK: zero address");
        repo.users[0].backupKey.pubKey = newKeeper;
    }

    // ==== Coupon ====

    function infoParser(bytes32 info) public pure returns(Key memory)
    {
        uint _info = uint(info);

        Key memory out = Key({
            pubKey: address(0),
            discount: uint16(_info >> 80),
            gift: uint40(_info >> 40),
            coupon: uint40(_info)
        });

        return out;
    }

    function setPlatformRule(Repo storage repo, bytes32 snOfRule) public {

        Rule memory rule = ruleParser(snOfRule);

        User storage opt = repo.users[0];

        opt.primeKey.discount = rule.rate;
        opt.primeKey.gift = rule.eoaRewards;

        opt.backupKey.discount = rule.para;
        opt.backupKey.gift = rule.coaRewards;
        opt.backupKey.coupon = rule.floor;
    }

    function setRoyaltyRule(
        Repo storage repo,
        bytes32 snOfRoyalty,
        address msgSender
    ) public {

        Key memory rule = infoParser(snOfRoyalty);

        uint author = getUserNo(repo, msgSender);
        User storage a = repo.users[author];

        a.backupKey.discount = rule.discount;
        a.backupKey.gift = rule.gift;
        a.backupKey.coupon = rule.coupon;

    }

    function addCouponOnce(Repo storage repo, address targetAddr) public {
        User storage user = repo.users[getUserNo(repo, targetAddr)];
        unchecked {
            user.primeKey.coupon = 
                (user.primeKey.coupon == type(uint40).max) 
                    ? 1 
                    : user.primeKey.coupon + 1;
        }
    }

    // ==== Reg User ====

    function regUser(
        Repo storage repo, address msgSender
    ) public returns (User memory ) {
        require(msgSender != address(0), "UserRepo.RegUser: zero address");
        require(!usedKey(repo, msgSender), "UserRepo.RegUser: used key");

        uint userNo = block.timestamp;
        do {
            userNo = uint40(uint(keccak256(abi.encodePacked(
                userNo, msgSender
            ))));
        } while (userNo == 0 || !repo.usersList.add(userNo));

        repo.userNo[msgSender] = userNo;

        User memory user;

        user.primeKey.pubKey = msgSender;

        Rule memory rule = getPlatformRule(repo);

        if (_isContract(msgSender)) {
            user.primeKey.discount = 1;
            user.primeKey.gift = rule.coaRewards;
        } else user.primeKey.gift = rule.eoaRewards;

        repo.users[userNo] = user;

        return user;
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    function setBackupKey(
        Repo storage repo, 
        address bKey, 
        address msgSender
    ) public {
        require(msgSender != address(0), "UserRepo.SetBackupKey: zero address");
        require(bKey != address(0), "UserRepo.SetBackupKey: zero address");
        require (!usedKey(repo, bKey), "UserRepo.SetBackupKey: used key");

        uint caller = getUserNo(repo, msgSender);

        User storage user = repo.users[caller];

        require(user.backupKey.pubKey == address(0), 
            "UR.SBK: already set backupKey");
        
        user.backupKey.pubKey = bKey;

        repo.userNo[bKey] = caller;
    }

    function upgradeBackupToPrime(
        Repo storage repo,
        address msgSender
    ) public {
        require(usedKey(repo, msgSender), 
            "UR.UBP: not registered");
        
        User storage user = repo.users[getUserNo(repo, msgSender)];

        require(user.backupKey.pubKey != address(0), 
            "UR.UBP: zero backup key");

        (user.primeKey.pubKey, user.backupKey.pubKey) =
            (user.backupKey.pubKey, user.primeKey.pubKey);
    }


    // ##############
    // ## Read I/O ##
    // ##############

    // ==== Config ====
     
    function getOwner(Repo storage repo) public view returns (address) {
        return repo.users[0].primeKey.pubKey;
    }

    function getBookeeper(Repo storage repo) public view returns (address) {
        return repo.users[0].backupKey.pubKey;
    }

    function getPlatformRule(Repo storage repo) public view 
        returns (Rule memory rule) 
    {
        User storage opt = repo.users[0];

        rule = Rule({
            eoaRewards: opt.primeKey.gift,
            coaRewards: opt.backupKey.gift,
            floor: opt.backupKey.coupon,
            rate: opt.primeKey.discount,
            para: opt.backupKey.discount
        });
    }
    
    // ==== User & No ====

    function isUserNo(Repo storage repo, uint acct) public view returns (bool) {
        return repo.usersList.contains(acct);
    }

    function getUserNo(Repo storage repo, address targetAddr) 
        public view returns(uint40) 
    {
        uint40 user = uint40(repo.userNo[targetAddr]);

        if (user > 0) return user;
        else revert ("UR.getUserNo: not registered");
    }

    function counterOfUsers(Repo storage repo) public view returns (uint) {
        return repo.usersList.length();
    }

    function getUserNoList(Repo storage repo) public view returns (uint[] memory) { 
        return repo.usersList.values(); 
    }

    function getUser(Repo storage repo, address targetAddr) 
        public view returns (User memory)
    {
        return repo.users[getUserNo(repo, targetAddr)];
    }

    function getRoyaltyRule(Repo storage repo, uint author)
        public view returns (Key memory) 
    {
        require (author > 0, "zero author");

        Key memory rule = repo.users[author].backupKey;
        delete rule.pubKey;

        return rule;
    }

    // ==== Key ====

    function usedKey(Repo storage repo, address key) public view returns (bool) {
        return repo.userNo[key] > 0;
    }

    function isPrimeKey(Repo storage repo, address key) public view returns (bool) {
        if (usedKey(repo, key)) {
            return key == repo.users[repo.userNo[key]].primeKey.pubKey;
        } else return false;
    }

}
