// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IMeetingMinutes.sol";

// BookOfGeneralMeeting
interface IBookOfGM is IMeetingMinutes {

    //##################
    //##    写接口     ##
    //##################

    function createCorpSeal() external;

    function createBoardSeal(address bod) external;
}
