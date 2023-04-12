// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


// import "../lib/EnumerableSet.sol";
import "../lib/FilesRepo.sol";
// import "../lib/DocsRepo.sol";
import "../lib/RulesParser.sol";

interface IFilesFolder {

    //#############
    //##  Event  ##
    //#############

    event UpdateStateOfFile(address indexed body, uint indexed state);

    //#################
    //##  Write I/O  ##
    //#################

    function regFile(uint256 snOfDoc, address body) external;

    function circulateFile(
        address body,
        uint16 signingDays,
        uint16 closingDays,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    function establishFile(address body) external;

    function proposeFile(
        address body,
        RulesParser.VotingRule memory vr
    ) external;

    function voteCountingForFile(address body, bool approved) external;

    function execFile(address body) external;

    function revokeFile(address body) external;

    function setStateOfFile(address body, uint state) external;

    //##################
    //##   read I/O   ##
    //##################

    function isRegistered(address body) external view 
        returns (bool);

    function qtyOfFiles() external view 
        returns (uint256);

    function getFilesList() external view 
        returns (address[] memory);

    function getSNOfFile(address body) external view 
        returns (uint256);

    function getHeadOfFile(address body) external view 
        returns (FilesRepo.Head memory head);

    function getRefOfFile(address body) external view 
        returns (FilesRepo.Ref memory ref);
}
