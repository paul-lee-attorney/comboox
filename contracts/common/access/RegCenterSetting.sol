// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./../../IRegCenter.sol";
import "../../IGeneralKeeper.sol";

contract RegCenterSetting {

    enum TitleOfBooks {
        ZeroPoint,
        BookOfIA,           // 1
        BookOfDirectors,    // 2
        BookOfGM,           // 3
        BookOfSHA,          // 4
        BookOfOptions,      // 5
        BookOfPledges,      // 6
        BookOfShares,       // 7
        RegisterOfMembers,  // 8
        RegisterOfSwaps     // 9
    }

    enum TitleOfKeepers {
        ZeroPoint,
        BOAKeeper, // 1
        BODKeeper, // 2
        BOGKeeper, // 3
        BOHKeeper, // 4
        BOOKeeper, // 5
        BOPKeeper, // 6
        BOSKeeper, // 7
        ROMKeeper, // 8
        ROSKeeper, // 9
        SHAKeeper  // 10
    }

    IRegCenter internal _rc;
    IGeneralKeeper internal _gk;

    // ##################
    // ##    写端口    ##
    // ##################

    function _setRegCenter(address rc) internal {
        require(address(_rc) == address(0), "already set regCenter");

        // emit SetRegCenter(rc);
        _rc = IRegCenter(rc);
    }

    function _setGeneralKeeper(address gk) internal {
        require(address(_gk) == address(0), "already set generalKeeper");

        // emit SetGeneralKeeper(gk);
        _gk = IGeneralKeeper(gk);
    }

    function _msgSender() internal returns (uint40) {
        return _rc.getUserNo(msg.sender);
    }

}
