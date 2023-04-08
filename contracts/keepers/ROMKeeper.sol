// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

// import "../common/ruting/ROMSetting.sol";

import "./IROMKeeper.sol";

contract ROMKeeper is IROMKeeper, AccessControl {
    // #############
    // ##   ROM   ##
    // #############

    function setMaxQtyOfMembers(uint8 max) external onlyDirectKeeper {
        _gk.getROM().setMaxQtyOfMembers(max);
    }

    function setVoteBase(bool onPar) external onlyDirectKeeper {
        _gk.getROM().setVoteBase(onPar);
    }

    function setAmtBase(bool onPar) external onlyDirectKeeper {
        _gk.getROM().setAmtBase(onPar);
    }
}
