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

    function updateOracle(uint256 seqOfOpt, uint32 d1, uint32 d2) external;

    function execOption(uint256 seqOfOpt, uint256 caller) external;

    function addFuture(
        uint256 seqOfOpt,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint256 caller
    ) external;

    function removeFuture(
        uint256 seqOfOpt,
        uint256 seqOfFt,
        uint256 caller
    ) external;

    function requestPledge(
        uint256 seqOfOpt,
        uint256 seqOfShare,
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

    function revokeOption(uint256 seqOfOpt, uint256 caller) external;

    function releasePledges(uint256 seqOfOpt, uint256 caller) external;
}
