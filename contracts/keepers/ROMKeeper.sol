// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "../common/ruting/ROMSetting.sol";

import "./IROMKeeper.sol";

contract ROMKeeper is IROMKeeper, ROMSetting, AccessControl {
    // #############
    // ##   ROM   ##
    // #############

    function setMaxQtyOfMembers(uint8 max) external onlyDirectKeeper {
        _getROM().setMaxQtyOfMembers(max);
    }

    function setVoteBase(bool onPar) external onlyDirectKeeper {
        _getROM().setVoteBase(onPar);
    }

    function setAmtBase(bool onPar) external onlyDirectKeeper {
        _getROM().setAmtBase(onPar);
    }
}
