// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bos/IBookOfShares.sol";

import "../access/RegCenterSetting.sol";

contract BOSSetting is RegCenterSetting {

    IBookOfShares internal _bos;

    function initBOS() external {
        _bos = IBookOfShares(_gk.getBook(uint8(TitleOfBooks.BookOfShares)));
        emit SetBookRuting(uint8(TitleOfBooks.BookOfShares), address(_bos));
    }

    // ==== Modifier ====

    modifier shareExist(uint32 seqOfShare) {
        require(_bos.isShare(seqOfShare), "shareNumber NOT exist");
        _;
    }

    modifier onlyBOS() {
        require(
            msg.sender == _gk.getBook(uint8(TitleOfBooks.BookOfShares)),
            "ROM.onlyBOS: msgSender is not BOS"
        );
        _;
    }
}
