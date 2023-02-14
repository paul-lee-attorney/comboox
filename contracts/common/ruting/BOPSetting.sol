// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bop/IBookOfPledges.sol";

import "../access/AccessControl.sol";

contract BOPSetting is AccessControl {
    IBookOfPledges internal _bop;

    function setBOP(address bop) external onlyDirectKeeper {
        _bop = IBookOfPledges(bop);
    }

    function bopAddr() external view returns (address) {
        return address(_bop);
    }
}
