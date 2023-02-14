// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/ruting/ROMSetting.sol";

import "./IROMKeeper.sol";

contract ROMKeeper is IROMKeeper, ROMSetting {
    // #############
    // ##   ROM   ##
    // #############

    function setMaxQtyOfMembers(uint8 max) external onlyDirectKeeper {
        _rom.setMaxQtyOfMembers(max);
    }

    function setVoteBase(bool onPar) external onlyDirectKeeper {
        _rom.setVoteBase(onPar);
    }

    function setAmtBase(bool onPar) external onlyDirectKeeper {
        _rom.setAmtBase(onPar);
    }
}
