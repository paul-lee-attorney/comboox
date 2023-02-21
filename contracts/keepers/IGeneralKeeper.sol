// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IGeneralKeeper {

    // enum TitleOfKeepers {
    //     BOAKeeper, // 0
    //     BODKeeper, // 1
    //     BOGKeeper, // 2
    //     BOHKeeper, // 3
    //     BOOKeeper, // 4
    //     BOPKeeper, // 5
    //     BOSKeeper, // 6
    //     ROMKeeper, // 7
    //     SHAKeeper // 8
    // }

    // ###############
    // ##   Event   ##
    // ###############

    event SetBook(uint16 title, address book);

    event SetBookeeper(uint16 title, address keeper);

    event SetRegNumberHash(bytes32 numHash);

    // ######################
    // ##   AccessControl  ##
    // ######################

    function isKeeper(address caller) external view returns (bool flag);

    function getBook(uint16) external view returns(address book);
}
