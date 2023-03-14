// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ITerm.sol";
import "../../../common/lib/EnumerableSet.sol";


interface IAntiDilution is ITerm {

    struct Benchmark{
        uint16 classOfShare;
        uint64 floorPrice;
        EnumerableSet.UintSet obligors; 
    }

    // ################
    // ##   Write    ##
    // ################



    // ############
    // ##  read  ##
    // ############


}
