// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBookSetting {
    //##############
    //##  write   ##
    //##############

    function setBOA(address boa) external;

    function setAgrmtCal(address agrmtCal) external;

    function setBOH(address boh) external;

    function setBOM(address bom) external;

    function setBOO(address boo) external;

    function setBOP(address boo) external;

    function setBOS(address bos) external;

    function setIA(address ia) external;

    function setROM(address rom) external;
}
