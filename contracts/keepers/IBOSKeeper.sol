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

    function setPayInAmount(bytes32 sn, uint64 amount) external;

    function requestPaidInCapital(bytes32 sn, string memory hashKey) external;

    function withdrawPayInAmount(bytes32 sn) external;

    function decreaseCapital(
        uint256 seqOfShare,
        uint64 paid,
        uint64 par
    ) external;

    function updatePaidInDeadline(uint256 seqOfShare, uint48 line) external;
}
