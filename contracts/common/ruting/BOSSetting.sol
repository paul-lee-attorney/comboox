// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/bos/IBookOfShares.sol";

import "../access/AccessControl.sol";

contract BOSSetting is AccessControl {
    IBookOfShares internal _bos;

    modifier shareExist(uint32 ssn) {
        require(_bos.isShare(ssn), "shareNumber NOT exist");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function setBOS(address bos) external onlyDirectKeeper {
        _bos = IBookOfShares(bos);
    }

    function bosAddr() external view returns (address) {
        return address(_bos);
    }
}
