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
        uint256 sn,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPaid,
        uint64 pledgedPar,
        uint64 guaranteedAmt,
        uint256 caller
    ) external;

    function updatePledge(
        uint256 seqOfShare,
        uint256 seqOfPledge,
        uint40 creditor,
        uint48 expireDate,
        uint64 pledgedPar,
        uint64 pledgedPaid,
        uint64 guaranteedAmt,
        uint256 caller
    ) external;

    function delPledge(uint256 seqOfShare, uint256 seqOfPledge, uint256 caller) external;
}
