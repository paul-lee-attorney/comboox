// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/lib/DealsRepo.sol";

interface ITerm {
    function isTriggered(address ia, DealsRepo.Deal memory deal)
        external
        view
        returns (bool);

    function isExempted(address ia, DealsRepo.Deal memory deal)
        external
        view
        returns (bool);
}
