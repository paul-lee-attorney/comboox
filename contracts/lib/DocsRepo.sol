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

pragma solidity ^0.8.8;

import "../center/access/IOwnable.sol";
import "../openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "../openzeppelin/utils/structs/EnumerableSet.sol";

library DocsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Head {
        uint32 typeOfDoc;
        uint32 version;
        uint64 seqOfDoc;
        uint40 author;
        uint40 creator;
        uint48 createDate;
    }
 
    struct Body {
        uint32 version;
        uint64 seq;
        address addr;
    }

    struct Doc {
        Head head;
        address body;
    }

    struct Repo {
        // typeOfDoc => version => seqOfDoc => Body
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Body))) bodies;
        // body address => Head
        mapping(address => Head) heads;
        // typeOfDoc set
        EnumerableSet.UintSet typesList;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head.typeOfDoc = uint32(_sn >> 224);
        head.version = uint32(_sn >> 192);
        head.seqOfDoc = uint64(_sn >> 128);
        head.author = uint40(_sn >> 88);
    }

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

    function _isProxy(
        address temp, address proxy
    ) public view returns(bool) {
        return temp == IOwnable(proxy).getImplementation();
    }

    function _regDoc(
        Repo storage repo,
        Doc memory doc
    ) private {
        doc.head.seqOfDoc = _increaseCounterOfDocs(repo, doc.head.typeOfDoc, doc.head.version);            
        doc.head.createDate = uint48(block.timestamp);

        repo.bodies[doc.head.typeOfDoc][doc.head.version][doc.head.seqOfDoc].addr = doc.body;
        repo.heads[doc.body] = doc.head;
    }

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

    function cloneDoc(
        Repo storage repo, 
        uint typeOfDoc,
        uint version,
        uint creator
    ) public returns (Doc memory doc)
    {
        doc = getTemp(repo, typeOfDoc, version);
        doc.head.creator = uint40(creator);
        require(doc.head.creator > 0, "DR.cloneDoc: zero creator");

        doc.body = _createClone(doc.body);
        require(doc.body != address(0), "DR.cloneDoc: clone failed");

        _regDoc(repo, doc);
    }

    function proxyDoc(
        Repo storage repo, 
        uint typeOfDoc,
        uint version,
        uint creator,
        address owner,
        address rc,
        address dk,
        address gk
    ) public returns (Doc memory doc) {
        doc = getTemp(repo, typeOfDoc, version);
        doc.head.creator = uint40(creator);
        require(doc.head.creator > 0, "DR.proxyDoc: zero creator");
        
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,address,address)",
            owner,
            rc,
            dk,
            gk
        );

        doc.body = address(new ERC1967Proxy(doc.body, data));

        _regDoc(repo, doc);
    }

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
    
        require(oldHead.typeOfDoc == doc.head.typeOfDoc,
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

    function counterOfTypes(Repo storage repo) public view returns(uint32) {
        return uint32(repo.typesList.length());
    }

    function typeExist(Repo storage repo, uint typeOfDoc) public view returns(bool) {
        return repo.typesList.contains(typeOfDoc);
    }

    function getTypesList(Repo storage repo) public view returns(uint[] memory) {
        return repo.typesList.values();
    }

    // ---- Counters ----

    function counterOfVersions(Repo storage repo, uint typeOfDoc) public view returns(uint32) {
        return uint32(repo.bodies[uint32(typeOfDoc)][0][0].seq);
    }

    function counterOfDocs(Repo storage repo, uint typeOfDoc, uint version) public view returns(uint64) {
        return repo.bodies[uint32(typeOfDoc)][uint32(version)][0].seq;
    }

    // ---- Authors ----

    function getAuthor(
        Repo storage repo,
        uint typeOfDoc,
        uint version
    ) public view returns(uint40) {
        address temp = repo.bodies[typeOfDoc][version][0].addr;
        require(temp != address(0), "getAuthor: temp not exist");

        return repo.heads[temp].author;
    }

    function getAuthorByBody(
        Repo storage repo,
        address body
    ) public view returns(uint40) {
        Head memory head = getHeadByBody(repo, body);
        return getAuthor(repo, head.typeOfDoc, head.version);
    }

    // ---- Temps ----

    function tempExist(Repo storage repo, address body) public view returns(bool) {
        Head memory head = repo.heads[body];
        if (   body == address(0) 
            || head.typeOfDoc == 0 
            || head.version == 0 
            || head.seqOfDoc != 0
        ) return false;
   
        return repo.bodies[head.typeOfDoc][head.version][0].addr == body;
    }

    function getTemp(
        Repo storage repo,
        uint typeOfDoc, uint version
    ) public view returns(Doc memory doc) {
        doc.body = repo.bodies[uint32(typeOfDoc)][uint32(version)][0].addr;
        doc.head = repo.heads[doc.body];
        require(tempExist(repo, doc.body),
            "DR.getTemp: temp not exist");
    }

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

    function docExist(Repo storage repo, address body) public view returns(bool) {
        Head memory head = repo.heads[body];
        if (   body == address(0) 
            || head.typeOfDoc == 0 
            || head.version == 0 
            || head.seqOfDoc == 0
        ) return false;
   
        return repo.bodies[head.typeOfDoc][head.version][head.seqOfDoc].addr == body;
    }

    function getHeadByBody(
        Repo storage repo,
        address body
    ) public view returns (Head memory ) {
        return repo.heads[body];
    }

    function getDoc(
        Repo storage repo,
        uint typeOfDoc, uint version, uint seqOfDoc
    ) public view returns(Doc memory doc) {
        doc.body = repo.bodies[uint32(typeOfDoc)][uint32(version)][uint64(seqOfDoc)].addr;
        doc.head = repo.heads[doc.body];
        require(docExist(repo, doc.body),
            "DR.getDoc: doc not exist");
    }

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
