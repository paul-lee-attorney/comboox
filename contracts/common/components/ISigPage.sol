// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../ruting/IRODSetting.sol";

interface ISigPage {

    //####################
    //##    设置接口     ##
    //####################

    function setSigDeadline(uint48 deadline) external;

    function setClosingDeadline(uint48 deadline) external;

    function removeBlank(uint40 acct, uint16 ssn) external;

    function addParty(uint40 acct) external;
}
