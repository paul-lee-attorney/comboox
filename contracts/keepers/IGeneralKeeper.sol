// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IGeneralKeeper {
    // ###############
    // ##   Event   ##
    // ###############

    event SetBookeeper(uint8 title, address keeper);

    // ######################
    // ##   AccessControl  ##
    // ######################

    function isKeeper(uint8 title, address caller) external returns (bool flag);
}
