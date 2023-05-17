// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/IFilesFolder.sol";

interface IBookOfSHA is IFilesFolder{

    //##############
    //##  Event   ##
    //##############

    event ChangePointer(address indexed pointer);

    //##################
    //##    写接口    ##
    //##################

    function changePointer(address body) external;

    //##################
    //##    读接口    ##
    //##################

    function pointer() external view returns (address);
}
