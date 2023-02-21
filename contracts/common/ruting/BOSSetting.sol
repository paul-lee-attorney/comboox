// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bos/IBookOfShares.sol";

import "../access/RegCenterSetting.sol";

contract BOSSetting is RegCenterSetting {
    modifier shareExist(uint32 ssn) {
        require(_getBOS().isShare(ssn), "shareNumber NOT exist");
        _;
    }

    modifier onlyBOS() {
        require(
            msg.sender == _gk.getBook(uint8(TitleOfBooks.BookOfShares)),
            "ROM.onlyBOS: msgSender is not bos"
        );
        _;
    }

    // ################
    // ##    Read    ##
    // ################

    function _getBOS() internal view returns (IBookOfShares _bos)  {
        _bos = IBookOfShares(_gk.getBook(uint8(TitleOfBooks.BookOfShares)));
    }
}
