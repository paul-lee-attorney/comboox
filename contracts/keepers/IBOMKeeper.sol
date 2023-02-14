// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOMKeeper {
    // #####################
    // ##   CorpSetting   ##
    // #####################

    function createCorpSeal() external;

    function createBoardSeal() external;

    function setRegNumberHash(bytes32 numHash) external;

    // ################
    // ##   Motion   ##
    // ################

    function entrustDelegate(
        uint40 caller,
        uint40 delegate,
        uint256 actionId
    ) external;

    function nominateDirector(uint40 candidate, uint40 nominator) external;

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
        uint8 attitude,
        uint40 caller,
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
        address ia,
        bytes32 sn,
        uint40 againstVoter,
        uint40 caller
    ) external;
}
