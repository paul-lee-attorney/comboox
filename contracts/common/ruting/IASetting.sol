// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IIASetting.sol";

import "../access/AccessControl.sol";

import "../../books/boa/IInvestmentAgreement.sol";

contract IASetting is IIASetting, AccessControl {
    IInvestmentAgreement internal _ia;

    //##################
    //##   Modifier   ##
    //##################

    modifier dealExist(uint16 seq) {
        _ia.isDeal(seq);
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setIA(address ia) external onlyDirectKeeper {
        _ia = IInvestmentAgreement(ia);
    }
}
