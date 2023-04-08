// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import "./IBookOfGM.sol";
import "../../common/components/MeetingMinutes.sol";

contract BookOfGM is IBookOfGM, MeetingMinutes {

    //#################
    //##    写接口    ##
    //#################

    // ==== Corp Register ====

    function createCorpSeal() external onlyDirectKeeper {
        _rc.regUser();
    }

    function createBoardSeal(address board) external onlyDirectKeeper {
        _rc.setBackupKey(board);
    }
}
