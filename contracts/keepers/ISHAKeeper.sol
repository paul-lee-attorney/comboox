// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface ISHAKeeper {
    function createDealSN(
        uint16 class,
        uint16 seq,
        uint8 typeOfDeal,
        uint40 seller,
        uint40 buyer,
        uint40 group,
        uint32 ssn,
        uint32 unitPrice,
        uint16 preSeq
    ) external pure returns (bytes32 sn);

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        bytes32 sn,
        bool dragAlong,
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function acceptAlongDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        bytes32 sigHash
    ) external;

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function takeGiftShares(
        address ia,
        bytes32 sn,
        uint40 caller
    ) external;

    // ======== FirstRefusal ========

    function execFirstRefusal(
        address ia,
        bytes32 sn,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function acceptFirstRefusal(
        address ia,
        bytes32 snOfOD,
        uint16 ssnOfFR,
        uint40 caller,
        bytes32 sigHash
    ) external;
}
