// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../components/IRepoOfDocs.sol";

import "../access/AccessControl.sol";

contract RODSetting is AccessControl {
    IRepoOfDocs internal _rod;

    function setROD(address rod) external onlyDirectKeeper {
        _rod = IRepoOfDocs(rod);
    }

    function rodAddr() external view returns (address) {
        return address(_rod);
    }
}
