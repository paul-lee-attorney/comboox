// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegCenter.sol";
import "../../keepers/IGeneralKeeper.sol";

contract RegCenterSetting {

    enum TitleOfBooks {
        BookOfIA, // 0
        BookOfDirectors, // 1
        BookOfGM, // 2
        BookOfSHA, // 3
        BookOfOptions, // 4
        BookOfPledges, // 5
        BookOfShares, // 6
        RegisterOfMembers, // 7
        RegisterOfSwaps
    }

    IRegCenter internal _rc;
    IGeneralKeeper internal _gk;

    // ##################
    // ##   Event      ##
    // ##################

    event SetRegCenter(address rc);
    event SetGeneralKeeper(address gk);
    event SetBookRuting(uint256 title, address book);

    // ##################
    // ##    写端口    ##
    // ##################

    // shall be set up at the creation stage of a contract
    function _setRegCenter(address rc) internal {
        require(address(_rc) == address(0), "already set regCenter");

        emit SetRegCenter(rc);
        _rc = IRegCenter(rc);
    }

    function _setGeneralKeeper(address gk) internal {
        require(address(_gk) == address(0), "already set generalKeeper");

        emit SetGeneralKeeper(gk);
        _gk = IGeneralKeeper(gk);
    }

    function _msgSender() internal returns (uint40) {
        return _rc.userNo(msg.sender);
    }
}
