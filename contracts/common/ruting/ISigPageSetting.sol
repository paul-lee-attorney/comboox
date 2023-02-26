// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../components/ISigPage.sol";

interface ISigPageSetting {
    
    function setSigPage(address sigPage) external;

    function getSigPage() external view returns (ISigPage);
}
