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

/// @title IBookOfDocs
/// @notice Document registry interface for templates, proxies, and clones.
/// @dev Exposes write operations for registration/upgrade and read operations for queries.

import "../../lib/books/DocsRepo.sol";

interface IBookOfDocs {

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Docs ====
    
    /// @notice Emitted when a template is registered.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param body Template address.
    event SetTemplate(uint256 indexed typeOfDoc, uint256 indexed version, address indexed body);

    /// @notice Emitted when a proxy is registered.
    /// @param snOfDoc Encoded document header.
    /// @param body Proxy address.
    event RegProxy(bytes32 indexed snOfDoc, address indexed body);

    /// @notice Emitted when IPR is transferred.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param transferee New author userNo.
    event TransferIPR(uint indexed typeOfDoc, uint indexed version, uint indexed transferee);

    /// @notice Emitted when a clone is created.
    /// @param snOfDoc Encoded document header.
    /// @param body Clone address.
    event CloneDoc(bytes32 indexed snOfDoc, address indexed body);

    /// @notice Emitted when a proxy is created.
    /// @param snOfDoc Encoded document header.
    /// @param body Proxy address.
    event ProxyDoc(bytes32 indexed snOfDoc, address indexed body);

    /// @notice Emitted when a proxy is upgraded and registered.
    /// @param snOfDoc Encoded document header.
    /// @param body Proxy address.
    event UpgradeDoc(bytes32 indexed snOfDoc, address indexed body);

    // ##################
    // ##    Write     ##
    // ##################

    /// @notice Register a template contract for a document type.
    /// @param typeOfDoc Document type (must be > 0 in implementation).
    /// @param body Template contract address (non-zero).
    /// @param author Author userNo (must be > 0).
    function setTemplate(
        uint typeOfDoc, address body, uint author
     ) external;

    /// @notice Register an externally created proxy.
    /// @param temp Template implementation address.
    /// @param proxy Proxy address.
    function regProxy(
        address temp,
        address proxy
    ) external;

    /// @notice Transfer IPR to a new author.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param transferee New author userNo.
    function transferIPR(
        uint typeOfDoc, 
        uint version, 
        uint transferee
    ) external;

    /// @notice Create and register an EIP-1167 clone from a template.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @return doc Registered document instance.
    function cloneDoc(
        uint typeOfDoc,
        uint version
    ) external returns(
        DocsRepo.Doc memory doc
    );

    /// @notice Create and register an ERC1967 proxy initialized via `initialize`.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @return doc Registered document instance.
    function proxyDoc(
        uint typeOfDoc,
        uint version
    ) external returns(
        DocsRepo.Doc memory doc
    );

    /// @notice Register a proxy upgrade to a new template.
    /// @param temp New template implementation address.
    function upgradeDoc(address temp) external;

    // ##################
    // ##  Read I/O    ##
    // ##################

    // ---- Type of Doc ----

    /// @notice Get number of document types.
    function counterOfTypes() external view returns(uint32);

    /// @notice Check if a document type exists.
    /// @param typeOfDoc Document type.
    function typeExist(uint256 typeOfDoc) external view returns(bool);

    /// @notice Get all document types.
    function getTypesList() external view returns(uint[] memory);

    // ---- Counters ----

    /// @notice Get latest version for a document type.
    /// @param typeOfDoc Document type.
    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32);

    /// @notice Get count of docs for a type/version.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64);

    // ---- Authors ----

    /// @notice Get author userNo for a template.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    function getAuthor(uint typeOfDoc, uint version) external view returns(uint40);

    /// @notice Get author userNo by body address.
    /// @param body Document body address.
    function getAuthorByBody(address body) external view returns(uint40);

    // ---- Temps ----

    /// @notice Check if a template exists for a body address.
    /// @param body Template address.
    function tempExist(address body) external view returns(bool);

    /// @notice Get template document for a type/version.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @return doc Template document.
    function getTemp(uint typeOfDoc, uint version) external view returns(DocsRepo.Doc memory doc);

    /// @notice Get all templates for a document type.
    /// @param typeOfDoc Document type.
    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory);

    // ---- Docs ----

    /// @notice Check if a document instance exists for a body address.
    /// @param body Document body address.
    function docExist(address body) external view returns(bool);

    /// @notice Get header by body address.
    /// @param body Document body address.
    function getHeadByBody(address body) external view returns (DocsRepo.Head memory );

    /// @notice Get a specific document instance by type/version/seq.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param seqOfDoc Document sequence number.
    /// @return doc Document instance.
    function getDoc(
        uint typeOfDoc, uint version, uint seqOfDoc
    ) external view returns(DocsRepo.Doc memory doc);

    /// @notice Get a document instance by userNo.
    /// @param acct User number.
    /// @return doc Document instance (zeroed if not found).
    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc);

    /// @notice Get all documents for a type/version.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    function getDocsList(uint typeOfDoc, uint version) external view returns(DocsRepo.Doc[] memory);

    /// @notice Verify that a document instance is a valid clone or proxy of its template.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param seqOfDoc Document sequence number.
    /// @return flag True if valid.
    function verifyDoc(
        uint typeOfDoc, uint version, uint seqOfDoc
    ) external view returns(bool flag);

}
