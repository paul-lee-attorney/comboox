// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IRegCenter {
    // ##################
    // ##    Event     ##
    // ##################

    // ==== Options ====

    event SetBlockSpeed(uint64 speed);

    event SetRewards(
        uint32 eoaRewards,
        uint32 coaRewards,
        uint16 discRate,
        uint32 offAmt
    );

    event TransferOwnership(address newOwner);

    event TurnOverCenterKey(address newKeeper);

    // ==== Points ====

    event MintPointsTo(uint40 indexed userNo, uint96 amt);

    event TransferPointsTo(
        uint40 indexed sender,
        uint40 indexed receiver,
        uint96 amt
    );

    event LockPoints(bytes32 indexed sn, uint96 amt);

    event TakePoints(bytes32 indexed sn, uint96 amt);

    event ChargeFee(uint40 indexed userNo, uint32 fee);

    // ==== User ====

    event RegUser(uint40 indexed userNo, address primeKey, bool isCOA);

    event SetBackupKey(uint40 indexed userNo, address backupKey);

    // event AcceptMember(uint40 indexed userNo, address member);

    // event DismissMember(uint40 indexed userNo, address member);

    // ##################
    // ##    写端口    ##
    // ##################

    // ==== Opts Setting ====

    function setBlockSpeed(uint64 speed) external;

    function setRewards(
        uint32 eoaRewards,
        uint32 coaRewards,
        uint16 discRate,
        uint32 offAmt
    ) external;

    // ==== Power transfer ====

    function transferOwnership(address newOwner) external;

    function turnOverCenterKey(address newKeeper) external;

    // ==== Mint/Sell Points ====

    function mintPointsTo(uint40 to, uint96 amt) external;

    function lockPoints(bytes32 sn, uint96 amt) external;

    function rechargePointsTo(uint40 to, uint96 amt) external;

    function sellPoints(bytes32 sn, uint96 amt) external;

    function fetchPoints(bytes32 sn, string memory hashKey) external;

    function withdrawPoints(bytes32 sn, string memory hashKey) external;

    // ==== User ====

    function regUser() external;

    function setBackupKey(address bKey) external;

    // function acceptMember(address member) external;

    // function dismissMember(address member) external;

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() external view returns (address);

    function getBookeeper() external view returns (address);

    function blocksPerHour() external view returns (uint64);

    function getRewards()
        external
        view
        returns (
            uint32 eoaRewards,
            uint32 coaRewards,
            uint16 discRate,
            uint32 offAmt
        );

    function counterOfUsers() external view returns (uint40);

    function isKey(address key) external view returns (bool);

    function primeKey(uint40 user) external view returns (address);

    function backupKey(uint40 user) external view returns (address);

    function isCOA(uint40 user) external view returns (bool);

    function qtyOfMembers(uint40 user) external view returns (uint32);

    function userNo(address targetAddr) external returns (uint40 target);

    function balanceOf(uint40 user) external view returns (uint96);
}
