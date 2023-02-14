// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../lib/SigsRepo.sol";

// import "../access/AccessControl.sol";

import "../ruting/RODSetting.sol";

import "./ISigPage.sol";

contract SigPage is ISigPage, RODSetting {
    // using SigsRepo for SigsRepo.Page;

    // SigsRepo.Page private _sigPage;

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

    // funtion blankCounterOfDoc() public {
    //     _rod.blankCounterOfDoc();
    // }

}
