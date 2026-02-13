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

import "../openzeppelin/utils/structs/EnumerableSet.sol";
import "./RulesParser.sol";

/// @title FilesRepo
/// @notice Library for managing document file lifecycle and metadata.
/// @dev Stores file records keyed by document contract address.
library FilesRepo {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice File lifecycle state.
    enum StateOfFile {
        ZeroPoint,  // 0
        Created,    // 1
        Circulated, // 2
        Proposed,   // 3
        Approved,   // 4
        Rejected,   // 5
        Closed,     // 6
        Revoked     // 7
    }

    /// @notice Core lifecycle fields and voting windows for a file.
    struct Head {
        uint48 circulateDate;
        uint8 signingDays;
        uint8 closingDays;
        uint16 seqOfVR;
        uint8 frExecDays;
        uint8 dtExecDays;
        uint8 dtConfirmDays;
        uint48 proposeDate;
        uint8 invExitDays;
        uint8 votePrepareDays;
        uint8 votingDays;
        uint8 execDaysForPutOpt;
        uint64 seqOfMotion;
        uint8 state;
    }

    /// @notice Off-chain reference metadata for a file.
    struct Ref {
        bytes32 docUrl;
        bytes32 docHash;
    }

    /// @notice Full file record.
    struct File {
        bytes32 snOfDoc;
        Head head;
        Ref ref;
    }

    /// @notice Repository storage for files.
    struct Repo {
        // Keyed by document contract address.
        mapping(address => File) files;
        // List of registered document contract addresses.
        EnumerableSet.AddressSet filesList;
    }

    //####################
    //##    modifier    ##
    //####################

    /// @dev Reverts if the file is not registered.
    modifier onlyRegistered(Repo storage repo, address body) {
        require(repo.filesList.contains(body),
            "FR.md.OR: doc NOT registered");
        _;
    }

    //##################
    //##  Write I/O   ##
    //##################

    /// @notice Register a document file.
    /// @param repo Repository storage.
    /// @param snOfDoc Encoded document identifier.
    /// @param body Document contract address.
    /// @return flag True if the file is newly registered.
    function regFile(Repo storage repo, bytes32 snOfDoc, address body) 
        public returns (bool flag)
    {
        require(body != address(0), "FR.regFile: zero address");
        if (repo.filesList.add(body)) {

            File storage file = repo.files[body];
            
            file.snOfDoc = snOfDoc;
            file.head.state = uint8(StateOfFile.Created);
            flag = true;
        }
    }

    /// @notice Circulate a file for signing and voting.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    /// @param signingDays Signing window in days.
    /// @param closingDays Total closing window in days.
    /// @param vr Voting rule parameters.
    /// @param docUrl Document URL hash.
    /// @param docHash Document content hash.
    /// @return head Updated head record.
    function circulateFile(
        Repo storage repo,
        address body,
        uint signingDays,
        uint closingDays,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) public onlyRegistered(repo, body) returns (Head memory head){

        require(
            repo.files[body].head.state == uint8(StateOfFile.Created),
            "FR.CF: Doc not pending"
        );

        head = Head({
            circulateDate: uint48(block.timestamp),
            signingDays: uint8(signingDays),
            closingDays: uint8(closingDays),
            seqOfVR: vr.seqOfRule,
            frExecDays: vr.frExecDays,
            dtExecDays: vr.dtExecDays,
            dtConfirmDays: vr.dtConfirmDays,
            proposeDate: 0,
            invExitDays: vr.invExitDays,
            votePrepareDays: vr.votePrepareDays,
            votingDays: vr.votingDays,
            execDaysForPutOpt: vr.execDaysForPutOpt,
            seqOfMotion: 0,
            state: uint8(StateOfFile.Circulated)
        });

        require(head.signingDays > 0, "FR.CF: zero signingDays");

        require(head.closingDays >= signingDays + vr.frExecDays + vr.dtExecDays + vr.dtConfirmDays + 
                vr.invExitDays + vr.votePrepareDays + vr.votingDays,
            "FR.CF: insufficient closingDays");

        File storage file = repo.files[body];

        file.head = head;

        if (docUrl != bytes32(0) || docHash != bytes32(0)){
            file.ref = Ref({
                docUrl: docUrl,
                docHash: docHash
            });   
        }
        return file.head;
    }

    /// @notice Propose a circulated file for voting.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    /// @param seqOfMotion Motion sequence number.
    /// @return Updated head record.
    function proposeFile(
        Repo storage repo,
        address body,
        uint64 seqOfMotion
    ) public onlyRegistered(repo, body) returns(Head memory){

        require(repo.files[body].head.state == uint8(StateOfFile.Circulated),
            "FR.PF: Doc not circulated");

        uint48 timestamp = uint48(block.timestamp);

        require(timestamp >= dtExecDeadline(repo, body), 
            "FR.proposeFile: still in dtExecPeriod");

        File storage file = repo.files[body];

        require(timestamp < terminateStartpoint(repo, body) || (file.head.frExecDays
             + file.head.dtExecDays + file.head.dtConfirmDays) == 0, 
            "FR.proposeFile: missed proposeDeadline");

        file.head.proposeDate = timestamp;
        file.head.seqOfMotion = seqOfMotion;
        file.head.state = uint8(StateOfFile.Proposed);

        return file.head;
    }

    /// @notice Record vote counting result for a proposed file.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    /// @param approved True if approved.
    function voteCountingForFile(
        Repo storage repo,
        address body,
        bool approved
    ) public onlyRegistered(repo, body) {

        require(repo.files[body].head.state == uint8(StateOfFile.Proposed),
            "FR.VCFF: Doc not proposed");

        File storage file = repo.files[body];

        file.head.state = approved ? 
            uint8(StateOfFile.Approved) : uint8(StateOfFile.Rejected);
    }

    /// @notice Execute an approved file.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function execFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) {

        File storage file = repo.files[body];

        require(file.head.state == uint8(StateOfFile.Approved),
            "FR.EF: Doc not approved");

        uint48 timestamp = uint48(block.timestamp);

        require(timestamp < closingDeadline(repo, body), 
            "FR.EF: missed closingDeadline");

        file.head.state = uint8(StateOfFile.Closed);
    }

    /// @notice Revoke a file.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function terminateFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) {

        File storage file = repo.files[body];

        require(file.head.state != uint8(StateOfFile.Closed),
            "FR.terminateFile: Doc is closed");

        file.head.state = uint8(StateOfFile.Revoked);
    }

    /// @notice Force set file state.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    /// @param state New state value.
    function setStateOfFile(Repo storage repo, address body, uint state) 
        public onlyRegistered(repo, body)
    {
        repo.files[body].head.state = uint8(state);
    }

    //##################
    //##   read I/O   ##
    //##################

    /// @notice Get signing deadline timestamp.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function signingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays) * 86400;
    }

    /// @notice Get closing deadline timestamp.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function closingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.closingDays) * 86400;
    }

    /// @notice Get first execution deadline timestamp.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function frExecDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays + 
            file.head.frExecDays) * 86400;
    }

    /// @notice Get second execution deadline timestamp.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function dtExecDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays + 
            file.head.frExecDays + file.head.dtExecDays) * 86400;
    }

    /// @notice Get termination start timestamp.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function terminateStartpoint(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + (uint48(file.head.signingDays + 
            file.head.frExecDays + file.head.dtExecDays + file.head.dtConfirmDays)) * 86400;
    }

    /// @notice Get voting deadline timestamp.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function votingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.proposeDate + (uint48(file.head.invExitDays + 
            file.head.votePrepareDays + file.head.votingDays)) * 86400;
    }    

    /// @notice Check if a file is registered.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function isRegistered(Repo storage repo, address body) public view returns (bool) {
        return repo.filesList.contains(body);
    }

    /// @notice Get number of registered files.
    /// @param repo Repository storage.
    function qtyOfFiles(Repo storage repo) public view returns (uint256) {
        return repo.filesList.length();
    }

    /// @notice Get list of registered file addresses.
    /// @param repo Repository storage.
    function getFilesList(Repo storage repo) public view returns (address[] memory) {
        return repo.filesList.values();
    }

    /// @notice Get file record by address.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function getFile(Repo storage repo, address body) public view returns (File memory) {
        return repo.files[body];
    }

    /// @notice Get file header by address.
    /// @param repo Repository storage.
    /// @param body Document contract address.
    function getHeadOfFile(Repo storage repo, address body)
        public view onlyRegistered(repo, body) returns (Head memory)
    {
        return repo.files[body].head;
    }

}
