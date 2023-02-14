// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/SNParser.sol";

import "./IRegCenter.sol";

contract RegCenter is IRegCenter {
    using SNParser for bytes32;

    struct User {
        bool isCOA;
        uint32 qtyOfMembers;
        uint32 counterOfV;
        address primeKey;
        address backupKey;
        uint96 balance;
    }

    // users[0] {
    //     primeKey: owner;
    //     backupKey: bookeeper;
    // }

    // userNo => User
    mapping(uint256 => User) private _users;

    // key => userNo
    mapping(address => uint40) private _userNo;

    // from && to && expireDate && hashLock(kaccak256(4-18)) => amount
    mapping(bytes32 => uint96) private _lockers;

    struct OptionsSetting {
        uint64 blocksPerHour;
        uint32 eoaRewards;
        uint32 coaRewards;
        uint32 offAmt;
        uint16 discRate;
        uint40 userCounter;
    }

    OptionsSetting private _opts;

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

    function setBlockSpeed(uint64 speed) external onlyKeeper {
        _opts.blocksPerHour = speed;

        emit SetBlockSpeed(speed);
    }

    function setRewards(
        uint32 eoaRewards,
        uint32 coaRewards,
        uint16 discRate,
        uint32 offAmt
    ) external onlyOwner {
        _opts.eoaRewards = eoaRewards;
        _opts.coaRewards = coaRewards;
        _opts.discRate = discRate;
        _opts.offAmt = offAmt;

        emit SetRewards(eoaRewards, coaRewards, discRate, offAmt);
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

    function mintPointsTo(uint40 to, uint96 amt) external onlyOwner {
        _users[to].balance += amt;

        emit MintPointsTo(to, amt);
    }

    function lockPoints(bytes32 sn, uint96 amt) external onlyOwner {
        _lockPoints(sn, amt);
    }

    function _lockPoints(bytes32 sn, uint96 amt) private {
        require(
            sn.expireDateOfRCLocker() > block.timestamp,
            "RC.lockPointsTo: expireDate not future time"
        );

        require(
            sn.hashLockOfRCLocker() != bytes16(0),
            "RC.lockPointsTo: zero lock"
        );

        if (_lockers[sn] == 0) {
            _lockers[sn] = amt;
            emit LockPoints(sn, amt);
        } else revert("RC.lockPointsTo: locker not empty");
    }

    function rechargePointsTo(uint40 to, uint96 amt)
        external
        onlyPrimeKey
        onlyEOA
    {
        uint40 caller = _userNo[msg.sender];

        if (_users[caller].balance > amt) {
            _users[caller].balance -= amt;
            _users[to].balance += amt;

            emit TransferPointsTo(caller, to, amt);
        } else revert("RC.transferPointsTo: insufficient balance");
    }

    function sellPoints(bytes32 sn, uint96 amt) external onlyPrimeKey onlyEOA {
        uint40 caller = _userNo[msg.sender];

        if (_users[caller].balance > amt) {
            _users[caller].balance -= amt;

            _lockPoints(sn, amt);
        } else revert("RC.sellPoints: insufficient balance");
    }

    function fetchPoints(bytes32 sn, string memory hashKey)
        external
        onlyPrimeKey
        onlyEOA
    {
        require(
            sn.expireDateOfRCLocker() > block.timestamp,
            "RC.fetchPoints: locker expired"
        );

        uint40 caller = _userNo[msg.sender];

        require(
            sn.toOfRCLocker() == caller,
            "RC.fetchPoints: caller not buyer"
        );

        _takePoints(sn, hashKey, caller);
    }

    function _takePoints(
        bytes32 sn,
        string memory hashKey,
        uint40 caller
    ) private {
        if (sn.hashLockOfRCLocker() == keccak256(bytes(hashKey)).hashTrim()) {
            uint96 amt = _lockers[sn];
            delete _lockers[sn];
            _users[caller].balance += amt;

            emit TakePoints(sn, amt);
        } else revert("RC.fetchPoints: wrong hashKey");
    }

    function withdrawPoints(bytes32 sn, string memory hashKey)
        external
        onlyPrimeKey
        onlyEOA
    {
        require(
            sn.expireDateOfRCLocker() <= block.timestamp,
            "RC.withdrawPoints: locker still effective"
        );

        uint40 caller = _userNo[msg.sender];

        require(
            caller == sn.fromOfRCLocker(),
            "RC.withdrawPoints: caller not depositer"
        );

        _takePoints(sn, hashKey, caller);
    }

    // ##########################
    // ##    User & Members    ##
    // ##########################

    // ==== reg user ====

    function regUser() external {
        address msgSender = msg.sender;

        require(!isKey(msgSender), "RC.regUser: used key");

        _opts.userCounter++;

        _userNo[msgSender] = _opts.userCounter;

        User storage user = _users[_opts.userCounter];

        user.primeKey = msgSender;

        // initial points awarded for new user;
        if (_isContract(msgSender)) {
            user.isCOA = true;
            user.balance = _opts.coaRewards;
        } else user.balance = _opts.eoaRewards;

        emit RegUser(_userNo[msgSender], msgSender, user.isCOA);
    }

    function _isContract(address acct) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(acct)
        }
        return size != 0;
    }

    function setBackupKey(address bKey) external onlyPrimeKey onlyNewKey(bKey) {
        address _msgSender = msg.sender;
        uint40 caller = _userNo[_msgSender];

        User storage user = _users[caller];

        require(
            user.backupKey == address(0),
            "RC.setBackupKey: already set bKey"
        );
        user.backupKey = bKey;

        _userNo[bKey] = caller;

        emit SetBackupKey(caller, bKey);
    }

    // function acceptMember(address member)
    //     external
    //     onlyPrimeKey
    //     onlyNewKey(member)
    // {
    //     address _msgSender = msg.sender;
    //     require(_isContract(_msgSender), "RC.acceptMember: caller not COA");
    //     require(_isContract(member), "RC.acceptMember: member not COA");

    //     uint40 caller = _userNo[_msgSender];

    //     _userNo[member] = caller;
    //     _users[caller].qtyOfMembers++;

    //     emit AcceptMember(caller, member);
    // }

    // function dismissMember(address member) external onlyPrimeKey {
    //     uint40 caller = _userNo[msg.sender];

    //     if (_userNo[member] == caller) {
    //         delete _userNo[member];
    //         _users[caller].qtyOfMembers--;
    //         emit DismissMember(caller, member);
    //     } else revert("RC.dismissMember: target not member");
    // }

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

    function blocksPerHour() external view returns (uint64) {
        return _opts.blocksPerHour;
    }

    function getRewards()
        external
        view
        returns (
            uint32 eoaRewards,
            uint32 coaRewards,
            uint16 discRate,
            uint32 offAmt
        )
    {
        eoaRewards = _opts.eoaRewards;
        coaRewards = _opts.coaRewards;
        discRate = _opts.discRate;
        offAmt = _opts.offAmt;
    }

    function counterOfUsers() external view returns (uint40) {
        return _opts.userCounter;
    }

    // ==== register ====

    function isKey(address key) public view returns (bool) {
        return _userNo[key] != 0;
    }

    function primeKey(uint40 user) external view returns (address) {
        return _users[user].primeKey;
    }

    function backupKey(uint40 user) external view returns (address) {
        return _users[user].backupKey;
    }

    function isCOA(uint40 user) external view returns (bool) {
        return _users[user].isCOA;
    }

    function qtyOfMembers(uint40 user) external view returns (uint32) {
        return _users[user].qtyOfMembers;
    }

    function balanceOf(uint40 user) external view returns (uint96) {
        return _users[user].balance;
    }

    function userNo(address targetAddr) external returns (uint40) {
        uint40 target = _userNo[targetAddr];

        if (msg.sender != targetAddr) {
            _chargeFee(target);

            if (tx.origin != targetAddr) _chargeFee(_userNo[tx.origin]);
        }

        return target;
    }

    function _chargeFee(uint40 user) private {
        User storage u = _users[user];

        uint32 coupon = u.counterOfV * _opts.discRate + _opts.offAmt;
        uint32 fee = (coupon < 256000) ? (256168 - coupon) : 168;

        if (u.balance >= fee) {
            u.balance -= fee;
            u.counterOfV++;

            emit ChargeFee(user, fee);
        } else revert("RC.chargeFee: insufficient balance");
    }
}
