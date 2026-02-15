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

import "./IBookOfDocs.sol";
import "./BookOfUsers.sol";
import "../../openzeppelin/utils/Address.sol";

contract BookOfDocs is IBookOfDocs, BookOfUsers {
    using DocsRepo for DocsRepo.Repo;
    using DocsRepo for DocsRepo.Head;
    using Address for address;
    
    DocsRepo.Repo private _docs;

    // ==== UUPSUpgradable ====

    uint[50] private __gap;

    function upgradeCenterTo(address newImplementation) external onlyProxy {
        upgradeTo(newImplementation);
        DocsRepo.Doc memory doc = _docs.upgradeDoc(newImplementation, address(this));
        emit UpgradeDoc(doc.head.codifyHead(), doc.body);
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    // ########################
    // ##    Error & Event   ##
    // ########################

    error BOD_NotProxyable();

    error BOD_MsgSenderNotRegistered();

    modifier proxyable(uint typeOfDoc) {
        if (
            (typeOfDoc == DocsRepo.getTypeByName("RegCenter") ||
            typeOfDoc == DocsRepo.getTypeByName("CreateNewComp") ||
            typeOfDoc == DocsRepo.getTypeByName("UsdFuelTank") || 
            typeOfDoc == DocsRepo.getTypeByName("CashLockers") ||
            typeOfDoc == DocsRepo.getTypeByName("MockUSDC")) &&
            msg.sender != getBookeeper()
        ) revert BOD_NotProxyable();
        _;
    }

    // ###############
    // ##    Docs   ##
    // ###############

    function setTemplate(
        uint typeOfDoc, address body, uint author
     ) external onlyKeeper {
        DocsRepo.Head memory head = 
            _docs.setTemplate(
                typeOfDoc, 
                body, 
                author, 
                _getUserNo(msg.sender)
            );

        emit SetTemplate(head.typeOfDoc, head.version, body);
    }

    function regProxy(
        address temp,
        address proxy
    ) external onlyKeeper {
        DocsRepo.Doc memory doc = _docs.regProxy(
                temp,
                proxy,
                _getUserNo(msg.sender)
        );

        emit RegProxy(doc.head.codifyHead(), proxy);
    }

    function transferIPR(
        uint typeOfDoc, 
        uint version, 
        uint transferee
    ) external {
        _docs.transferIPR(
            typeOfDoc, 
            version, 
            transferee, 
            _getUserNo(msg.sender)
        );
        emit TransferIPR(typeOfDoc, version, transferee);
    }

    function _getCreator(address msgSender) private view returns(uint creator) {
        if (msgSender.isContract()) {
            if (!_docs.docExist(msgSender)) 
                revert BOD_MsgSenderNotRegistered();
            creator = _docs.getHeadByBody(msgSender).creator;
        } else {
            creator = _getUserNo(msgSender);
        }
    }

    function cloneDoc(
        uint typeOfDoc,
        uint version
    ) external proxyable(typeOfDoc) returns(
        DocsRepo.Doc memory doc
    ) {
        doc = _docs.cloneDoc(
            typeOfDoc, 
            version, 
            _getCreator(msg.sender)
        );
        IOwnable(doc.body).initialize(msg.sender, address(this));
        emit CloneDoc(doc.head.codifyHead(), doc.body);
    }

    function proxyDoc(
        uint typeOfDoc,
        uint version
    ) external proxyable(typeOfDoc) returns(
        DocsRepo.Doc memory doc
    ) {
        doc = _docs.proxyDoc(
            typeOfDoc, 
            version,
            _getCreator(msg.sender)
        );
        emit ProxyDoc(doc.head.codifyHead(), doc.body);
    }

    function upgradeDoc(address temp) external {
        DocsRepo.Doc memory doc = _docs.upgradeDoc(temp, msg.sender);
        emit UpgradeDoc(doc.head.codifyHead(), doc.body);
    }

    // ##################
    // ##  Read I/O    ##
    // ##################

    // ---- Type of Doc ----

    function counterOfTypes() external view returns(uint32) {
        return _docs.counterOfTypes();
    }

    function typeExist(uint256 typeOfDoc) external view returns(bool) {
        return _docs.typeExist(uint32(typeOfDoc));
    }

    function getTypesList() external view returns(uint[] memory) {
        return _docs.getTypesList();
    }

    // ---- Counters ----

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32) {
        return _docs.counterOfVersions(uint32(typeOfDoc));
    }

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64) {
        return _docs.counterOfDocs(uint32(typeOfDoc), uint32(version));
    }

    // ---- Authors ----

    function getAuthor(uint typeOfDoc, uint version) external view returns(uint40) {
        return _docs.getAuthor(typeOfDoc, version);
    }

    function getAuthorByBody(address body) external view returns(uint40) {
        return _docs.getAuthorByBody(body);
    }

    // ---- Temps ----

    function tempExist(address body) external view returns(bool) {
        return _docs.tempExist(body);
    }

    function getTemp(uint typeOfDoc, uint version) external view returns(DocsRepo.Doc memory doc) {
        doc = _docs.getTemp(typeOfDoc, version);
    }

    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getVersionsList(uint32(typeOfDoc));
    }

    // ---- Docs ----

    function docExist(address body) public view returns(bool) {
        return _docs.docExist(body);
    }

    function getHeadByBody(address body) external view returns (DocsRepo.Head memory ) {
        return _docs.getHeadByBody(body);
    }

    function getDoc(
        uint typeOfDoc, uint version, uint seqOfDoc
    ) external view returns(DocsRepo.Doc memory doc) {
        doc = _docs.getDoc(typeOfDoc, version, seqOfDoc);
    }

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc) {
        if (isUserNo(acct)) {
            doc.body = _getUserByNo(acct).primeKey.pubKey;
            if (_docs.docExist(doc.body)) doc.head = _docs.heads[doc.body];
            else doc.body = address(0);
        }
    }

    function getDocsList(uint typeOfDoc, uint version) external view returns(DocsRepo.Doc[] memory) {
        return _docs.getDocsList(typeOfDoc, version);
    } 

    function verifyDoc(
        uint typeOfDoc, uint version, uint seqOfDoc
    ) external view returns(bool flag) {
        flag = _docs.verifyDoc(typeOfDoc, version, seqOfDoc);
    }
}
