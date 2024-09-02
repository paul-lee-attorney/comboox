// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

pragma solidity ^0.8.8;

import "./IBookOfDocs.sol";

import "../access/IOwnable.sol";

import "./BookOfPoints.sol";

contract BookOfDocs is IBookOfDocs, BookOfPoints {
    using DocsRepo for DocsRepo.Repo;
    using DocsRepo for DocsRepo.Head;
    
    DocsRepo.Repo private _docs;
    
    constructor(address keeper) BookOfPoints(keeper) {}

    // ###############
    // ##    Docs   ##
    // ###############

    function setTemplate(
        uint typeOfDoc, address body, uint author
     ) external onlyKeeper {
        DocsRepo.Head memory head = 
            _docs.setTemplate(typeOfDoc, body, author, getMyUserNo());

        emit SetTemplate(head.typeOfDoc, head.version, body);
    }

    function transferIPR(uint typeOfDoc, uint version, uint transferee) external {
        _docs.transferIPR(typeOfDoc, version, transferee, getMyUserNo());

        emit TransferIPR(typeOfDoc, version, transferee);
    }

    function createDoc(bytes32 snOfDoc,address primeKeyOfOwner) external returns(
        DocsRepo.Doc memory doc
    ) {
        doc = _docs.createDoc(snOfDoc, msg.sender);
        IOwnable(doc.body).init(primeKeyOfOwner, address(this));
        
        emit CreateDoc(doc.head.codifyHead(), doc.body);
    }

    // ##################
    // ##  Read I/O    ##
    // ##################


    function counterOfTypes() external view returns(uint32) {
        return _docs.counterOfTypes();
    }

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32) {
        return _docs.counterOfVersions(uint32(typeOfDoc));
    }

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64) {
        return _docs.counterOfDocs(uint32(typeOfDoc), uint32(version));
    }

    function docExist(address body) public view returns(bool) {
        return _docs.docExist(body);
    }

    function getAuthor(uint typeOfDoc, uint version) external view returns(uint40) {
        return _docs.getAuthor(typeOfDoc, version);
    }

    function getAuthorByBody(address body) external view returns(uint40) {
        return _docs.getAuthorByBody(body);
    }

    function getHeadByBody(address body) public view returns (DocsRepo.Head memory ) {
        return _docs.getHeadByBody(body);
    }

    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc) {
        doc = _docs.getDoc(snOfDoc);
    }

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc) {
        if (counterOfUsers() >= acct) { 
            doc.body = _getUserByNo(acct).primeKey.pubKey;
            if (_docs.docExist(doc.body)) doc.head = _docs.heads[doc.body];
            else doc.body = address(0);
        }
    }

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag) {
        flag = _docs.verifyDoc(snOfDoc);
    }

    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getVersionsList(uint32(typeOfDoc));
    }

    function getDocsList(bytes32 snOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getDocsList(snOfDoc);
    } 
}
