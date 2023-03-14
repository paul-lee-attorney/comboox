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

    struct Locker {
        uint40 from;
        uint40 to;
        uint48 expireDate;
        bytes16 hashLock;
    }

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Options ====

    event SetRewards(bytes32 sn);

    event TransferOwnership(address newOwner);

    event TurnOverCenterKey(address newKeeper);

    // ==== Points ====

    event MintPointsTo(uint256 indexed userNo, uint256 amt);

    // ##################
    // ##    写端口    ##
    // ##################

    // ==== Opts Setting ====

    function setRewards(bytes32 sn) external;

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external;

    function turnOverCenterKey(address newKeeper) external;

    // ==== Mint/Sell Points ====

    function mintPointsTo(uint256 to, uint256 amt) external;

    function lockPoints(bytes32 sn, uint256 amt) external;

    function rechargePointsTo(uint256 to, uint256 amt) external;

    function sellPoints(bytes32 sn, uint256 amt) external;

    function fetchPoints(bytes32 sn, string memory hashKey) external;

    function withdrawPoints(bytes32 sn, string memory hashKey) external;

    function checkLocker(bytes32 sn) external view returns (uint216 amount);

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
