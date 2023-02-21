// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../components/IRepoOfDocs.sol";

interface IRODSetting {
    function setROD(IRepoOfDocs rod) external;
}
