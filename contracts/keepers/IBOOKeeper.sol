// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOOKeeper {
    // #################
    // ##  BOOKeeper  ##
    // #################

    function createOption(
        bytes32 sn,
        uint40 rightholder,
        uint64 paid,
        uint64 par,
        uint40 caller
    ) external;

    function joinOptionAsObligor(bytes32 sn, uint40 caller) external;

    function removeObligorFromOption(
        bytes32 sn,
        uint40 obligor,
        uint40 caller
    ) external;

    function updateOracle(bytes32 sn, uint32 d1, uint32 d2) external;

    function execOption(bytes32 sn, uint40 caller) external;

    function addFuture(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar,
        uint40 caller
    ) external;

    function removeFuture(
        bytes32 sn,
        bytes32 ft,
        uint40 caller
    ) external;

    function requestPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint64 paidPar,
        uint40 caller
    ) external;

    function lockOption(
        bytes32 sn,
        bytes32 hashLock,
        uint40 caller
    ) external;

    function closeOption(
        bytes32 sn,
        string memory hashKey,
        uint40 caller
    ) external;

    function revokeOption(bytes32 sn, uint40 caller) external;

    function releasePledges(bytes32 sn, uint40 caller) external;
}
