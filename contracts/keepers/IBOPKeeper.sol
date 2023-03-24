// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
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
        uint16 guaranteeDays,
        uint64 paid,
        uint64 par,
        uint64 guaranteedAmt,
        uint256 caller
    ) external;

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint40 buyer,
        uint64 amt,
        uint256 caller        
    ) external;

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint64 amt,
        uint256 caller
    ) external;

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint16 extDays,
        uint256 caller
    ) external;

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint256 caller
    ) external;

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey,
        uint256 caller
    ) external;

    function execPledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external;

    function revokePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external;

}
