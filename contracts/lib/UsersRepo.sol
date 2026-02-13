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

/// @title UsersRepo
/// @notice User registry and platform rules repository for ownership, keeper, and user key management.
/// @dev Stores user metadata keyed by userNo and maps addresses to userNo. Provides
///      registration, rule configuration, and coupon accounting helpers.

import "../openzeppelin/utils/structs/EnumerableSet.sol";

library UsersRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice User key metadata.
    /// @dev `discount/gift/coupon` are short fixed-width counters/values used in pricing rules.
    struct Key {
        address pubKey;
        uint16 discount;
        uint40 gift; 
        uint40 coupon;
    }

    /// @notice User record with prime and backup keys.
    struct User {
        Key primeKey;
        Key backupKey;
    }

    /// @notice Platform rule configuration.
    /// @dev Values are decoded from a packed bytes32 rule descriptor.
    struct Rule {
        uint40 eoaRewards;
        uint40 coaRewards;
        uint40 floor;
        uint16 rate;
        uint16 para;
    }

    /// @notice Repository storage container.
    /// @dev `users[0]` is reserved for platform config and admin keys.
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

    /// @notice Restrict to platform owner (users[0].primeKey.pubKey).
    modifier onlyOwner(Repo storage repo) {
        require(msg.sender == repo.users[0].primeKey.pubKey,
            "UR: not owner");
        _;
    }

    /// @notice Restrict to platform keeper (users[0].backupKey.pubKey).
    modifier onlyKeeper(Repo storage repo) {
        require(msg.sender == repo.users[0].backupKey.pubKey,
            "UR: not keeper");
        _;
    }


    // ########################
    // ##  Config Setting    ##
    // ########################

    // ==== Platform  ====

    /// @notice Parse a packed platform rule into a {Rule} struct.
    /// @param sn Packed rule bytes.
    /// @return rule Decoded rule.
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

    /// @notice Update platform owner address.
    /// @param repo Repository storage.
    /// @param newOwner New owner address (non-zero).
    function transferOwnership(Repo storage repo, address newOwner) public onlyOwner(repo) {
        require(newOwner != address(0), "UR.TO: zero address");
        repo.users[0].primeKey.pubKey = newOwner;
    }

    /// @notice Update platform keeper address.
    /// @param repo Repository storage.
    /// @param newKeeper New keeper address (non-zero).
    function handoverCenterKey(Repo storage repo, address newKeeper) public onlyKeeper(repo) {
        require(newKeeper != address(0), "UR.HCK: zero address");
        repo.users[0].backupKey.pubKey = newKeeper;
    }

    // ==== Coupon ====

    /// @notice Parse a packed royalty rule into a {Key} struct.
    /// @param info Packed rule bytes.
    /// @return out Decoded key values (pubKey zeroed).
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

    /// @notice Set platform rule values.
    /// @param repo Repository storage.
    /// @param snOfRule Packed rule bytes.
    function setPlatformRule(Repo storage repo, bytes32 snOfRule) public onlyOwner(repo) {

        Rule memory rule = ruleParser(snOfRule);

        User storage opt = repo.users[0];

        opt.primeKey.discount = rule.rate;
        opt.primeKey.gift = rule.eoaRewards;

        opt.backupKey.discount = rule.para;
        opt.backupKey.gift = rule.coaRewards;
        opt.backupKey.coupon = rule.floor;
    }

    /// @notice Set per-author royalty rule for msgSender.
    /// @param repo Repository storage.
    /// @param snOfRoyalty Packed rule bytes.
    /// @param msgSender Author address (must be registered).
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

    /// @notice Increment coupon counter for a user once, wrapping to 1 on overflow.
    /// @param repo Repository storage.
    /// @param targetAddr User address (must be registered).
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

    /// @notice Register a new user and assign a unique userNo.
    /// @param repo Repository storage.
    /// @param msgSender User address (non-zero, not used).
    /// @return user Newly created user record.
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

    /// @notice Check whether an address is a contract.
    /// @param acct Address to check.
    /// @return True if code size > 0.
    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    /// @notice Set a backup key for a user.
    /// @param repo Repository storage.
    /// @param bKey Backup key address (non-zero, unused).
    /// @param msgSender User address (must be registered).
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

    /// @notice Swap backup key to become prime key for a user.
    /// @param repo Repository storage.
    /// @param msgSender User address (must be registered, backup key set).
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
     
    /// @notice Get platform owner address.
    /// @param repo Repository storage.
    /// @return Owner address.
    function getOwner(Repo storage repo) public view returns (address) {
        return repo.users[0].primeKey.pubKey;
    }

    /// @notice Get platform keeper address.
    /// @param repo Repository storage.
    /// @return Keeper address.
    function getBookeeper(Repo storage repo) public view returns (address) {
        return repo.users[0].backupKey.pubKey;
    }

    /// @notice Get current platform rule values.
    /// @param repo Repository storage.
    /// @return rule Current rule.
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

    /// @notice Check whether a userNo exists.
    /// @param repo Repository storage.
    /// @param acct User number.
    /// @return True if exists.
    function isUserNo(Repo storage repo, uint acct) public view returns (bool) {
        return repo.usersList.contains(acct);
    }

    /// @notice Resolve userNo by address.
    /// @param repo Repository storage.
    /// @param targetAddr User address.
    /// @return userNo Registered user number.
    function getUserNo(Repo storage repo, address targetAddr) 
        public view returns(uint40) 
    {
        uint40 user = uint40(repo.userNo[targetAddr]);

        if (user > 0) return user;
        else revert ("UR.getUserNo: not registered");
    }

    /// @notice Get total number of registered users.
    /// @param repo Repository storage.
    /// @return Count of users.
    function counterOfUsers(Repo storage repo) public view returns (uint) {
        return repo.usersList.length();
    }

    /// @notice Get list of all user numbers.
    /// @param repo Repository storage.
    /// @return Array of user numbers.
    function getUserNoList(Repo storage repo) public view returns (uint[] memory) { 
        return repo.usersList.values(); 
    }

    /// @notice Get user record by address.
    /// @param repo Repository storage.
    /// @param targetAddr User address.
    /// @return User record.
    function getUser(Repo storage repo, address targetAddr) 
        public view returns (User memory)
    {
        return repo.users[getUserNo(repo, targetAddr)];
    }

    /// @notice Get royalty rule for an author.
    /// @param repo Repository storage.
    /// @param author Author userNo (must be > 0).
    /// @return rule Royalty rule with pubKey cleared.
    function getRoyaltyRule(Repo storage repo, uint author)
        public view returns (Key memory) 
    {
        require (author > 0, "zero author");

        Key memory rule = repo.users[author].backupKey;
        delete rule.pubKey;

        return rule;
    }

    // ==== Key ====

    /// @notice Check if an address is already registered as a key.
    /// @param repo Repository storage.
    /// @param key Address to check.
    /// @return True if used.
    function usedKey(Repo storage repo, address key) public view returns (bool) {
        return repo.userNo[key] > 0;
    }

    /// @notice Check if an address is a user's prime key.
    /// @param repo Repository storage.
    /// @param key Address to check.
    /// @return True if prime key.
    function isPrimeKey(Repo storage repo, address key) public view returns (bool) {
        if (usedKey(repo, key)) {
            return key == repo.users[repo.userNo[key]].primeKey.pubKey;
        } else return false;
    }

}
