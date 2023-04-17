// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/bod/IBookOfDirectors.sol";

// import "../common/lib/UsersRepo.sol";
// import "../common/lib/MotionsRepo.sol";
import "../common/lib/RulesParser.sol";

interface IBODKeeper {
    function nominateOfficer(
        uint256 seqOfPos,
        uint candidate,
        uint nominator
    ) external;

    function proposeToRemoveOfficer(
        uint256 seqOfPos,
        uint nominator
    ) external;

    // ---- Docs ----

    function proposeDoc(
        address doc,
        uint seqOfVR,
        uint executor,
        uint proposer
    ) external;

    // ---- Actions ----

    function proposeAction(
        uint seqOfVR,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint executor,
        uint proposer
    ) external;

    // ==== Cast Vote ====

    function entrustDelegate(
        uint256 seqOfMotion,
        uint delegate,
        uint caller
    ) external;

    function castVote(
        uint256 seqOfMotion,
        uint attitude,
        bytes32 sigHash,
        uint256 caller
    ) external;

    // ==== Vote Counting ====

    function voteCounting(uint256 seqOfMotion, uint256 caller)
        external;

    // ==== Exec Motion ====

    function takePosition(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external;

    function quitPosition(uint256 seqOfPos, uint caller) external;

    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint target,
        uint caller
    ) external;

    function execAction(
        uint typeOfAction,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory params,
        bytes32 desHash,
        uint256 seqOfMotion,
        uint caller
    ) external returns (uint);
}
