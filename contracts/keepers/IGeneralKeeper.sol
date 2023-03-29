// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/lib/RolesRepo.sol";

import "./IBOAKeeper.sol";
import "./IBODKeeper.sol";
import "./IBOHKeeper.sol";
import "./IBOGKeeper.sol";
import "./IBOOKeeper.sol";
import "./IBOPKeeper.sol";
import "./IBOSKeeper.sol";
import "./IROMKeeper.sol";
import "./ISHAKeeper.sol";

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

    // enum TitleOfBooks {
    //     BOA, // 0
    //     BOD, // 1
    //     BOG, // 2
    //     BOH, // 3
    //     BOO, // 4
    //     BOP, // 5
    //     BOS, // 6
    //     ROM, // 7
    //     ROS // 8
    // }

    // ###############
    // ##   Event   ##
    // ###############

    event SetBook(uint256 title, address book);

    event SetBookeeper(uint256 title, address keeper);

    event SetRegNumberHash(bytes32 numHash);

    // ######################
    // ##   AccessControl  ##
    // ######################

    function isKeeper(address caller) external view returns (bool flag);

    function getBook(uint256) external view returns(address book);
}
