// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bod/IBookOfDirectors.sol";

import "../access/RegCenterSetting.sol";

contract BODSetting is RegCenterSetting {
    IBookOfDirectors internal _bod;

    modifier directorExist(uint256 acct) {
        require(_bod.isDirector(acct), "director NOT exist");
        _;
    }

    function initBOD() external {
        _bod = IBookOfDirectors(_gk.getBook(uint8(TitleOfBooks.BookOfDirectors)));
        emit SetBookRuting(uint8(TitleOfBooks.BookOfDirectors), address(_bod));
    }
}
