// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IFilesFolder.sol";

interface IBookOfSHA is IFilesFolder {

    //##############
    //##  Event   ##
    //##############

    event ChangePointer(address pointer);

    //##################
    //##    写接口    ##
    //##################

    // function setTermTemplate(
    //     uint8 title,
    //     address add
    // ) external;

    function changePointer(address body) external;

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address);

    // function hasTemplate(uint8 title) external view returns (bool);

    // function getTermTemplate(uint8 title) external view returns (address);
}
