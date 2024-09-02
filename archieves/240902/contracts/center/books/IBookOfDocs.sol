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

import "../../lib/DocsRepo.sol";

interface IBookOfDocs {

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Docs ====
    
    event SetTemplate(uint256 indexed typeOfDoc, uint256 indexed version, address indexed body);

    event TransferIPR(uint indexed typeOfDoc, uint indexed version, uint indexed transferee);

    event CreateDoc(bytes32 indexed snOfDoc, address indexed body);

    event InsertDoc(bytes32 indexed snOfDoc, address indexed body);

    // ##################
    // ##    Write     ##
    // ##################

    function setTemplate(uint typeOfDoc, address body, uint author) external;

    function transferIPR(uint typeOfDoc, uint version, uint transferee) external;

    function createDoc(bytes32 snOfDoc, address primeKeyOfOwner) external 
        returns(DocsRepo.Doc memory doc);

    // #################
    // ##   Read      ##
    // #################

    function counterOfTypes() external view returns(uint32);

    function counterOfVersions(uint256 typeOfDoc) external view returns(uint32 seq);

    function counterOfDocs(uint256 typeOfDoc, uint256 version) external view returns(uint64 seq);

    function docExist(address body) external view returns(bool);

    function getAuthor(uint typeOfDoc, uint version) external view returns(uint40);

    function getAuthorByBody(address body) external view returns(uint40);

    function getHeadByBody(address body) external view returns (DocsRepo.Head memory );
    
    function getDoc(bytes32 snOfDoc) external view returns(DocsRepo.Doc memory doc);

    function getDocByUserNo(uint acct) external view returns (DocsRepo.Doc memory doc);

    function verifyDoc(bytes32 snOfDoc) external view returns(bool flag);

    function getVersionsList(uint256 typeOfDoc) external view returns(DocsRepo.Doc[] memory);

    function getDocsList(bytes32 snOfDoc) external view returns(DocsRepo.Doc[] memory);
}
