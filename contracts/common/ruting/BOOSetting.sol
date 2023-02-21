// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boo/IBookOfOptions.sol";
import "../access/RegCenterSetting.sol";

contract BOOSetting is RegCenterSetting {
    function _getBOO() internal view returns(IBookOfOptions _boo) {
        _boo = IBookOfOptions(_gk.getBook(uint8(TitleOfBooks.BookOfOptions)));
    }
}
