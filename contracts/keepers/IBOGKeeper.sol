// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOGKeeper {
    // #####################
    // ##   CorpSetting   ##
    // #####################

    function createCorpSeal() external;

    function createBoardSeal() external;

    // ################
    // ##   Motion   ##
    // ################

    function entrustDelegate(
        uint256 motionId,
        uint256 caller,
        uint256 delegate
    ) external;

    function nominateOfficer(uint256 seqOfBSR, uint256 seqOfTitle, uint256 nominator, uint256 candidate) external;

    function proposeDoc(address doc, uint256 seqOfVR, uint256 caller) external;

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
        uint256 motionId,
        uint256 caller,
        uint8 attitude,
        bytes32 sigHash
    ) external;

    function voteCounting(uint256 motionId, uint256 caller) external;

    function execAction(
        uint256 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 caller
    ) external returns (uint256);

    function requestToBuy(
        uint256 motionId,
        uint256 seqOfDeal,
        uint256 againstVoter,
        uint256 caller
    ) external;
}
