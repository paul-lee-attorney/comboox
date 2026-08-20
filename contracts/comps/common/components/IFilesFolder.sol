// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "../../../lib/books/FilesRepo.sol";
import "../../../lib/books/RulesParser.sol";

/// @title FilesFolder
/// @notice Base contract for managing document file lifecycle and metadata.
/// @dev Provides keeper-controlled state transitions and read access to file records.
interface IFilesFolder {

    //#############
    //##  Event  ##
    //#############

    /// @notice Emitted when a file state is updated.
    /// @param body Document contract address.
    /// @param state New state value.
    event UpdateStateOfFile(address indexed body, uint indexed state);

    //#################
    //##  Write I/O  ##
    //#################

    /// @notice Register a document file.
    /// @param snOfDoc Encoded document identifier.
    /// @param body Document contract address.
    function regFile(bytes32 snOfDoc, address body) external;

    /// @notice Circulate a file for signing and voting.
    /// @param body Document contract address.
    /// @param signingDays Signing window in days.
    /// @param closingDays Total closing window in days.
    /// @param vr Voting rule parameters.
    /// @param docUrl Document URL hash.
    /// @param docHash Document content hash.
    function circulateFile(
        address body,
        uint16 signingDays,
        uint16 closingDays,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    /// @notice Propose a circulated file for voting.
    /// @param body Document contract address.
    /// @param seqOfMotion Motion sequence number.
    function proposeFile(address body, uint64 seqOfMotion) external;

    /// @notice Record vote counting result for a proposed file.
    /// @param body Document contract address.
    /// @param approved True if approved.
    function voteCountingForFile(address body, bool approved) external;

    /// @notice Execute an approved file.
    /// @param body Document contract address.
    function execFile(address body) external;

    /// @notice Revoke a file.
    /// @param body Document contract address.
    function terminateFile(address body) external;

    /// @notice Force set file state.
    /// @param body Document contract address.
    /// @param state New state value.
    function setStateOfFile(address body, uint state) external;

    //##################
    //##   read I/O   ##
    //##################

    /// @notice Get signing deadline timestamp.
    /// @param body Document contract address.
    function signingDeadline(address body) external view returns (uint48);

    /// @notice Get closing deadline timestamp.
    /// @param body Document contract address.
    function closingDeadline(address body) external view returns (uint48);

    /// @notice Get first execution deadline timestamp.
    /// @param body Document contract address.
    function frExecDeadline(address body) external view returns (uint48);

    /// @notice Get second execution deadline timestamp.
    /// @param body Document contract address.
    function dtExecDeadline(address body) external view returns (uint48);

    /// @notice Get termination start timestamp.
    /// @param body Document contract address.
    function terminateStartpoint(address body) external view returns (uint48);

    /// @notice Get voting deadline timestamp.
    /// @param body Document contract address.
    function votingDeadline(address body) external view returns (uint48);

    /// @notice Check if a file is registered.
    /// @param body Document contract address.
    function isRegistered(address body) external view 
        returns (bool);

    /// @notice Get number of registered files.
    function qtyOfFiles() external view 
        returns (uint256);

    /// @notice Get list of registered file addresses.
    function getFilesList() external view 
        returns (address[] memory);

    /// @notice Get file record by address.
    /// @param body Document contract address.
    function getFile(address body) external view 
        returns (FilesRepo.File memory);

    /// @notice Get file header by address.
    /// @param body Document contract address.
    function getHeadOfFile(address body) external view 
        returns (FilesRepo.Head memory head);
        
}
