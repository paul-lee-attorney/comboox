// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRepoOfDocs.sol";

import "../lib/EnumerableSet.sol";
import "../lib/SigsRepo.sol";
import "../lib/SNParser.sol";

import "../access/AccessControl.sol";

import "../utils/CloneFactory.sol";

contract RepoOfDocs is IRepoOfDocs, CloneFactory, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SigsRepo for SigsRepo.Page;
    using SNParser for bytes32;

    enum RODStates {
        ZeroPoint,
        Created,
        Circulated,
        Established,
        Proposed,
        Voted,
        Executed,
        Revoked
    }

    struct Head {
        uint8 docType;
        uint40 creator;
        uint48 createDate;
        uint48 shaExecDeadline;
        uint48 proposeDeadline;
        uint8 state;
    }

    struct Doc {
        Head head;
        bytes32 docUrl;
        bytes32 docHash;
        SigsRepo.Page sigPage;
    }

    // docType => address
    mapping(uint256 => address) private _templates;

    // addrOfBody => Doc
    mapping(address => Doc) private _docs;

    EnumerableSet.AddressSet private _docsList;

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady(uint256 typeOfDoc) {
        require(_templates[typeOfDoc] != address(0), "ROD.md.tr: template NOT set");
        _;
    }

    modifier onlyRegistered(address body) {
        require(
            _docsList.contains(body),
            "ROD.md.or: doc NOT registered"
        );
        _;
    }

    modifier onlyForPending(address body) {
        require(
            _docs[body].head.state == uint8(RODStates.Created),
            "ROD.md.ofp: doc not pending"
        );
        _;
    }

    modifier onlyForCirculated(address body) {
        require(
            _docs[body].head.state == uint8(RODStates.Circulated),
            "ROD.md.ofc: Doc not Circulated"
        );
        _;
    }

    //##################
    //##    写接口     ##
    //##################

    function setTemplate(address body, uint256 typeOfDoc) external onlyDirectKeeper {
        _templates[typeOfDoc] = body;
        emit SetTemplate(body, typeOfDoc);
    }

    function createDoc(uint256 docType, uint256 creator)
        public
        onlyDirectKeeper
        tempReady(docType)
        returns (address body)
    {
        address temp = createClone(_templates[docType]);

        if (_docsList.add(temp)) {
            body = temp;

            emit UpdateStateOfDoc(body, uint8(RODStates.Created));

            // Head storage head = _docs[body].docHead;

            _docs[body].head = Head({
                docType: uint8(docType),
                creator: uint40(creator),
                createDate: uint48(block.timestamp),
                shaExecDeadline: 0,
                proposeDeadline: 0,
                state: uint8(RODStates.Created)
            });

            // doc.docType = docType;
            // doc.creator = creator;
            // doc.createDate = uint48(block.timestamp);
            // doc.state = uint8(RODStates.Created);
        }
    }

    function removeDoc(address body) external onlyDirectKeeper onlyForPending(body) {
        if (_docsList.remove(body)) {
            emit RemoveDoc(body);
            delete _docs[body];
        }
    }

    function circulateDoc(
        address body,
        bytes32 rule,
        bytes32 docUrl,
        bytes32 docHash
    ) public onlyDirectKeeper onlyForPending(body) {

        emit UpdateStateOfDoc(body, uint8(RODStates.Circulated));

        Doc storage doc = _docs[body];

        uint48 execDays = rule.shaExecDaysOfVR();
        uint48 reviewDays = rule.reviewDaysOfVR();

        doc.head.shaExecDeadline =
            uint48(block.timestamp) +
            execDays * 86400;

        doc.head.proposeDeadline =
            doc.head.shaExecDeadline +
            reviewDays * 86400;

        doc.docUrl = docUrl;
        doc.docHash = docHash;

        doc.head.state = uint8(RODStates.Circulated);
    }

    function pushToNextState(address body) public onlyRegistered(body) onlyKeeper {
        emit UpdateStateOfDoc(body, _docs[body].head.state + 1);
        _docs[body].head.state++;
    }

    // ==== Drafting ====
    
    function setSigDeadline(uint48 deadline) 
        external onlyRegistered(msg.sender) 
    {
        _docs[msg.sender].sigPage.setSigDeadline(deadline);
    }

    function setClosingDeadline(uint48 deadline) 
        external onlyRegistered(msg.sender) 
    {
        _docs[msg.sender].sigPage.setClosingDeadline(deadline);
    }

    function addBlank(uint40 acct, uint16 seq)
        external onlyRegistered(msg.sender) 
    {
        _docs[msg.sender].sigPage.addBlank(acct, seq);
    }

    function removeBlank(uint40 acct, uint16 seq)
        external onlyRegistered(msg.sender)
    {
        _docs[msg.sender].sigPage.removeBlank(acct, seq);
    }

    // ==== Execution ====

    function signDeal(address body, uint40 caller, uint16 seq, bytes32 sigHash)
        public onlyForCirculated(body) onlyDirectKeeper
    {
        _docs[msg.sender].sigPage.signDeal(caller, seq, sigHash);
    }

    function signDoc(address body, uint40 caller, bytes32 sigHash)
        external
        onlyDirectKeeper
        onlyForCirculated(body)
    {
        signDeal(body, caller, 0, sigHash);
    }

    function acceptDoc(address body, bytes32 sigHash, uint40 caller) 
        external 
        onlyDirectKeeper
        onlyForCirculated(body)
    {
        require(_docs[body].sigPage.established(), "SP.acceptDoc: Doc not established");
        signDeal(body, caller, 0, sigHash);
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

        if (doc.head.state < uint8(RODStates.Established)) return false;
        else if (doc.head.state > uint8(RODStates.Established)) return true;
        else if (doc.head.shaExecDeadline > block.timestamp) return false;
        else return true;
    }

    function isCirculated(address body)
        external
        view
        onlyRegistered(body)
        returns (bool)
    {
        return _docs[body].head.state >= uint8(RODStates.Circulated);
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
            bytes32 docUrl,
            bytes32 docHash
        )
    {
        Doc storage doc = _docs[body];

        docType = doc.head.docType;
        creator = doc.head.creator;
        createDate = doc.head.createDate;
        docUrl = doc.docUrl;
        docHash = doc.docHash;
    }

    function currentState(address body)
        external
        view
        onlyRegistered(body)
        returns (uint8)
    {
        return _docs[body].head.state;
    }

    function shaExecDeadlineOf(address body)
        external
        view
        onlyRegistered(body)
        returns (uint48)
    {
        return _docs[body].head.shaExecDeadline;
    }

    function proposeDeadlineOf(address body)
        external
        view
        onlyRegistered(body)
        returns (uint48)
    {
        return _docs[body].head.proposeDeadline;
    }

    // ==== SigPage ====

    function established(address body) 
        external 
        view 
        onlyRegistered(body)
        returns (bool) 
    {
        return _docs[body].sigPage.established();
    }

    function sigDeadline(address body) 
        external 
        view 
        onlyRegistered(body) 
        returns (uint48) 
    {
        return _docs[body].sigPage.sigDeadline();
    }

    function closingDeadline(address body) 
        external 
        view 
        onlyRegistered(body)
        returns(uint48) 
    {
        return _docs[body].sigPage.closingDeadline();
    }

    function isParty(address body, uint40 acct)
        external
        view
        onlyRegistered(body)
        returns(bool)
    {
        return _docs[body].sigPage.isParty(acct);
    }

    function isInitSigner(address body, uint40 acct) 
        external 
        view 
        onlyRegistered(body)
        returns (bool) 
    {
        return _docs[body].sigPage.isInitSigner(acct);
    }

    function partiesOfDoc(address body) 
        external 
        view 
        onlyRegistered(body)
        returns (uint40[] memory) 
    {
        return _docs[body].sigPage.partiesOfDoc();
    }

    function qtyOfParties(address body) 
        external 
        view 
        onlyRegistered(body)
        returns (uint256) 
    {
        return _docs[body].sigPage.qtyOfParties();
    }

    function blankCounter(address body) 
        external 
        view 
        onlyRegistered(body)
        returns (uint16) 
    {
        return _docs[body].sigPage.blankCounterOfDoc();
    }

    function sigCounter(address body) 
        external 
        view 
        onlyRegistered(body)
        returns (uint16) 
    {
        return _docs[body].sigPage.sigCounter();
    }

    function sigOfDeal(address body, uint40 acct, uint16 ssn) 
        external
        view
        onlyRegistered(body)
        returns (
            uint64 blocknumber,
            uint48 sigDate,
            bytes32 sigHash
        )
    {
        return _docs[body].sigPage.sigOfDeal(acct, ssn);
    }

    function sigOfDoc(address body, uint40 acct) 
        external
        view
        onlyRegistered(body)
        returns (
            uint64 blocknumber,
            uint48 sigDate,
            bytes32 sigHash
        )
    {
        return _docs[body].sigPage.sigOfDeal(acct, 0);
    }
}
