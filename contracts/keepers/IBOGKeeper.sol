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
        uint40 caller,
        uint40 delegate
    ) external;

    function nominateOfficer(bytes32 bsRule, uint8 seqOfTitle, uint40 nominator, uint40 candidate) external;

    function proposeDoc(address doc, uint8 typeOfDoc, uint40 caller) external;

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
        uint256 motionId,
        uint40 caller,
        uint8 attitude,
        bytes32 sigHash
    ) external;

    function voteCounting(uint256 motionId, uint40 caller) external;

    function execAction(
        uint8 actionType,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 caller
    ) external returns (uint256);

    function requestToBuy(
        uint256 motionId,
        bytes32 snOfDeal,
        uint40 againstVoter,
        uint40 caller
    ) external;
}
