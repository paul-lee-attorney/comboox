// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/bod/IBookOfDirectors.sol";

// import "../common/lib/UsersRepo.sol";
// import "../common/lib/MotionsRepo.sol";
// import "../common/lib/RulesParser.sol";

interface IBODKeeper {

    // ==== Directors ====

    function takeSeat(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external;

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external;

    // ==== Officers ====

    function takePosition(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external;

    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external;

    // ==== Quit ====

    function quitPosition(uint256 seqOfPos, uint caller) external;

}
