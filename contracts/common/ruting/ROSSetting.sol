// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/ros/IRegisterOfSwaps.sol";
import "../access/RegCenterSetting.sol";

contract ROSSetting is RegCenterSetting {
    function _getROS() internal view returns(IRegisterOfSwaps _ros) {
        _ros = IRegisterOfSwaps(_gk.getBook(uint8(TitleOfBooks.RegisterOfSwaps)));
    }
}
