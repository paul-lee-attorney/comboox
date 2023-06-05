// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/EnumerableSet.sol";

library DocsRepo {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Head {
        uint16 typeOfDoc;
        uint16 version;
        uint64 seqOfDoc;
        uint40 creator;
        uint48 createDate;
        uint16 para;
        uint16 argu;
        uint32 data;
        uint8 state;        
    }
 
    struct Doc {
        Head head;
        address body;
    }

    struct Repo {
        // typeOfDoc => version => seqOfDoc => Doc
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Doc))) docs;
        mapping(address => bytes32) snOfDoc;
        EnumerableSet.Bytes32Set snList;
    }

    //##################
    //##    写接口     ##
    //##################

    function snParser(bytes32 sn) public pure returns(Head memory head) {
        uint _sn = uint(sn);

        head = Head({
            typeOfDoc: uint16(_sn >> 240),
            version: uint16(_sn >> 224),
            seqOfDoc: uint64(_sn >> 160),
            creator: uint40(_sn >> 120),
            createDate: uint48(_sn >> 72),
            para: uint16(_sn >> 56),
            argu: uint16(_sn >> 40),
            data: uint32(_sn >> 8),
            state: uint8(_sn)
        });
    }

    function codifyHead(Head memory head) public pure returns(bytes32 sn) {
        bytes memory _sn = abi.encodePacked(
                            head.typeOfDoc,
                            head.version,
                            head.seqOfDoc,
                            head.creator,
                            head.createDate,
                            head.para,
                            head.argu,
                            head.data,
                            head.state);  
        assembly {
            sn := mload(add(_sn, 0x20))
        }
    }

    function init(Repo storage repo, address msgSender) 
        public returns(bool flag)
    {
        if (getKeeper(repo) == address(0)) {
            flag = _setKeeper(repo, msgSender);
        }
    }

    function turnOverRepoKey(Repo storage repo, address keeper, address msgSender) 
        public returns (bool flag) 
    {
        require(getKeeper(repo) == msgSender, "DR.TORK: not keeper");
        if (msgSender != keeper) {
            flag = _setKeeper(repo, keeper);
        }
    } 

    function setTemplate(
        Repo storage repo,
        bytes32 snOfDoc, 
        address body,
        address msgSender,
        uint caller
    ) public returns (Doc memory doc) {
        doc.head = snParser(snOfDoc);

        require(doc.head.typeOfDoc > 0, "DR.ST: zero typeOfDoc");
        require(msgSender == getKeeper(repo), "DR.ST: not keeper");

        doc.head.creator = uint40(caller);
        doc.head.version = _increaseCounterOfVersions(repo, doc.head.typeOfDoc);
        doc.head.createDate = uint48(block.timestamp);
        doc.body = body;

        if (repo.snList.add(codifyHead(doc.head))) {
            repo.docs[doc.head.typeOfDoc][doc.head.version][0] = doc;
        }
    }

    function createDoc(Repo storage repo, bytes32 snOfDoc, uint creator)
        public returns (Doc memory doc)
    {
        doc.head = snParser(snOfDoc);

        require(doc.head.typeOfDoc > 0, "DR.CD: zero typeOfDoc");
        require(doc.head.version > 0, "DR.CD: zero version");
        require(creator > 0, "DR.CD: zero creator");

        doc.head.creator = uint40(creator);

        address temp = repo.docs[doc.head.typeOfDoc][doc.head.version][0].body;

        require(temp != address(0), "DR.CD: template not ready");
    
        doc.body = _createClone(temp);

        doc.head.seqOfDoc = _increaseCounterOfDocs(repo, doc.head.typeOfDoc, doc.head.version);
        doc.head.createDate = uint48(block.timestamp);

        bytes32 sn = codifyHead(doc.head);
        if (repo.snList.add(sn)) {
            repo.docs[doc.head.typeOfDoc][doc.head.version][doc.head.seqOfDoc] = doc;
            repo.snOfDoc[doc.body] = sn;
        }
    }

    function _setKeeper(Repo storage repo, address keeper) private returns (bool flag) {
        if (keeper > address(0)) {
            repo.docs[0][0][0].body = keeper;
            flag = true;
        }
    }

    function _increaseCounterOfVersions(Repo storage repo, uint256 typeOfDoc) private returns(uint16 version) {
        repo.docs[typeOfDoc][0][0].head.version++;
        version = repo.docs[typeOfDoc][0][0].head.version;
    }

    function _increaseCounterOfDocs(Repo storage repo, uint256 typeOfDoc, uint256 version) private returns(uint64 seq) {
        repo.docs[typeOfDoc][version][0].head.seqOfDoc++;
        seq = repo.docs[typeOfDoc][version][0].head.seqOfDoc;
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

    function counterOfVersions(Repo storage repo, uint256 typeOfDoc) public view returns(uint16 seq) {
        seq = repo.docs[typeOfDoc][0][0].head.version;
    }

    function counterOfDocs(Repo storage repo, uint256 typeOfDoc, uint256 version) public view returns(uint64 seq) {
        seq = repo.docs[typeOfDoc][version][0].head.seqOfDoc;
    }

    function getKeeper (Repo storage repo) public view returns(address keeper) {
        keeper = repo.docs[0][0][0].body;
    }

    // ==== SingleCheck ====

    function getTemplate(Repo storage repo, bytes32 snOfDoc) public view returns (Doc memory doc) {
        Head memory head = snParser(snOfDoc);
        doc = repo.docs[head.typeOfDoc][head.version][0];
    }

    function docExist(Repo storage repo, bytes32 snOfDoc) public view returns(bool) {
        return repo.snList.contains(snOfDoc);
    }

    function getDoc(Repo storage repo, bytes32 snOfDoc) public view returns(Doc memory doc) {
        if (docExist(repo, snOfDoc)) {
            Head memory head = snParser(snOfDoc);
            doc = repo.docs[head.typeOfDoc][head.version][head.seqOfDoc];
        }
    }

    function getSN(Repo storage repo, address body) public view returns(bytes32 sn) {
        sn = repo.snOfDoc[body];
    }

    function verifyDoc(Repo storage repo, bytes32 snOfDoc) public view returns(bool flag) {
        address temp = getTemplate(repo, snOfDoc).body;
        address query = getDoc(repo, snOfDoc).body;

        flag = _isClone(temp, query);
    }

    // ==== BatchQuery ====

    function getAllSN(Repo storage repo) public view returns(bytes32[] memory) {
        return repo.snList.values();
    }

    function getBodiesList(Repo storage repo, uint256 typeOfDoc, uint256 version) public view returns(address[] memory) {
        uint256 len = counterOfDocs(repo, typeOfDoc, version);
        address[] memory output = new address[](len);
        while (len > 0) {
            output[len - 1]=repo.docs[typeOfDoc][version][len].body;
            len--; 
        }
        return output;
    } 

    function getSNList(Repo storage repo, uint256 typeOfDoc, uint256 version) public view returns(bytes32[] memory) {
        uint256 len = counterOfDocs(repo, typeOfDoc, version);
        bytes32[] memory output = new bytes32[](len);
        while (len > 0) {
            output[len - 1]=codifyHead(repo.docs[typeOfDoc][version][len].head);
            len--; 
        }
        return output;
    } 

    function getDocsList(Repo storage repo, uint256 typeOfDoc, uint256 version) public view returns(Doc[] memory) {
        uint256 len = counterOfDocs(repo, typeOfDoc, version);
        Doc[] memory output = new Doc[](len);
        while (len > 0) {
            output[len - 1] = repo.docs[typeOfDoc][version][len];
            len--; 
        }
        return output;
    } 

    function getTempsList(Repo storage repo, uint256 typeOfDoc) public view returns(Doc[] memory) {
        uint256 len = counterOfVersions(repo, typeOfDoc);
        Doc[] memory output = new Doc[](len);
        while (len > 0) {
            output[len - 1]=repo.docs[typeOfDoc][len][0];
            len--; 
        }
        return output;
    }
}
