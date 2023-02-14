// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boh/IShareholdersAgreement.sol";
import "../../books/boh/IBookOfSHA.sol";

import "../access/AccessControl.sol";

contract BOHSetting is AccessControl {
    IBookOfSHA internal _boh;

    function setBOH(address boh) external onlyDirectKeeper {
        _boh = IBookOfSHA(boh);
    }

    function _getSHA() internal view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(_boh.pointer());
    }

    function bohAddr() external view returns (address) {
        return address(_boh);
    }
}
