// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./../../IRegCenter.sol";
import "../../IGeneralKeeper.sol";

contract RegCenterSetting {

    // enum TitleOfBooks {
    //     ZeroPoint,
    //     BOC,    // 1
    //     BOD,    // 2
    //     BMM,    // 3
    //     BOM,    // 4
    //     GMM,    // 5
    //     BOI,    // 6
    //     BOO,    // 7
    //     BOP,    // 8
    //     ROS,    // 9
    //     BOS    // 10
    // }

    // enum TitleOfKeepers {
    //     ZeroPoint,
    //     BOCKeeper, // 1
    //     BODKeeper, // 2
    //     BMMKeeper, // 3
    //     BOMKeeper, // 4
    //     GMMKeeper, // 5
    //     BOIKeeper, // 6
    //     BOOKeeper, // 7
    //     BOPKeeper, // 8
    //     ROSKeeper, // 9
    //     SHAKeeper // 10
    // }

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

    function _msgSender(uint fee) internal returns (uint40) {

        uint40 usr = _rc.getUserNo(msg.sender, fee);

        if (usr > 0)
            return usr;
        else revert ("RCS._msgSender: not registered");
        
    }

}
