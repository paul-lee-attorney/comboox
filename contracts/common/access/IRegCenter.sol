// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IRegCenter {

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

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Options ====

    event SetRewards(uint256 sn);

    event TransferOwnership(address newOwner);

    event TurnOverCenterKey(address newKeeper);

    // ==== Points ====

    event MintPointsTo(uint256 indexed userNo, uint256 amt);

    event LockPoints(uint256 indexed sn, uint216 value);

    event ReleasePoints(uint256 indexed sn, string hashKey, uint8 salt, uint216 value);

    event WithdrawPoints(uint256 indexed sn, string hashKey, uint8 salt, uint216 value);

    // ##################
    // ##    写端口    ##
    // ##################

    // ==== Opts Setting ====

    function setRewards(uint256 sn) external;

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external;

    function turnOverCenterKey(address newKeeper) external;

    // ==== Mint/Sell Points ====

    function mintPointsTo(uint256 to, uint216 amt) external;

    function mintAndLockPoints(uint256 sn, uint216 amt) external;

    function transferPointsTo(uint256 to, uint216 amt) external;

    function lockPoints(uint256 sn, uint216 amt) external;

    function releasePoints(uint256 sn, string memory hashKey, uint8 salt) external;

    function withdrawPoints(uint256 sn, string memory hashKey, uint8 salt) external;

    function checkLocker(uint256 sn) external view returns (uint216 amt);

    // ==== User ====

    function regUser() external;

    function setBackupKey(address bKey) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() external view returns (address);

    function getBookeeper() external view returns (address);

    function getRewardsSetting()
        external
        view
        returns (Reward memory);

    function isKey(address key) external view returns (bool);

    function isCOA(uint256 acct) external view returns(bool);

    function getUser(uint256 acct) external view returns (User memory);

    function userNo(address targetAddr) external returns (uint40);
}
