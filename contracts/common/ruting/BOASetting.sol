// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boa/IBookOfIA.sol";

import "../access/RegCenterSetting.sol";

contract BOASetting is RegCenterSetting {
    function _getBOA() internal view returns (IBookOfIA _boa) {
        _boa = IBookOfIA(_gk.getBook(uint8(TitleOfBooks.BookOfIA)));
    }
}
