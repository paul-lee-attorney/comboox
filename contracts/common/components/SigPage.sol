// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../ruting/RODSetting.sol";

import "./ISigPage.sol";

contract SigPage is ISigPage, RODSetting {

    //####################
    //##    设置接口     ##
    //####################

    function setSigDeadline(uint48 deadline) external onlyAttorney {
        _rod.setSigDeadline(deadline);
    }

    function setClosingDeadline(uint48 deadline) external onlyAttorney {
        _rod.setClosingDeadline(deadline);
    }

    function addBlank(uint40 acct, uint16 ssn) public {
        _rod.addBlank(acct, ssn);
    }

    function removeBlank(uint40 acct, uint16 ssn) public onlyAttorney {
        _rod.removeBlank(acct, ssn);
    }

    function addParty(uint40 acct) external onlyAttorney {
        addBlank(acct, 0);
    }

    //####################
    //##    查询接口     ##
    //####################

}
