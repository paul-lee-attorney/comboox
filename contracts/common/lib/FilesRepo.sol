// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";
import "./RulesParser.sol";

library FilesRepo {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum StateOfFile {
        ZeroPoint,  // 0
        Created,    // 1
        Circulated, // 2
        Established,// 3
        Proposed,   // 4
        Approved,   // 5
        Rejected,   // 6
        Executed,   // 7
        Revoked     // 8
    }

    struct Head {
        uint48 circulateDate;
        uint8 signingDays;
        uint16 closingDays;
        uint16 seqOfVR;
        uint8 shaExecDays;
        uint8 reviewDays;
        uint48 proposeDate;
        uint8 reconsiderDays;
        uint8 votePrepareDays;
        uint8 votingDays;
        uint8 execDaysForPutOpt;
        uint64 seqOfMotion;
        uint8 state;
    }

    // struct Head {
    //     uint48 signingDeadline;
    //     uint48 shaExecDeadline;
    //     uint48 proposeDeadline;
    //     uint48 votingDeadline;
    //     uint48 closingDeadline;
    //     uint8 state;        
    // }

    struct Ref {
        bytes32 docUrl;
        bytes32 docHash;
    }

    struct File {
        bytes32 snOfDoc;
        Head head;
        Ref ref;
    }

    struct Repo {
        mapping(address => File) files;
        EnumerableSet.AddressSet filesList;
    }

    //####################
    //##    modifier    ##
    //####################

    modifier onlyRegistered(Repo storage repo, address body) {
        require(repo.filesList.contains(body),
            "FR.md.OR: doc NOT registered");
        _;
    }

    //##################
    //##    写接口     ##
    //##################

    function regFile(Repo storage repo, bytes32 snOfDoc, address body) 
        public returns (bool flag)
    {
        if (repo.filesList.add(body)) {

            File storage file = repo.files[body];
            
            file.snOfDoc = snOfDoc;
            file.head.state = uint8(StateOfFile.Created);
            flag = true;
        }
    }

    function circulateFile(
        Repo storage repo,
        address body,
        uint16 signingDays,
        uint16 closingDays,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) public onlyRegistered(repo, body) returns (Head memory){

        require(
            repo.files[body].head.state == uint8(StateOfFile.Created),
            "FR.CF: Doc not pending"
        );

        require(signingDays > 0, "FR.CF: zero signingDays");

        require(closingDays >= signingDays + vr.shaExecDays + vr.reviewDays + 
                vr.reconsiderDays + vr.votingDays,
            "FR.CF: insufficient closingDays");

        File storage file = repo.files[body];

        file.head = Head({
            circulateDate: uint48(block.timestamp),
            signingDays: uint8(signingDays),
            closingDays: closingDays,
            seqOfVR: vr.seqOfRule,
            shaExecDays: vr.shaExecDays,
            reviewDays: vr.reviewDays,
            proposeDate: 0,
            reconsiderDays: vr.reconsiderDays,
            votePrepareDays: vr.votePrepareDays,
            votingDays: vr.votingDays,
            execDaysForPutOpt: vr.execDaysForPutOpt,
            seqOfMotion: 0,
            state: uint8(StateOfFile.Circulated)
        });

        // file.head.circulateDate = uint48(block.timestamp);
        

        // file.head.signingDeadline = timestamp + uint48(signingDays) * 86400;
        // file.head.closingDeadline = timestamp + uint48(closingDays) * 86400;

        // file.head.shaExecDeadline = file.head.signingDeadline + uint48(vr.shaExecDays) * 86400;
        // file.head.proposeDeadline = file.head.shaExecDeadline + uint48(vr.reviewDays) * 86400;

        // file.head.state = uint8(StateOfFile.Circulated);

        if (docUrl != bytes32(0) || docHash != bytes32(0)){
            file.ref.docUrl = docUrl;
            file.ref.docHash = docHash;            
        }
        return file.head;
    }

    function establishFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) returns (Head memory){

        require(
            repo.files[body].head.state == uint8(StateOfFile.Circulated),
            "FR.EF: Doc not circulated"
        );

        File storage file = repo.files[body];

        require(block.timestamp <= signingDeadline(repo, body) , 
            "FR.SF: missed signingDeadline");

        file.head.state = uint8(StateOfFile.Established);

        return file.head;
    }

    function proposeFile(
        Repo storage repo,
        address body,
        uint64 seqOfMotion
    ) public onlyRegistered(repo, body) returns(Head memory){

        require(
            repo.files[body].head.state == uint8(StateOfFile.Established),
            "FR.PF: Doc not established"
        );

        uint48 timestamp = uint48(block.timestamp);

        File storage file = repo.files[body];

        require(timestamp > shaExecDeadline(repo, body), 
            "FR.PF: still in shaExecPeriod");

        require(timestamp <= proposeDeadline(repo, body), 
            "FR.PF: missed proposeDeadline");

        file.head.proposeDate = timestamp;
        file.head.seqOfMotion = seqOfMotion;

        // file.head.votingDeadline = timestamp + (uint48(vr.reconsiderDays) + uint48(vr.votingDays)) * 86400;

        file.head.state = uint8(StateOfFile.Proposed);

        return file.head;
    }

    function voteCountingForFile(
        Repo storage repo,
        address body,
        bool approved
    ) public onlyRegistered(repo, body) returns (uint8) {

        require(
            repo.files[body].head.state == uint8(StateOfFile.Proposed),
            "FR.VCFF: Doc not proposed"
        );

        uint48 timestamp = uint48(block.timestamp);

        File storage file = repo.files[body];

        require(timestamp > votingDeadline(repo, body), "FR.VCFF: still in votingPeriod");
        require(timestamp <= closingDeadline(repo, body), "FR.VCFF: missed closingDeadline");

        file.head.state = approved ? 
            uint8(StateOfFile.Approved) : uint8(StateOfFile.Rejected);

        return file.head.state;
    }

    function execFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) {

        require(
            repo.files[body].head.state == uint8(StateOfFile.Approved),
            "FR.EF: Doc not approved"
        );

        uint48 timestamp = uint48(block.timestamp);

        File storage file = repo.files[body];

        require(timestamp <= closingDeadline(repo, body), 
            "FR.EF: missed closingDeadline");

        file.head.state = uint8(StateOfFile.Executed);
    }

    function revokeFile(
        Repo storage repo,
        address body
    ) public onlyRegistered(repo, body) {

        require(
            repo.files[body].head.state != uint8(StateOfFile.Executed),
            "FR.RF: Doc is executed"
        );

        File storage file = repo.files[body];

        require(block.timestamp > closingDeadline(repo, body), 
            "FR.RF: still in execPeriod");

        file.head.state = uint8(StateOfFile.Revoked);
    }

    function setStateOfFile(Repo storage repo, address body, uint state) 
        public onlyRegistered(repo, body)
    {
        repo.files[body].head.state = uint8(state);
    }

    //##################
    //##   read I/O   ##
    //##################

    function signingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.signingDays) * 86400;
    }

    function closingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + uint48(file.head.closingDays) * 86400;
    }

    function shaExecDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + (uint48(file.head.signingDays) + 
            uint48(file.head.shaExecDays)) * 86400;
    }

    function proposeDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.circulateDate + (uint48(file.head.signingDays) + 
            uint48(file.head.shaExecDays) + uint48(file.head.reviewDays)) * 86400;
    }

    function votingDeadline(Repo storage repo, address body) 
        public view returns (uint48) {
        
        File storage file = repo.files[body];
        
        return file.head.proposeDate + (uint48(file.head.reconsiderDays) + 
            uint48(file.head.votingDays)) * 86400;
    }    

    function isRegistered(Repo storage repo, address body) public view returns (bool) {
        return repo.filesList.contains(body);
    }

    function qtyOfFiles(Repo storage repo) public view returns (uint256) {
        return repo.filesList.length();
    }

    function getFilesList(Repo storage repo) public view returns (address[] memory) {
        return repo.filesList.values();
    }

    function getSNOfFile(Repo storage repo, address body)
        public view onlyRegistered(repo, body) returns (bytes32)
    {
        return repo.files[body].snOfDoc;
    }

    function getHeadOfFile(Repo storage repo, address body)
        public view onlyRegistered(repo, body) returns (Head memory)
    {
        return repo.files[body].head;
    }

    function getRefOfFile(Repo storage repo, address body)
        public view onlyRegistered(repo, body) returns (Ref memory) 
    {
        return repo.files[body].ref;
    }

}
