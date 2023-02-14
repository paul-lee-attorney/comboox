// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../access/AccessControl.sol";

import "../../books/boa/IInvestmentAgreement.sol";

contract IASetting is AccessControl {
    IInvestmentAgreement internal _ia;

    //##################
    //##   Modifier   ##
    //##################

    modifier dealExist(uint16 ssn) {
        _ia.isDeal(ssn);
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setIA(address ia) external onlyDirectKeeper {
        _ia = IInvestmentAgreement(ia);
    }

    function iaAddr() external view returns (address) {
        return address(_ia);
    }
}
