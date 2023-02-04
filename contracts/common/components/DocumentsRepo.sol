// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IDocumentsRepo.sol";

import "../lib/SNParser.sol";
import "../lib/EnumerableSet.sol";

import "../access/AccessControl.sol";

import "../utils/CloneFactory.sol";

contract DocumentsRepo is IDocumentsRepo, CloneFactory, AccessControl {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum BODStates {
        ZeroPoint,
        Created,
        Circulated,
        Established,
        Proposed,
        Voted,
        Executed,
        Revoked
    }

    struct Doc {
        uint8 docType;
        uint40 creator;
        uint48 createDate;
        uint64 shaExecDeadlineBN;
        uint64 proposeDeadlineBN;
        uint8 state;
        bytes32 docHash;
    }

    // docType => address
    mapping(uint256 => address) private _templates;

    // addrOfBody => Doc
    mapping(address => Doc) private _docs;

    EnumerableSet.AddressSet private _docsList;

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady(uint8 typeOfDoc) {
        require(_templates[typeOfDoc] != address(0), "template NOT set");
        _;
    }

    modifier onlyRegistered(address body) {
        require(
            _docsList.contains(body),
            "DR.md.onlyRegistered: doc NOT registered"
        );
        _;
    }

    modifier onlyForPending(address body) {
        require(
            _docs[body].state == uint8(BODStates.Created),
            "state of doc is not Created"
        );
        _;
    }

    modifier onlyForCirculated(address body) {
        require(
            _docs[body].state == uint8(BODStates.Circulated),
            "state of doc is not Circulated"
        );
        _;
    }

    //##################
    //##    写接口    ##
    //##################

    function setTemplate(address body, uint8 typeOfDoc) external onlyDK {
        _templates[typeOfDoc] = body;
        emit SetTemplate(body, typeOfDoc);
    }

    function createDoc(uint8 docType, uint40 creator)
        public
        onlyDK
        tempReady(docType)
        returns (address body)
    {
        address temp = createClone(_templates[docType]);

        if (_docsList.add(temp)) {
            body = temp;

            Doc storage doc = _docs[body];

            doc.docType = docType;
            doc.creator = creator;
            doc.createDate = uint48(block.timestamp);
            doc.state = uint8(BODStates.Created);

            emit UpdateStateOfDoc(body, doc.state);
        }
    }

    function removeDoc(address body) external onlyDK onlyForPending(body) {
        if (_docsList.remove(body)) {
            delete _docs[body];
            emit RemoveDoc(body);
        }
    }

    function circulateDoc(
        address body,
        bytes32 rule,
        bytes32 docHash
    ) public onlyDK onlyRegistered(body) onlyForPending(body) {
        Doc storage doc = _docs[body];

        uint64 execDays = rule.shaExecDaysOfVR();
        uint64 reviewDays = rule.reviewDaysOfVR();

        doc.shaExecDeadlineBN =
            uint64(block.number) +
            execDays *
            24 *
            _rc.blocksPerHour();

        doc.proposeDeadlineBN =
            doc.shaExecDeadlineBN +
            reviewDays *
            24 *
            _rc.blocksPerHour();

        doc.docHash = docHash;

        doc.state = uint8(BODStates.Circulated);

        emit UpdateStateOfDoc(body, doc.state);
    }

    function pushToNextState(address body) public onlyRegistered(body) {
        require(
            _gk.isKeeper(uint8(TitleOfKeepers.BOAKeeper), msg.sender) ||
                _gk.isKeeper(uint8(TitleOfKeepers.BOHKeeper), msg.sender) ||
                _gk.isKeeper(uint8(TitleOfKeepers.BOMKeeper), msg.sender),
            "DR.pushToNextState: not have access right"
        );

        _docs[body].state++;

        emit UpdateStateOfDoc(body, _docs[body].state);
    }

    //##################
    //##   read I/O   ##
    //##################

    function template(uint8 typeOfDoc) external view returns (address) {
        return _templates[typeOfDoc];
    }

    function isRegistered(address body) external view returns (bool) {
        return _docsList.contains(body);
    }

    function passedExecPeriod(address body)
        external
        view
        onlyRegistered(body)
        returns (bool)
    {
        Doc storage doc = _docs[body];

        if (doc.state < uint8(BODStates.Established)) return false;
        else if (doc.state > uint8(BODStates.Established)) return true;
        else if (doc.shaExecDeadlineBN > block.number) return false;
        else return true;
    }

    function isCirculated(address body)
        external
        view
        onlyRegistered(body)
        returns (bool)
    {
        return _docs[body].state >= uint8(BODStates.Circulated);
    }

    function qtyOfDocs() external view returns (uint256) {
        return _docsList.length();
    }

    function docsList() external view returns (address[] memory) {
        return _docsList.values();
    }

    function getDoc(address body)
        external
        view
        onlyRegistered(body)
        returns (
            uint8 docType,
            uint40 creator,
            uint48 createDate,
            bytes32 docHash
        )
    {
        Doc storage doc = _docs[body];

        docType = doc.docType;
        creator = doc.creator;
        createDate = doc.createDate;
        docHash = doc.docHash;
    }

    function currentState(address body)
        external
        view
        onlyRegistered(body)
        returns (uint8)
    {
        return _docs[body].state;
    }

    function shaExecDeadlineBNOf(address body)
        external
        view
        onlyRegistered(body)
        returns (uint64)
    {
        return _docs[body].shaExecDeadlineBN;
    }

    function proposeDeadlineBNOf(address body)
        external
        view
        onlyRegistered(body)
        returns (uint64)
    {
        return _docs[body].proposeDeadlineBN;
    }
}
