// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOOKeeper {
    // #################
    // ##  BOOKeeper  ##
    // #################

    function issueOption(
        bytes32 sn,
        uint256 rightholder,
        uint64 paid,
        uint64 par,
        uint256 caller
    ) external;

    function joinOptionAsObligor(uint256 seqOfOpt, uint256 caller) external;

    function removeObligorFromOption(
        uint256 seqOfOpt,
        uint256 obligor,
        uint256 caller
    ) external;

    function updateOracle(uint256 seqOfOpt, uint64 d1, uint64 d2, uint64 d3) external;

    function execOption(uint256 seqOfOpt, uint256 caller) external;

    function addOrder(
        uint256 seqOfOpt,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint40 buyer,
        uint40 caller
    ) external;

    function removeOrder(
        uint32 seqOfOpt,
        uint16 seqOfOdr,
        uint40 caller
    ) external;

    function requestPledge(
        uint256 seqOfOpt,
        uint256 seqOfOdr,
        uint32 seqOfShare,
        uint64 paid,
        uint64 par,
        uint256 caller
    ) external;

    function lockOption(
        uint256 seqOfOpt,
        bytes32 hashLock,
        uint256 caller
    ) external;

    function closeOption(
        uint256 seqOfOpt,
        string memory hashKey,
        uint256 caller
    ) external;

    function revokeOption(uint256 seqOfOpt, uint256 caller, string memory hashKey) external;

    function releasePledges(uint256 seqOfOpt, uint256 caller) external;
}
