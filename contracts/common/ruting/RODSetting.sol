// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../components/IRepoOfDocs.sol";

import "../access/AccessControl.sol";

import "./IRODSetting.sol";

contract RODSetting is IRODSetting, AccessControl {
    IRepoOfDocs internal _rod;

    modifier tempReady(uint8 typeOfDoc) {
        require(_rod.template(typeOfDoc) != address(0), "ROD.md.tr: template NOT set");
        _;
    }

    function setROD(IRepoOfDocs rod) external onlyDirectKeeper {
        _rod = rod;
    }
}
