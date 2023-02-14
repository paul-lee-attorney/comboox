// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOPKeeper {
    // ###################
    // ##   BOPKeeper   ##
    // ###################

    function createPledge(
        bytes32 sn,
        bytes32 shareNumber,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint40 caller
    ) external;

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint48 expireDate,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint40 caller
    ) external;

    function delPledge(bytes32 sn, uint40 caller) external;
}
