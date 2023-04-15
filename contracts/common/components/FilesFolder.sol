// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IFilesFolder.sol";

import "../access/AccessControl.sol";

contract FilesFolder is IFilesFolder, AccessControl {
    using FilesRepo for FilesRepo.Repo;

    FilesRepo.Repo private _repo;

    //##################
    //##    写接口     ##
    //##################

    function regFile(bytes32 snOfDoc, address body)
        external onlyDirectKeeper
    {
        if (_repo.regFile(snOfDoc, body)) 
            emit UpdateStateOfFile(body, uint8(FilesRepo.StateOfFile.Created));
    }

    function circulateFile(
        address body,
        uint16 signingDays,
        uint16 closingDays,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) external onlyDirectKeeper {
        _repo.circulateFile(body, signingDays, closingDays, vr, docUrl, docHash);
        emit UpdateStateOfFile(body, uint8(FilesRepo.StateOfFile.Circulated));
    }

    function establishFile(
        address body
    ) external onlyDirectKeeper {
        _repo.establishFile(body);
        emit UpdateStateOfFile(body, uint8(FilesRepo.StateOfFile.Established));
    }

    function proposeFile(
        address body,
        RulesParser.VotingRule memory vr
    ) external onlyKeeper {
        _repo.proposeFile(body, vr);
        emit UpdateStateOfFile(body, uint8(FilesRepo.StateOfFile.Proposed));
    }

    function voteCountingForFile(
        address body,
        bool approved
    ) external onlyKeeper {
        _repo.voteCountingForFile(body, approved);
        emit UpdateStateOfFile(body, approved ? 
                uint8(FilesRepo.StateOfFile.Approved) : 
                uint8(FilesRepo.StateOfFile.Rejected));
    }

    function execFile(
        address body
    ) public onlyDirectKeeper {
        _repo.execFile(body);
        emit UpdateStateOfFile(body, uint8(FilesRepo.StateOfFile.Executed));
    }

    function revokeFile(
        address body
    ) public onlyDirectKeeper {
        _repo.revokeFile(body);
        emit UpdateStateOfFile(body, uint8(FilesRepo.StateOfFile.Revoked));
    }

    function setStateOfFile(address body, uint state) public onlyKeeper {
        _repo.setStateOfFile(body, state);
        emit UpdateStateOfFile(body, state);
    }

    //##################
    //##   read I/O   ##
    //##################

    function isRegistered(address body) external view returns (bool) {
        return _repo.isRegistered(body);
    }

    function qtyOfFiles() external view returns (uint256) {
        return _repo.qtyOfFiles();
    }

    function getFilesList() external view returns (address[] memory) {
        return _repo.getFilesList();
    }

    function getSNOfFile(address body)
        external view returns (bytes32)
    {
        return _repo.getSNOfFile(body);
    }

    function getHeadOfFile(address body)
        public view returns (FilesRepo.Head memory head)
    {
        head = _repo.getHeadOfFile(body);
    }

    function getRefOfFile(address body)
        external view returns (FilesRepo.Ref memory ref) 
    {
        ref = _repo.getRefOfFile(body);
    }

}
