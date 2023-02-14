// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IGeneralKeeper {

    enum TitleOfKeepers {
        BOAKeeper, // 0
        BODKeeper, // 1
        BOHKeeper, // 2
        BOMKeeper, // 3
        BOOKeeper, // 4
        BOPKeeper, // 5
        BOSKeeper, // 6
        ROMKeeper, // 7
        SHAKeeper // 8
    }

    // ###############
    // ##   Event   ##
    // ###############

    event SetBookeeper(uint16 title, address keeper);

    // ######################
    // ##   AccessControl  ##
    // ######################

    function isKeeper(address caller) external returns (bool flag);
}
