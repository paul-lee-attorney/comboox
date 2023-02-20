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
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SigsRepo for SigsRepo.Page;
    using SNParser for bytes32;

    // docType => address
    mapping(uint256 => address) private _templates;

    // addrOfBody => Doc
    mapping(address => Doc) private _docs;

    EnumerableSet.AddressSet private _docsList;

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady(uint8 typeOfDoc) {
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

    function setTemplate(address body, uint8 typeOfDoc) external onlyDirectKeeper {
        _templates[typeOfDoc] = body;
        emit SetTemplate(body, typeOfDoc);
    }

    function createDoc(uint8 docType, uint40 creator)
        public
        onlyDirectKeeper
        tempReady(docType)
        returns (address body)
    {
        address temp = createClone(_templates[docType]);

        if (_docsList.add(temp)) {
            body = temp;

            emit UpdateStateOfDoc(body, uint8(RODStates.Created));

            _docs[body].head = Head({
                docType: docType,
                creator: creator,
                createDate: uint48(block.timestamp),
                shaExecDeadline: 0,
                proposeDeadline: 0,
                state: uint8(RODStates.Created)
            });
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
        _docs[msg.sender].sigPage.addBlank(seq, acct);
    }

    function removeBlank(uint40 acct, uint16 seq)
        external onlyRegistered(msg.sender)
    {
        _docs[msg.sender].sigPage.removeBlank(seq, acct);
    }

    // ==== Execution ====

    function signDeal(address body, uint16 seq, uint40 caller, bytes32 sigHash)
        public onlyForCirculated(body) onlyDirectKeeper
    {
        _docs[msg.sender].sigPage.signDeal(seq, caller, sigHash);
    }

    function signDoc(address body, uint40 caller, bytes32 sigHash)
        external
        onlyDirectKeeper
        onlyForCirculated(body)
    {
        signDeal(body, 0, caller, sigHash);
    }

    function acceptDoc(address body, uint40 caller, bytes32 sigHash) 
        external 
        onlyDirectKeeper
    {
        require(_docs[body].sigPage.established(),
            "SP.AD: Doc not established");
        
        signDeal(body, 0, caller, sigHash);
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

    function qtyOfDocs() external view returns (uint256) {
        return _docsList.length();
    }

    function docsList() external view returns (address[] memory) {
        return _docsList.values();
    }

    function getHeadOfDoc(address body)
        external
        view
        onlyRegistered(body)
        returns (Head memory head)
    {
        head = _docs[body].head;
    }

    function getRefOfDoc(address body)
        external
        view
        onlyRegistered(body)
        returns (bytes32 docUrl, bytes32 docHash) 
    {
        docUrl = _docs[body].docUrl;
        docHash = _docs[body].docHash;
    }

    // ==== SigPage ====

    function established(address body) external view onlyRegistered(body)
        returns (bool) 
    {
        return _docs[body].sigPage.established();
    }

    function parasOfPage(address body) 
        external 
        view 
        onlyRegistered(body) 
        returns (SigsRepo.Signature memory) 
    {
        return _docs[body].sigPage.parasOfPage();
    }

    function sigDeadline(address body)
        external
        view
        onlyRegistered(body)
        returns (uint48)
    {
        return _docs[body].sigPage.signatures[0].sigDate;
    }

    function closingDeadline(address body)
        external
        view
        onlyRegistered(body)
        returns (uint48)
    {
        return uint48(_docs[body].sigPage.signatures[0].blocknumber);
    }

    function isParty(address body, uint40 acct)
        external
        view
        onlyRegistered(body)
        returns(bool)
    {
        return _docs[body].sigPage.parties.contains(acct);
    }

    function isInitSigner(address body, uint40 acct) 
        external 
        view 
        onlyRegistered(body)
        returns (bool) 
    {
        return _docs[body].sigPage.signatures[acct].signer == acct;
    }

    function qtyOfParties(address body)
        external
        view
        onlyRegistered(body)
        returns (uint256)
    {
        return _docs[body].sigPage.parties.length();
    }

    function partiesOfDoc(address body)
        external
        view
        onlyRegistered(body)
        returns (uint40[] memory)
    {
        return _docs[body].sigPage.parties.valuesToUint40();
    }

    function sigOfDeal(address body, uint16 seq, uint40 acct) 
        external
        view
        onlyRegistered(body)
        returns (SigsRepo.Signature memory)
    {
        return _docs[body].sigPage.sigOfDeal(seq, acct);
    }

    function sigOfDoc(address body, uint40 acct) 
        external
        view
        onlyRegistered(body)
        returns (SigsRepo.Signature memory)
    {
        return _docs[body].sigPage.sigOfDeal(0, acct);
    }
}
