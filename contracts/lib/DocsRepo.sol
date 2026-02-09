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

/// @notice typeOfDoc numbering rules (uint32): four 8-bit segments shown as two hex chars each.
/// @dev Bit ranges (MSB -> LSB):
///      (0~7)   Domain: RegCenter, Comps, Funds, OpenZeppelin, ...
///      (8~15)  Category: Libraries, Routers, Keepers, Registers, Utils, ...
///      (16~23) Feature: GeneralKeeper, ROAKeeper, ROCKeeper, ...
///      (24~32) Interface variants: e.g. GeneralKeeper -> PrivateComp, ListedComp, ListedOpenComp, ...
/// @dev For proxy upgrades, the top 24 bits (0~23) must match; only interface variants may differ.

pragma solidity ^0.8.8;

/// @title DocsRepo - TypeOfDoc: 0x01010201 (Domain: RegCenter, Category: Libraries, Feature: DocsRepo, Interface: v1)
/// @notice In-memory indexed repository of document templates, proxies, and clones.
/// @dev Stores document metadata (Head) and body addresses in nested mappings keyed by
///      typeOfDoc -> version -> seqOfDoc. Provides registration, upgrade, and query helpers.

import "../center/access/IOwnable.sol";
import "../openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "../openzeppelin/utils/structs/EnumerableSet.sol";

library DocsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Document header metadata encoded in a 32-byte identifier.
    /// @dev Fields are packed when encoded via {codifyHead}.
    struct Head {
        uint32 typeOfDoc;
        uint32 version;
        uint64 seqOfDoc;
        uint40 author;
        uint40 creator;
        uint48 createDate;
    }
 
    /// @notice Minimal body reference for a document instance.
    /// @dev `version` and `seq` are used to link upgrades.
    struct Body {
        uint32 version;
        uint64 seq;
        address addr;
    }

    /// @notice Full document tuple (header + body).
    struct Doc {
        Head head;
        address body;
    }

    /// @notice Repository storage container.
    /// @dev `bodies[type][version][seq]` stores the body address for a specific doc instance.
    ///      `heads[body]` stores the header for a given body address.
    struct Repo {
        // typeOfDoc => version => seqOfDoc => Body
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Body))) bodies;
        // body address => Head
        mapping(address => Head) heads;
        // typeOfDoc set
        EnumerableSet.UintSet typesList;
    }

    modifier proxyable(uint typeOfDoc) {
        uint32 typeOfDoc32 = uint32(typeOfDoc);
        require(
            (typeOfDoc32 & 0xFFFF0000 != 0x020e0000) && // not regCenter
            (typeOfDoc32 & 0xFFFF0000 != 0x060e0000), // not regCenter utils
            "DR.proxyable: NOT"
        );
        _;
    }

    //##################
    //##  Write I/O   ##
    //##################

    /// @notice Decode a document identifier into a {Head}.
    /// @param sn Encoded document identifier.
    /// @return head Decoded document header.
    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head.typeOfDoc = uint32(_sn >> 224);
        head.version = uint32(_sn >> 192);
        head.seqOfDoc = uint64(_sn >> 128);
        head.author = uint40(_sn >> 88);
    }

    /// @notice Encode a {Head} into a 32-byte identifier.
    /// @param head Document header.
    /// @return sn Encoded identifier.
    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfDoc,
                            head.version,
                            head.seqOfDoc,
                            head.author,
                            head.creator,
                            head.createDate);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    /// @notice Register a template contract for a document type.
    /// @dev Creates version=1..n and seqOfDoc=0 for templates.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type (must be > 0).
    /// @param body Template contract address (non-zero, not registered).
    /// @param author Author userNo (must be > 0).
    /// @param caller Creator userNo (must be > 0).
    /// @return head The created template header.
    function setTemplate(
        Repo storage repo,
        uint typeOfDoc, 
        address body,
        uint author,
        uint caller
    ) public returns (Head memory head) {
        head.typeOfDoc = uint32(typeOfDoc);
        head.author = uint40(author);
        head.creator = uint40(caller);

        require(body != address(0),
            "DR.setTemp: zero body");
        require(repo.heads[body].typeOfDoc == 0, 
            "DR.setTemp: temp already exists");
        
        require(head.typeOfDoc > 0, "DR.setTemp: zero typeOfDoc");
        require(head.author > 0, "DR.setTemp: zero author");
        require(head.creator > 0, "DR.setTemp: zero creator");

        repo.typesList.add(head.typeOfDoc);

        head.version = _increaseCounterOfVersions(repo, head.typeOfDoc);
        head.createDate = uint48(block.timestamp);
    
        repo.bodies[head.typeOfDoc][head.version][0].addr = body;
        repo.heads[body] = head;
    }

    /// @notice Check if a proxy points to the given template implementation.
    /// @param temp Template implementation address.
    /// @param proxy Proxy address.
    /// @return True if proxy implementation equals template.
    function _isProxy(
        address temp, address proxy
    ) public view returns(bool) {
        return temp == IOwnable(proxy).getImplementation();
    }

    /// @notice Internal helper to register a document instance.
    /// @param repo Repository storage.
    /// @param doc Document instance (head + body).
    function _regDoc(
        Repo storage repo,
        Doc memory doc
    ) private {
        doc.head.seqOfDoc = _increaseCounterOfDocs(repo, doc.head.typeOfDoc, doc.head.version);            
        doc.head.createDate = uint48(block.timestamp);

        repo.bodies[doc.head.typeOfDoc][doc.head.version][doc.head.seqOfDoc].addr = doc.body;
        repo.heads[doc.body] = doc.head;
    }

    /// @notice Register a proxy instance created externally.
    /// @param repo Repository storage.
    /// @param temp Template implementation address (must exist).
    /// @param proxy Proxy address to register (non-zero, not already registered).
    /// @param caller Creator userNo (must be > 0).
    /// @return doc Registered document instance.
    function regProxy(
        Repo storage repo,
        address temp,
        address proxy,
        uint caller
    ) public returns (Doc memory doc) {
        require(caller != 0, 
            "DR.regProxy: zero caller");
        require(tempExist(repo, temp), 
            "DR.regProxy: temp not exist");
        require(proxy != address(0), 
            "DR.regProxy: zero proxy");            
        require(!docExist(repo, proxy), 
            "DR.regProxy: already reged");
        require(_isProxy(temp, proxy),
            "DR.regProxy: wrong template");

        doc.head = repo.heads[temp];
        doc.head.creator = uint40(caller);
        doc.body = proxy;

        _regDoc(repo, doc);
        
    }

    /// @notice Create and register a minimal-proxy clone of a template.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param creator Creator userNo (must be > 0).
    /// @return doc Registered document instance.
    function cloneDoc(
        Repo storage repo, 
        uint typeOfDoc,
        uint version,
        uint creator
    ) public proxyable(typeOfDoc) returns (Doc memory doc)
    {
        doc = getTemp(repo, typeOfDoc, version);
        doc.head.creator = uint40(creator);
        require(doc.head.creator > 0, "DR.cloneDoc: zero creator");

        doc.body = _createClone(doc.body);
        require(doc.body != address(0), "DR.cloneDoc: clone failed");

        _regDoc(repo, doc);
    }

    /// @notice Create and register an ERC1967 proxy initialized via `initialize`.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param creator Creator userNo (must be > 0).
    /// @return doc Registered document instance.
    function proxyDoc(
        Repo storage repo, 
        uint typeOfDoc,
        uint version,
        uint creator
    ) public proxyable(typeOfDoc) returns (Doc memory doc) {
        doc = getTemp(repo, typeOfDoc, version);
        doc.head.creator = uint40(creator);
        require(doc.head.creator > 0, "DR.proxyDoc: zero creator");
        
        bytes memory data = abi.encodeWithSignature(
                    "initialize(address,address)",
                    msg.sender,
                    address(this)
                );

        doc.body = address(new ERC1967Proxy(doc.body, data));

        _regDoc(repo, doc);
    }

    /// @notice Register a proxy upgrade to a new template version.
    /// @param repo Repository storage.
    /// @param temp New template implementation (must exist).
    /// @param proxy Existing proxy address (must be registered).
    /// @return doc Registered upgraded document instance.
    function upgradeDoc(
        Repo storage repo, 
        address temp,
        address proxy
    ) public returns (Doc memory doc) {
        require(tempExist(repo, temp),
            "DR.upgradeDoc: temp not exist");
        require(docExist(repo, proxy),
            "DR.upgradeDoc: proxy not exist");

        doc.head = repo.heads[temp];
        doc.body = proxy;

        Head memory oldHead = repo.heads[proxy];
    
        require(
            (oldHead.typeOfDoc & 0xFFFFFF00) == (doc.head.typeOfDoc & 0xFFFFFF00),
            "DR.upgradeDoc: wrong typeOfDoc");

        require(oldHead.version != doc.head.version,
            "DR.upgradeDoc: wrong version");
        require(_isProxy(temp, proxy),
            "DR.upgradeDoc: wrong template");

        _regDoc(repo, doc);

        Body storage oldBody = 
            repo.bodies[oldHead.typeOfDoc][oldHead.version][oldHead.seqOfDoc];

        oldBody.addr = address(0);
        oldBody.version = doc.head.version;
        oldBody.seq = doc.head.seqOfDoc;
    }

    /// @notice Transfer IPR by updating author for a template.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param transferee New author userNo.
    /// @param caller Caller userNo (must equal current author).
    function transferIPR(
        Repo storage repo,
        uint typeOfDoc,
        uint version,
        uint transferee,
        uint caller 
    ) public {
        require (caller == getAuthor(repo, typeOfDoc, version),
            "DR.transferIPR: not author");
        repo.heads[repo.bodies[typeOfDoc][version][0].addr].author = uint40(transferee);
    }

    /// @notice Increment template version counter for a document type.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @return New version (uint32), wraps to 1 on overflow.
    function _increaseCounterOfVersions(
        Repo storage repo, 
        uint256 typeOfDoc
    ) private returns(uint32) {

        unchecked {
            repo.bodies[typeOfDoc][0][0].seq = 
                repo.bodies[typeOfDoc][0][0].seq == type(uint32).max
                    ? 1
                    : repo.bodies[typeOfDoc][0][0].seq + 1;   
        }

        return uint32(repo.bodies[typeOfDoc][0][0].seq);
    }

    /// @notice Increment doc instance counter for a document type/version.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @return New seqOfDoc (uint64), wraps to 1 on overflow.
    function _increaseCounterOfDocs(
        Repo storage repo, 
        uint256 typeOfDoc, 
        uint256 version
    ) private returns(uint64) {
        unchecked {
            repo.bodies[typeOfDoc][version][0].seq = 
                repo.bodies[typeOfDoc][version][0].seq == type(uint64).max
                    ? 1
                    : repo.bodies[typeOfDoc][version][0].seq + 1;   
        }
        return repo.bodies[typeOfDoc][version][0].seq;
    }

    // ==== CloneFactory ====

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly


    /// @notice Create an EIP-1167 minimal proxy clone of `temp`.
    /// @param temp Template implementation address.
    /// @return result Clone address (zero on failure).
    function _createClone(address temp) private returns (address result) {
        bytes20 tempBytes = bytes20(temp);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), tempBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    /// @notice Check if `query` is an EIP-1167 clone of `temp`.
    /// @param temp Template implementation address.
    /// @param query Address to test.
    /// @return result True if `query` is a clone of `temp`.
    function _isClone(address temp, address query)
        private view returns (bool result)
    {
        bytes20 tempBytes = bytes20(temp);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), tempBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }

    //##################
    //##   read I/O   ##
    //##################

    // ---- TypeOfDoc ---- 

    /// @notice Get number of document types.
    /// @param repo Repository storage.
    /// @return Number of types.
    function counterOfTypes(Repo storage repo) public view returns(uint32) {
        return uint32(repo.typesList.length());
    }

    /// @notice Check if a document type exists.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @return True if exists.
    function typeExist(Repo storage repo, uint typeOfDoc) public view returns(bool) {
        return repo.typesList.contains(typeOfDoc);
    }

    /// @notice Get all document types.
    /// @param repo Repository storage.
    /// @return Array of document types.
    function getTypesList(Repo storage repo) public view returns(uint[] memory) {
        return repo.typesList.values();
    }

    // ---- Counters ----

    /// @notice Get latest version for a document type.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @return Latest version counter.
    function counterOfVersions(Repo storage repo, uint typeOfDoc) public view returns(uint32) {
        return uint32(repo.bodies[uint32(typeOfDoc)][0][0].seq);
    }

    /// @notice Get count of docs for a document type/version.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @return Latest doc counter.
    function counterOfDocs(Repo storage repo, uint typeOfDoc, uint version) public view returns(uint64) {
        return repo.bodies[uint32(typeOfDoc)][uint32(version)][0].seq;
    }

    // ---- Authors ----

    /// @notice Get author userNo for a template.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @return Author userNo.
    function getAuthor(
        Repo storage repo,
        uint typeOfDoc,
        uint version
    ) public view returns(uint40) {
        address temp = repo.bodies[typeOfDoc][version][0].addr;
        require(temp != address(0), "getAuthor: temp not exist");

        return repo.heads[temp].author;
    }

    /// @notice Get author userNo by body address.
    /// @param repo Repository storage.
    /// @param body Document body address.
    /// @return Author userNo.
    function getAuthorByBody(
        Repo storage repo,
        address body
    ) public view returns(uint40) {
        Head memory head = getHeadByBody(repo, body);
        return getAuthor(repo, head.typeOfDoc, head.version);
    }

    // ---- Temps ----

    /// @notice Check if a template exists for a body address.
    /// @param repo Repository storage.
    /// @param body Template address.
    /// @return True if exists.
    function tempExist(Repo storage repo, address body) public view returns(bool) {
        Head memory head = repo.heads[body];
        if (   body == address(0) 
            || head.typeOfDoc == 0 
            || head.version == 0 
            || head.seqOfDoc != 0
        ) return false;
   
        return repo.bodies[head.typeOfDoc][head.version][0].addr == body;
    }

    /// @notice Get template document for a type/version.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @return doc Template document.
    function getTemp(
        Repo storage repo,
        uint typeOfDoc, uint version
    ) public view returns(Doc memory doc) {
        doc.body = repo.bodies[uint32(typeOfDoc)][uint32(version)][0].addr;
        doc.head = repo.heads[doc.body];
        require(tempExist(repo, doc.body),
            "DR.getTemp: temp not exist");
    }

    /// @notice Get all templates for a document type.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @return Array of templates ordered by version.
    function getVersionsList(
        Repo storage repo,
        uint typeOfDoc
    ) public view returns(Doc[] memory)
    {
        uint32 len = counterOfVersions(repo, typeOfDoc);
        Doc[] memory out = new Doc[](len);

        while (len > 0) {
            out[len - 1] = getTemp(repo, uint32(typeOfDoc), len);
            len--;
        }

        return out;
    }

    // ---- Docs ----

    /// @notice Check if a document instance exists for a body address.
    /// @param repo Repository storage.
    /// @param body Document body address.
    /// @return True if exists.
    function docExist(Repo storage repo, address body) public view returns(bool) {
        Head memory head = repo.heads[body];
        if (   body == address(0) 
            || head.typeOfDoc == 0 
            || head.version == 0 
            || head.seqOfDoc == 0
        ) return false;
   
        return repo.bodies[head.typeOfDoc][head.version][head.seqOfDoc].addr == body;
    }

    /// @notice Get header by body address.
    /// @param repo Repository storage.
    /// @param body Document body address.
    /// @return Header (zeroed if not found).
    function getHeadByBody(
        Repo storage repo,
        address body
    ) public view returns (Head memory ) {
        return repo.heads[body];
    }

    /// @notice Get a specific document instance by type/version/seq.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param seqOfDoc Document sequence number.
    /// @return doc Document instance.
    function getDoc(
        Repo storage repo,
        uint typeOfDoc, uint version, uint seqOfDoc
    ) public view returns(Doc memory doc) {
        doc.body = repo.bodies[uint32(typeOfDoc)][uint32(version)][uint64(seqOfDoc)].addr;
        doc.head = repo.heads[doc.body];
        require(docExist(repo, doc.body),
            "DR.getDoc: doc not exist");
    }

    /// @notice Get all documents for a type/version.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @return Array of documents ordered by seq.
    function getDocsList(
        Repo storage repo,
        uint typeOfDoc, uint version
    ) public view returns(Doc[] memory) {
        Head memory head;
        head.typeOfDoc = uint32(typeOfDoc);
        head.version = uint32(version);
                
        uint64 len = counterOfDocs(repo, head.typeOfDoc, head.version);
        Doc[] memory out = new Doc[](len);

        while (len > 0) {
            out[len - 1] = getDoc(repo, head.typeOfDoc, head.version, len);
            len--;
        }

        return out;
    }

    // ---- Verification ----

    /// @notice Verify that a document instance is a valid clone or proxy of its template.
    /// @param repo Repository storage.
    /// @param typeOfDoc Document type.
    /// @param version Template version.
    /// @param seqOfDoc Document sequence number.
    /// @return True if the instance matches its template.
    function verifyDoc(
        Repo storage repo, 
        uint typeOfDoc, uint version, uint seqOfDoc
    ) public view returns(bool) {
        Head memory head;
        head.typeOfDoc = uint32(typeOfDoc);
        head.version = uint32(version);
        head.seqOfDoc = uint64(seqOfDoc);

        address temp = repo.bodies[head.typeOfDoc][head.version][0].addr;
        address target = repo.bodies[head.typeOfDoc][head.version][head.seqOfDoc].addr;

        return tempExist(repo, temp) && docExist(repo, target) && 
                (_isClone(temp, target) || _isProxy(temp, target));
    }

}
