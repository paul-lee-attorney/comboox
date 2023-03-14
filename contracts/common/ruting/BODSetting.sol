// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bod/IBookOfDirectors.sol";

import "../access/RegCenterSetting.sol";

contract BODSetting is RegCenterSetting {

    modifier directorExist(uint256 acct) {
        require(_getBOD().isDirector(acct), "director NOT exist");
        _;
    }

    function _getBOD() internal view returns (IBookOfDirectors _bod) {
        _bod = IBookOfDirectors(_gk.getBook(uint8(TitleOfBooks.BookOfDirectors)));
    }
}
