// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface ITerm {
    function isTriggered(address ia, bytes32 snOfDeal)
        external
        view
        returns (bool);

    function isExempted(address ia, bytes32 snOfDeal)
        external
        view
        returns (bool);
}
