// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bop/IBookOfPledges.sol";

import "../access/RegCenterSetting.sol";

contract BOPSetting is RegCenterSetting {

    IBookOfPledges internal _bop;

    function initBOP() external {
        _bop = IBookOfPledges(_gk.getBook(uint8(TitleOfBooks.BookOfPledges)));
        emit SetBookRuting(uint8(TitleOfBooks.BookOfPledges), address(_bop));
    }
}
