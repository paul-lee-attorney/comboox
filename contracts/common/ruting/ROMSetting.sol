// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "../access/RegCenterSetting.sol";
import "../../books/rom/IRegisterOfMembers.sol";

contract ROMSetting is RegCenterSetting {

    IRegisterOfMembers internal _rom;

    modifier onlyMember() {
        require(_rom.isMember(_msgSender()), "ROMS.mf.OM: NOT Member");
        _;
    }

    modifier memberExist(uint256 acct) {
        require(_rom.isMember(acct), "ROMS.mf.ME: NOT member");
        _;
    }

    function initROM() external {
        _rom = IRegisterOfMembers(_gk.getBook(uint8(TitleOfBooks.RegisterOfMembers)));
        emit SetBookRuting(uint8(TitleOfBooks.RegisterOfMembers), address(_rom));
    }
}
