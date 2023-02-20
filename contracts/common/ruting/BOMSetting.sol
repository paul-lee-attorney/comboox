// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bog/IBookOfGM.sol";

import "../access/AccessControl.sol";

contract BOMSetting is AccessControl {
    IBookOfGM internal _bog;

    function setBOM(address bom) external onlyDirectKeeper {
        _bog = IBookOfGM(bom);
    }

    function bomAddr() external view returns (address) {
        return address(_bog);
    }
}
