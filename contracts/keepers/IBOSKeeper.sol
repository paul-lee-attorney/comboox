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

    function setPayInAmt(bytes32 snOfLocker, uint amount) external;

    function requestPaidInCapital(bytes32 snOfLocker, string memory hashKey, uint256 caller) external;

    function withdrawPayInAmt(bytes32 snOfLocker) external;

    function decreaseCapital(
        uint256 seqOfShare,
        uint paid,
        uint par
    ) external;

    // function updatePaidInDeadline(uint256 seqOfShare, uint line) external;
}
