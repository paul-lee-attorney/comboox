// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "../access/RegCenterSetting.sol";
import "../../books/rom/IRegisterOfMembers.sol";

contract ROMSetting is RegCenterSetting {
    // IRegisterOfMembers internal _getROM();

    modifier onlyMember() {
        require(_getROM().isMember(_msgSender()), "ROMS.mf.OM: NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(_getROM().isMember(acct), "ROMS.mf.ME: NOT member");
        _;
    }

    function _getROM() internal view returns(IRegisterOfMembers _rom) {
        _rom = IRegisterOfMembers(_gk.getBook(uint8(TitleOfBooks.RegisterOfMembers)));
    }
}
