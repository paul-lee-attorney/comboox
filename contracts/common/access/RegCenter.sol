// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";

contract RegCenter is IRegCenter {

    // users[0] {
    //     primeKey: owner;
    //     backupKey: bookeeper;
    // }

    // userNo => User
    mapping(uint256 => User) private _users;

    // key => userNo
    mapping(address => uint40) private _userNo;

    // from && to && expireDate && hashLock(kaccak256(4-18)) => amount
    mapping(bytes32 => uint216) private _lockers;

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

    function _rewardsParser(bytes32 sn) private pure returns(Reward memory reward) {
        reward = Reward({
            eoaRewards: uint32(bytes4(sn)),
            coaRewards: uint32(bytes4(sn<<32)),
            offAmt: uint32(bytes4(sn<<64)),
            discRate: uint16(bytes2(sn<<96)),
            distRatio: uint16(bytes2(sn<<112)),
            ceiling: uint64(bytes8(sn<<128)),
            floor: uint64(bytes8(sn<<192))
        });
    }

    function setRewards(bytes32 sn) external onlyOwner {
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

    function _snParser(bytes32 sn) private pure returns(Locker memory locker) 
    {
        locker = Locker({
            from: uint40(bytes5(sn)),
            to: uint40(bytes5(sn<<40)),
            expireDate: uint48(bytes6(sn<<80)),
            hashLock: bytes16(sn<<128)
        });
    }

    function mintPointsTo(uint256 to, uint256 amt) external onlyOwner {
        _users[to].balance += uint216(amt);
        emit MintPointsTo(to, amt);
    }

    function lockPoints(bytes32 sn, uint256 amt) external onlyOwner {
        _lockPoints(sn, uint216(amt));
    }

    function _lockPoints(bytes32 sn, uint216 amt) private {
        Locker memory locker = _snParser(sn);

        require(
            locker.expireDate > block.timestamp,
                "RC.LPT: expireDate not future time");

        require(
            locker.hashLock != bytes16(0),
                "RC.LPT: zero hashLock");

        if (_lockers[sn] == 0) {
            _lockers[sn] = amt;
            // emit LockPoints(sn, amt);
        } else revert("RC.LPT: locker not empty");
    }

    function rechargePointsTo(uint256 to, uint256 amt)
        external
        onlyPrimeKey
        onlyEOA
    {
        uint40 caller = _userNo[msg.sender];

        if (_users[caller].balance > amt) {
            _users[caller].balance -= uint216(amt);
            _users[to].balance += uint216(amt);

            // emit TransferPointsTo(caller, to, amt);
        } else revert("RC.transferPointsTo: insufficient balance");
    }

    function sellPoints(bytes32 sn, uint256 amt) external onlyPrimeKey onlyEOA {
        uint40 caller = _userNo[msg.sender];

        if (_users[caller].balance > amt) {
            _users[caller].balance -= uint216(amt);

            _lockPoints(sn, uint216(amt));
        } else revert("RC.SP: insufficient balance");
    }

    function fetchPoints(bytes32 sn, string memory hashKey)
        external
        onlyPrimeKey
        onlyEOA
    {
        Locker memory locker = _snParser(sn);

        require(
            locker.expireDate > block.timestamp,
                "RC.FP: locker expired");

        uint40 caller = _userNo[msg.sender];

        require(
            locker.to == caller,
            "RC.fetchPoints: caller not buyer"
        );

        _takePoints(sn, locker, hashKey, caller);
    }

    function _takePoints(
        bytes32 sn,
        Locker memory locker,
        string memory hashKey,
        uint40 caller
    ) private {
        if (locker.hashLock == bytes16(keccak256(bytes(hashKey)) << 32)) {
            uint216 amt = _lockers[sn];
            delete _lockers[sn];
            _users[caller].balance += amt;

            // emit TakePoints(sn, amt);
        } else revert("RC.FP: wrong hashKey");
    }

    function withdrawPoints(bytes32 sn, string memory hashKey)
        external
        onlyPrimeKey
        onlyEOA
    {

        Locker memory locker = _snParser(sn);

        require(
            locker.expireDate <= block.timestamp,
                "RC.WP: locker still effective");

        uint40 caller = _userNo[msg.sender];

        require(
            caller == locker.from,
                "RC.withdrawPoints: caller not depositer");

        _takePoints(sn, locker, hashKey, caller);
    }

    function checkLocker(bytes32 sn) external onlyPrimeKey onlyEOA
        view 
        returns (uint216 amount)
    {
        Locker memory locker = _snParser(sn);

        uint40 caller = _userNo[msg.sender];

        require(
            caller == locker.from ||
            caller == locker.to,
                "RC.CL: neither Depositer nor Receiver");

        amount = _lockers[sn];        
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

        // emit RegUser(_userNo[msgSender], msgSender, user.isCOA);
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

        // emit SetBackupKey(caller, bKey);
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

    function getRewardsSetting()
        external
        view
        returns (Reward memory)
    {
        return _rewards;
    }

    // ==== register ====

    function isKey(address key) public view returns (bool) {
        return _userNo[key] > 0;
    }

    function isCOA(uint256 acct) public view returns(bool) {
        return _users[acct].primeKey > address(0) && _users[acct].isCOA;
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
            // emit AwardBonus(sender, fee);
        }
    }

    function _chargeFee(uint40 user) private returns (uint64 fee) {
        User storage u = _users[user];

        uint32 coupon = u.counterOfV * _rewards.discRate + _rewards.offAmt;
        fee = (coupon < (_rewards.ceiling - _rewards.floor)) ? (_rewards.ceiling - coupon) : _rewards.floor;

        if (u.balance >= fee) {
            u.balance -= fee;
            u.counterOfV++;

            // emit ChargeFee(user, fee);
        } else revert("RC.chargeFee: insufficient balance");
    }
}
