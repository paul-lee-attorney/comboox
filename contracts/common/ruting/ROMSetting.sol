// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/rom/IRegisterOfMembers.sol";

import "../access/AccessControl.sol";

contract ROMSetting is AccessControl {
    IRegisterOfMembers internal _rom;

    modifier onlyMember() {
        require(_rom.isMember(_msgSender()), "NOT Member");
        _;
    }

    modifier memberExist(uint40 acct) {
        require(_rom.isMember(acct), "member NOT exist");
        _;
    }

    function setROM(address rom) external onlyDirectKeeper {
        _rom = IRegisterOfMembers(rom);
    }

    function romAddr() external view returns (address) {
        return address(_rom);
    }
}
