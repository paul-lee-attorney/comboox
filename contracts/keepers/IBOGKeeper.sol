// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/lib/MotionsRepo.sol";
import "../common/lib/RulesParser.sol";
import "../common/lib/SharesRepo.sol";
import "../common/lib/OfficersRepo.sol";

import "../common/components/IFilesFolder.sol";
import "../common/components/ISigPage.sol";

interface IBOGKeeper {
    // #####################
    // ##   CorpSetting   ##
    // #####################

    function createCorpSeal() external;

    function createBoardSeal(address board) external;

    // ################
    // ##   Motion   ##
    // ################

    function nominateDirector(
        uint256 seqOfPos,
        uint40 candidate,
        uint40 nominator
    ) external;

    function proposeToRemoveDirector(
        uint256 seqOfPos,
        uint40 caller
    ) external;

    function proposeDocOfGM(address doc, uint16 seqOfVR, uint40 executor,  uint40 proposer) external;

    function proposeActionOfGM(
        uint16 seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint40 executor,
        uint40 proposer
    ) external;

    function entrustDelegateOfMember(uint256 motionId, uint40 delegate, uint40 caller) external;

    function proposeMotionOfGM(uint256 seqOfMotion,uint40 caller) external;

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint8 attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    function voteCountingOfGM(uint256 seqOfMotion, uint256 caller) external;

    function takeSeat(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint40 caller 
    ) external;

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint40 target,
        uint40 caller
    ) external;

    function execActionOfGM(
        uint16 typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint40 caller
    ) external;

}
