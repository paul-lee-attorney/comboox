// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boa/IInvestmentAgreement.sol";

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

    // function createCorpSeal(uint info) external;

    // function createBoardSeal(address board) external;

    // ################
    // ##   Motion   ##
    // ################

    function nominateDirector(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external;

    function proposeToRemoveDirector(
        uint256 seqOfPos,
        uint caller
    ) external;

    function proposeDocOfGM(address doc, uint seqOfVR, uint executor,  uint proposer) external;

    function proposeActionOfGM(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external;

    function entrustDelegateOfMember(uint256 motionId, uint delegate, uint caller) external;

    function proposeMotionOfGM(uint256 seqOfMotion,uint caller) external;

    function castVoteOfGM(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    function voteCountingOfGM(uint256 seqOfMotion, uint256 caller) external;

    function takeSeat(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external;

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint target,
        uint caller
    ) external;

    function execActionOfGM(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns(uint);

}
