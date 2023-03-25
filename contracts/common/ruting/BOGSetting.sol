// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bog/IBookOfGM.sol";

import "../access/RegCenterSetting.sol";

contract BOGSetting is RegCenterSetting {
    IBookOfGM internal _bog;

    function initBOG() external {
        _bog = IBookOfGM(_gk.getBook(uint8(TitleOfBooks.BookOfGM)));
        emit SetBookRuting(uint8(TitleOfBooks.BookOfGM), address(_bog));
    }
}
