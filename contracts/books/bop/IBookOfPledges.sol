// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBookOfPledges {
    //##################
    //##    Event     ##
    //##################

    event CreatePledge(
        bytes32 indexed sn,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    );

    event UpdatePledge(
        bytes32 indexed sn,
        uint40 creditor,
        uint64 expireBN,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    );

    //##################
    //##    写接口    ##
    //##################

    function createPledge(
        bytes32 sn,
        uint40 creditor,
        uint16 monOfGuarantee,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external;

    function updatePledge(
        bytes32 sn,
        uint40 creditor,
        uint64 expireBN,
        uint64 pledgedPar,
        uint64 guaranteedAmt
    ) external;

    //##################
    //##    读接口    ##
    //##################

    function pledgesOf(uint32 ssn) external view returns (bytes32[] memory);

    function counterOfPledges(uint32 ssn) external view returns (uint16);

    function isPledge(bytes32 sn) external view returns (bool);

    function getPledge(bytes32 sn)
        external
        view
        returns (
            uint40 creditor,
            uint64 expireBN,
            uint64 pledgedPar,
            uint64 guaranteedAmt
        );
}
