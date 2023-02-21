// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ISigPage.sol";

import "../ruting/RODSetting.sol";
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

    function _addBlank(uint40 acct, uint16 seq) internal {
        _rod.addBlank(acct, seq);
    }

    function removeBlank(uint40 acct, uint16 seq) public onlyAttorney {
        _rod.removeBlank(acct, seq);
    }

    function addParty(uint40 acct) external onlyAttorney {
        _addBlank(acct, 0);
    }
}
