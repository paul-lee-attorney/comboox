// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bod/IBookOfDirectors.sol";

import "../access/AccessControl.sol";

contract BODSetting is AccessControl {
    IBookOfDirectors internal _bod;

    modifier directorExist(uint40 acct) {
        require(_bod.isDirector(acct), "director NOT exist");
        _;
    }

    function setBOD(address bod) external onlyDK {
        _bod = IBookOfDirectors(bod);
    }

    function bodAddr() external view returns (address) {
        return address(_bod);
    }
}
