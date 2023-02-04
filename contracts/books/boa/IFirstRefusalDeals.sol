// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IFirstRefusalDeals {
    //###############
    //##   Event   ##
    //###############

    event ExecFirstRefusal(uint16 seqOfOD, uint16 seqOfFR, uint40 acct);

    event AcceptFirstRefusal(uint16 seqOfOD, uint16 seqOfFR, uint64 ratio);

    //##################
    //##    写接口    ##
    //##################

    function execFirstRefusalRight(
        uint16 seqOfOD,
        uint16 seqOfFR,
        uint40 acct
    ) external;

    function acceptFirstRefusal(uint16 seqOfOD, uint16 seqOfFR)
        external
        returns (uint64 ratio);

    //  #################################
    //  ##       查询接口              ##
    //  #################################

    function sumOfWeight(uint16 seqOfOD) external view returns (uint64);

    function isTargetDeal(uint16 seqOfOD) external view returns (bool);

    function isFRDeal(uint16 seqOfOD, uint16 seqOfFR)
        external
        view
        returns (bool);

    function weightOfFR(uint16 seqOfOD, uint16 seqOfFR)
        external
        view
        returns (uint64);

    function ratioOfFR(uint16 seqOfOD, uint16 seqOfFR)
        external
        view
        returns (uint64);
}
