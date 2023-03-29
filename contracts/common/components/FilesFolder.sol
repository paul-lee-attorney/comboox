// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IFilesFolder.sol";

import "../access/AccessControl.sol";

contract FilesFolder is IFilesFolder, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    Folder private _folder;

    //####################
    //##    modifier    ##
    //####################

    modifier onlyRegistered(address body) {
        require(
            _folder.filesList.contains(body),
            "ROD.md.OR: doc NOT registered"
        );
        _;
    }

    modifier onlyForPending(address body) {
        require(
            _folder.files[body].head.state == uint8(StateOfFile.Created),
            "ROD.md.OFP: Doc not pending"
        );
        _;
    }

    modifier onlyForCirculated(address body) {
        require(
            _folder.files[body].head.state == uint8(StateOfFile.Circulated),
            "ROD.md.OFC: Doc not Circulated"
        );
        _;
    }

    //##################
    //##    写接口     ##
    //##################

    function createDoc(uint16 typeOfDoc, uint16 version, uint40 creator)
        public
        onlyDirectKeeper
        returns (address body)
    {
        uint256 snOfDoc;

        (snOfDoc, body) = _rc.createDoc(typeOfDoc, version, creator);

        if (_folder.filesList.add(body)) {
            emit UpdateStateOfFile(body, uint8(StateOfFile.Created));

            File storage file = _folder.files[body];
            
            file.head.snOfDoc = snOfDoc;
            file.head.state = uint8(StateOfFile.Created);
        }
    }

    function circulateDoc(
        address body,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) public onlyDirectKeeper onlyForPending(body) {

        emit UpdateStateOfFile(body, uint8(StateOfFile.Circulated));

        File storage file = _folder.files[body];

        file.head.shaExecDeadline =
            uint48(block.timestamp) +
            uint48(vr.shaExecDays) * 86400;

        file.head.proposeDeadline =
            file.head.shaExecDeadline +
            uint48(vr.reviewDays) * 86400;

        file.head.state = uint8(StateOfFile.Circulated);

        if (docUrl != bytes32(0) || docHash != bytes32(0)){
            file.ref.docUrl = docUrl;
            file.ref.docHash = docHash;            
        }
    }

    function setStateOfFile(address body, uint8 state) public onlyRegistered(body) onlyKeeper {
        emit UpdateStateOfFile(body, state);
        _folder.files[body].head.state = state;
    }

    //##################
    //##   read I/O   ##
    //##################

    function isRegistered(address body) external view returns (bool) {
        return _folder.filesList.contains(body);
    }

    function qtyOfFiles() external view returns (uint256) {
        return _folder.filesList.length();
    }

    function filesList() external view returns (address[] memory) {
        return _folder.filesList.values();
    }

    function getHeadOfFile(address body)
        public
        view
        onlyRegistered(body)
        returns (Head memory head)
    {
        head = _folder.files[body].head;
    }

    function getRefOfFile(address body)
        external
        view
        onlyRegistered(body)
        returns (Ref memory ref) 
    {
        ref = _folder.files[body].ref;
    }

}
