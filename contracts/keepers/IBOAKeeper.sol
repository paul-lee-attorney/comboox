// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOAKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    function setTempOfIA(address temp, uint8 typeOfDoc) external;

    function createIA(uint8 docType, uint40 caller) external;

    function removeIA(address ia, uint40 caller) external;

    function circulateIA(
        address ia,
        uint40 caller,
        bytes32 docHash
    ) external;

    function signIA(
        address ia,
        uint40 caller,
        bytes32 sigHash
    ) external;

    // ==== Deal & IA ====

    function pushToCoffer(
        address ia,
        bytes32 sn,
        bytes32 hashLock,
        uint48 closingDate,
        uint40 caller
    ) external;

    function closeDeal(
        address ia,
        bytes32 sn,
        string memory hashKey,
        uint40 caller
    ) external;

    function transferTargetShare(
        address ia,
        bytes32 sn,
        uint40 caller
    ) external;

    function issueNewShare(address ia, bytes32 sn) external;

    function revokeDeal(
        address ia,
        bytes32 sn,
        uint40 caller,
        string memory hashKey
    ) external;
}
