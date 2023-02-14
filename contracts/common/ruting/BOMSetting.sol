// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bom/IBookOfMotions.sol";

import "../access/AccessControl.sol";

contract BOMSetting is AccessControl {
    IBookOfMotions internal _bom;

    function setBOM(address bom) external onlyDirectKeeper {
        _bom = IBookOfMotions(bom);
    }

    function bomAddr() external view returns (address) {
        return address(_bom);
    }
}
