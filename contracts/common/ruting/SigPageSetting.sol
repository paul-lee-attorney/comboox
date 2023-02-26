// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../components/ISigPage.sol";

import "../access/AccessControl.sol";
import "./ISigPageSetting.sol";

contract SigPageSetting is ISigPageSetting, AccessControl {
    ISigPage internal _page;

    function setSigPage(address sigPage) external onlyDirectKeeper{
        _page = ISigPage(sigPage);
        _page.setBodyOfSigs(address(this));
    }

    function getSigPage() external view returns (ISigPage) {
        return _page;
    }
}
