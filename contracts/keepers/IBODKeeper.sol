// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBODKeeper {
    function appointOfficer(
        bytes32 bsRule,
        uint8 seqOfTitle,
        uint40 nominator,
        uint40 candidate
    ) external;

    function takePosition(bytes32 bsRule, uint8 seqOfTitile, uint256 motionId, uint40 candidate) external;

    function removeDirector(uint40 director, uint40 appointer) external;

    function quitPosition(uint40 director) external;

    // ==== resolution ====

    function entrustDelegate(
        uint40 caller,
        uint40 delegate,
        uint256 actionId
    ) external;

    function proposeAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 submitter,
        uint40 executor
    ) external;

    function castVote(
        uint256 actionId,
        uint8 attitude,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function voteCounting(uint256 actionId, uint40 caller) external;

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 caller
    ) external returns (uint256);
}
