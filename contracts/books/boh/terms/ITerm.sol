// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa/IInvestmentAgreement.sol";

interface ITerm {
    function isTriggered(address ia, IInvestmentAgreement.Deal memory deal)
        external
        view
        returns (bool);

    function isExempted(address ia, IInvestmentAgreement.Deal memory deal)
        external
        view
        returns (bool);
}
