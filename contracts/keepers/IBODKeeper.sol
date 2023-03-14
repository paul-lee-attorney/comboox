// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBODKeeper {
    function appointOfficer(
        uint256 seqOfBSR,
        uint256 seqOfTitle,
        uint256 nominator,
        uint256 candidate
    ) external;

    function takePosition(uint256 seqOfBSR, uint256 seqOfTitile, uint256 motionId, uint256 candidate) external;

    function removeDirector(uint256 director, uint256 appointer) external;

    function quitPosition(uint256 director) external;

    // ==== resolution ====

    function entrustDelegate(
        uint256 caller,
        uint256 delegate,
        uint256 actionId
    ) external;

    function proposeAction(
        uint256 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 submitter,
        uint256 executor
    ) external;

    function castVote(
        uint256 actionId,
        uint8 attitude,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function voteCounting(uint256 actionId, uint256 caller) external;

    function execAction(
        uint256 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 caller
    ) external returns (uint256);
}
