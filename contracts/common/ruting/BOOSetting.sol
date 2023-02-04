// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boo/IBookOfOptions.sol";

import "../access/AccessControl.sol";

contract BOOSetting is AccessControl {
    IBookOfOptions internal _boo;

    function setBOO(address boo) external onlyDK {
        _boo = IBookOfOptions(boo);
    }

    function booAddr() external view returns (address) {
        return address(_boo);
    }
}
