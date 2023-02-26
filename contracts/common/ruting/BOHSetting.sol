// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boh/IShareholdersAgreement.sol";
import "../../books/boh/IBookOfSHA.sol";

import "../access/RegCenterSetting.sol";

contract BOHSetting is RegCenterSetting {

    function _getBOH() internal view returns(IBookOfSHA _boh) {
        _boh = IBookOfSHA(_gk.getBook(uint8(TitleOfBooks.BookOfSHA)));
    }

    function _getSHA() internal view returns(IShareholdersAgreement _sha) {
        _sha = IShareholdersAgreement(_getBOH().pointer());
    }
}
