// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRepoOfDocs.sol";

import "../lib/EnumerableSet.sol";
import "../lib/RulesParser.sol";

import "../access/AccessControl.sol";
import "../components/ISigPage.sol";
// import "../ruting/ISigPageSetting.sol";
import "../utils/CloneFactory.sol";

contract RepoOfDocs is IRepoOfDocs, CloneFactory, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using RulesParser for uint256;

    // typeOfDoc => address // 0-SigPage ;
    mapping(uint256 => address) private _templates;
    EnumerableSet.UintSet private _tempsList;

    // addrOfBody => Doc
    mapping(address => Doc) private _docs;
    EnumerableSet.AddressSet private _docsList;

    //####################
    //##    modifier    ##
    //####################

    modifier tempReady(uint256 typeOfDoc) {
        require(_tempsList.contains(typeOfDoc), 
            "ROD.md.TR: template NOT set");
        _;
    }

    modifier onlyRegistered(address body) {
        require(
            _docsList.contains(body),
            "ROD.md.OR: doc NOT registered"
        );
        _;
    }

    modifier onlyForPending(address body) {
        require(
            _docs[body].head.state == uint8(RODStates.Created),
            "ROD.md.OFP: Doc not pending"
        );
        _;
    }

    modifier onlyForCirculated(address body) {
        require(
            _docs[body].head.state == uint8(RODStates.Circulated),
            "ROD.md.OFC: Doc not Circulated"
        );
        _;
    }

    //##################
    //##    写接口     ##
    //##################

    function setTemplate(address body, uint256 typeOfDoc) 
        external 
        onlyDirectKeeper 
    {
        emit SetTemplate(body, typeOfDoc);
        _templates[typeOfDoc] = body;
        _tempsList.add(typeOfDoc);
    }

    function createDoc(uint256 typeOfDoc, uint256 creator)
        public
        onlyDirectKeeper
        tempReady(typeOfDoc)
        tempReady(uint8(TypeOfDoc.SigPage))
        returns (address body)
    {
        address temp = createClone(_templates[typeOfDoc]);

        if (_docsList.add(temp)) {
            body = temp;

            emit UpdateStateOfDoc(body, uint8(RODStates.Created));

            _docs[body].head = Head({
                typeOfDoc: uint8(typeOfDoc),
                creator: uint40(creator),
                createDate: uint48(block.timestamp),
                shaExecDeadline: 0,
                proposeDeadline: 0,
                state: uint8(RODStates.Created)
            });

            // sigPage = createClone(_templates[uint8(TypeOfDoc.SigPage)]);

            // _docs[body].sigPage = sigPage;
        }
    }

    function removeDoc(address body) 
        external 
        onlyDirectKeeper 
        onlyForPending(body) 
    {
        if (_docsList.remove(body)) {
            emit RemoveDoc(body);
            delete _docs[body];
        }
    }

    function circulateDoc(
        address body,
        RulesParser.VotingRule memory vr,
        bytes32 docUrl,
        bytes32 docHash
    ) public onlyDirectKeeper onlyForPending(body) {

        emit UpdateStateOfDoc(body, uint8(RODStates.Circulated));

        Doc storage doc = _docs[body];

        // uint48 execDays = rule.shaExecDaysOfVR();
        // uint48 reviewDays = rule.reviewDaysOfVR();

        doc.head.shaExecDeadline =
            uint48(block.timestamp) +
            uint48(vr.shaExecDays) * 86400;

        doc.head.proposeDeadline =
            doc.head.shaExecDeadline +
            uint48(vr.reviewDays) * 86400;

        doc.docUrl = docUrl;
        doc.docHash = docHash;

        doc.head.state = uint8(RODStates.Circulated);
    }

    function setStateOfDoc(address body, uint8 state) public onlyRegistered(body) onlyKeeper {
        emit UpdateStateOfDoc(body, state);
        _docs[body].head.state = state;
    }

    //##################
    //##   read I/O   ##
    //##################

    function template(uint256 typeOfDoc) external view returns (address) {
        return _templates[typeOfDoc];
    }

    function tempsList() external view returns (uint256[] memory) {
        return _tempsList.values();
    }

    function tempReadyFor(uint256 typeOfDoc) public view returns (bool) {
        return _tempsList.contains(typeOfDoc);
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
        public
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

    // function sigPageOfDoc(address body)
    //     external
    //     view
    //     onlyRegistered(body)
    //     returns (ISigPage sigPage)
    // {
    //     sigPage = ISigPage(_docs[body].sigPage);
    // }

}
