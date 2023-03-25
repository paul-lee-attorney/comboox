// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOSKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    // ==== BOS funcs ====

    function setPayInAmt(uint256 snOfLocker, uint64 amount) external;

    function requestPaidInCapital(uint256 snOfLocker, string memory hashKey, uint8 salt, uint256 caller) external;

    function withdrawPayInAmt(uint256 snOfLocker) external;

    function decreaseCapital(
        uint256 seqOfShare,
        uint64 paid,
        uint64 par
    ) external;

    function updatePaidInDeadline(uint256 seqOfShare, uint48 line) external;
}
