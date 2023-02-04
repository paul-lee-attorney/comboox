// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boa/IBookOfIA.sol";

import "../access/AccessControl.sol";

contract BOASetting is AccessControl {
    IBookOfIA internal _boa;

    function setBOA(address boa) external onlyDK {
        _boa = IBookOfIA(boa);
    }

    function boaAddr() external view returns (address) {
        return address(_boa);
    }
}
