// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boo/IBookOfOptions.sol";
import "../access/RegCenterSetting.sol";

contract BOOSetting is RegCenterSetting {

    IBookOfOptions internal _boo;

    function initBOO() external {
        _boo = IBookOfOptions(_gk.getBook(uint8(TitleOfBooks.BookOfOptions)));
        emit SetBookRuting(uint8(TitleOfBooks.BookOfOptions), address(_boo));
    }
}
