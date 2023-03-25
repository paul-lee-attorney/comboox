// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";

import "../lib/LockersRepo.sol";

contract RegCenter is IRegCenter {
    using LockersRepo for LockersRepo.Repo;

    // users[0] {
    //     primeKey: owner;
    //     backupKey: bookeeper;
    // }

    // userNo => User
    mapping(uint256 => User) private _users;

    // key => userNo
    mapping(address => uint40) private _userNo;

    LockersRepo.Repo private _lockers;
    
    Reward private _rewards;

    constructor() {
        _users[0].primeKey = msg.sender;
    }

    // #################
    // ##   modifier  ##
    // #################

    modifier onlyOwner() {
        require(
            msg.sender == _users[0].primeKey,
            "RC.onlyOwner: caller not owner"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            msg.sender == _users[0].backupKey,
            "RC.onlyKeeper: caller not keeper"
        );
        _;
    }

    modifier onlyPrimeKey() {
        require(
            msg.sender == _users[_userNo[msg.sender]].primeKey,
            "RC.onlyPrimeKey: caller not primeKey"
        );
        _;
    }

    modifier onlyNewKey(address key) {
        require(!isKey(key), "RC.onlyNewKey: used key");
        _;
    }

    modifier onlyEOA() {
        require(
            !_users[_userNo[msg.sender]].isCOA,
            "RC.onlyEOA: msgSender not EOA"
        );
        _;
    }

    // ########################
    // ##    Opts Setting    ##
    // ########################

    function _rewardsParser(uint256 sn) private pure 
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

    function setRewards(uint256 sn) external onlyOwner {
        _rewards = _rewardsParser(sn);
        emit SetRewards(sn);
    }

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external onlyOwner {
        _users[0].primeKey = newOwner;
        emit TransferOwnership(newOwner);
    }

    function turnOverCenterKey(address newKeeper) external onlyKeeper {
        _users[0].backupKey = newKeeper;
        emit TurnOverCenterKey(newKeeper);
    }

    // ##################
    // ##    Points    ##
    // ##################

    function mintPointsTo(uint256 to, uint216 amt) external onlyOwner {
        _users[to].balance += amt;
        emit MintPointsTo(to, amt);
    }

    function mintAndLockPoints(uint256 sn, uint216 amt) external onlyOwner {
        if (_lockers.lockValue(sn, amt, _userNo[msg.sender]))
            emit LockPoints(sn, amt);
    }

    function transferPointsTo(uint256 to, uint216 amt)
        external onlyPrimeKey onlyEOA
    {
        uint40 caller = _userNo[msg.sender];

        if (_users[caller].balance >= amt) {
            _users[caller].balance -= amt;
            _users[to].balance += amt;

        } else revert("RC.transferPointsTo: insufficient balance");
    }

    function lockPoints(uint256 sn, uint216 amt) 
        external onlyPrimeKey onlyEOA 
    {
        uint40 caller = _userNo[msg.sender];

        if (_users[caller].balance >= amt) {
            _users[caller].balance -= amt;

            if (_lockers.lockValue(sn, amt, caller))
                emit LockPoints(sn, amt);

        } else revert("RC.SP: insufficient balance");
    }

    function releasePoints(uint256 sn, string memory hashKey, uint8 salt)
        external onlyPrimeKey onlyEOA
    {
        uint40 caller = _userNo[msg.sender];

        uint216 value = uint216(_lockers.releaseValue(sn, hashKey, salt, caller));

        if (value > 0) {
            _users[caller].balance += value;
            emit ReleasePoints(sn, hashKey, salt, value);
        }
    }

    function withdrawPoints(uint256 sn, string memory hashKey, uint8 salt)
        external onlyPrimeKey onlyEOA
    {
        uint40 caller = _userNo[msg.sender];

        uint216 value = uint216(_lockers.withdrawValue(sn, hashKey, salt, caller));

        if (value > 0) {
            _users[caller].balance += value;
            emit WithdrawPoints(sn, hashKey, salt, value);
        }
    }

    function checkLocker(uint256 sn) external onlyPrimeKey onlyEOA
        view returns (uint216 amount)
    {
        uint40 caller = _userNo[msg.sender];
        amount = uint216(_lockers.checkLocker(sn, caller));        
    }

    // ##########################
    // ##    User & Members    ##
    // ##########################

    // ==== reg user ====

    function regUser() external {
        address msgSender = msg.sender;

        require(!isKey(msgSender), "RC.RU: used key");

        _users[0].attr++;        
        uint40 seqOfUser = uint40(_users[0].attr);

        _userNo[msgSender] = seqOfUser;

        User storage user = _users[seqOfUser];

        user.primeKey = msgSender;

        // initial points awarded for new user;
        if (_isContract(msgSender)) {
            user.isCOA = true;
            user.balance = _rewards.coaRewards;
        } else user.balance = _rewards.eoaRewards;
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    function setBackupKey(address bKey) external onlyPrimeKey onlyNewKey(bKey) {
        uint40 caller = _userNo[msg.sender];

        User storage user = _users[caller];

        require(
            user.backupKey == address(0),
            "RC.setBackupKey: already set bKey"
        );
        user.backupKey = bKey;
        _userNo[bKey] = caller;
    }

    // ##################
    // ##   Read I/O   ##
    // ##################

    // ==== options ====

    function getOwner() external view returns (address) {
        return _users[0].primeKey;
    }

    function getBookeeper() external view returns (address) {
        return _users[0].backupKey;
    }

    function getRewardsSetting() external view 
        returns (Reward memory)
    {
        return _rewards;
    }

    // ==== register ====

    function isKey(address key) public view returns (bool) {
        return _userNo[key] > 0;
    }

    function isCOA(uint256 acct) public view returns(bool) {
        return _users[acct].isCOA;
    }

    function getUser(uint256 acct) external view returns (User memory)
    {
        require(_userNo[msg.sender] == acct,
            "RC.GU: not user's primeKey");
        return _users[acct];
    }

    function userNo(address targetAddr) external returns (uint40) {
        uint40 target = _userNo[targetAddr];

        if (msg.sender != targetAddr) {
            uint64 fee = _chargeFee(target);

            if (tx.origin != targetAddr) _chargeFee(_userNo[tx.origin]);
            else _awardBonus(msg.sender, fee);
        }

        return target;
    }

    function _awardBonus(address querySender, uint64 fee) private {
        uint40 sender = _userNo[querySender];
        if (sender > 0) {
            _users[sender].balance += (fee * uint64(_rewards.distRatio) / 10000);
        }
    }

    function _chargeFee(uint40 user) private returns (uint64 fee) {
        User storage u = _users[user];

        uint32 coupon = u.counterOfV * _rewards.discRate + _rewards.offAmt;
        fee = (coupon < (_rewards.ceiling - _rewards.floor)) ? 
                    (_rewards.ceiling - coupon) : 
                    _rewards.floor;

        if (u.balance >= fee) {
            u.balance -= fee;
            u.counterOfV++;
        } else revert("RC.chargeFee: insufficient balance");
    }
}
