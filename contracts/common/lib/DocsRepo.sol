// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../lib/EnumerableSet.sol";

library DocsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

     struct Head {
        uint16 typeOfDoc;
        uint16 version;
        uint64 seqOfDoc;
        uint40 creator;
        uint48 createDate;
        uint16 para;
        uint24 argu;
        uint32 data;        
    }
 
    struct Doc {
        Head head;
        address body;
    }

    struct Repo {
        // typeOfDoc => version => seqOfDoc => Doc
        mapping(uint256 => mapping(uint256 => mapping(uint256 => Doc))) docs;
        EnumerableSet.UintSet snList;
    }

    //##################
    //##    写接口     ##
    //##################

    function snParser(uint256 sn) public pure returns(Head memory head) {
        head = Head({
            typeOfDoc: uint16(sn >> 240),
            version: uint16(sn >> 224),
            seqOfDoc: uint64(sn >> 160),
            creator: uint40(sn >> 120),
            createDate: uint48(sn >> 72),
            para: uint16(sn >> 56),
            argu: uint24(sn >> 32),
            data: uint32(sn)
        });
    }

    function codifyHead(Head memory head) public pure returns(uint256 sn) {
        sn = (uint256(head.typeOfDoc) << 240) +
            (uint256(head.version) << 224) +
            (uint256(head.seqOfDoc) << 160) +
            (uint256(head.creator) << 120) +
            (uint256(head.createDate) << 72) +
            (uint256(head.para) << 56) +
            (uint256(head.argu) << 32) +
            head.data;
    }

    function init(Repo storage repo, uint40 caller) 
        public returns(bool flag)
    {
        if (getKeeper(repo) == 0) {
            flag = _setKeeper(repo, caller);
        }
    }

    function turnOverRepoKey(Repo storage repo, uint40 keeper, uint40 caller) 
        public returns (bool flag) 
    {
        require(getKeeper(repo) == caller, "DR.TORK: not keeper");
        if (caller != keeper) {
            flag = _setKeeper(repo, keeper);
        }
    } 

    function setTemplate(
        Repo storage repo,
        uint256 snOfDoc, 
        address body,
        uint40 caller
    ) public returns (Doc memory doc) {
        doc.head = snParser(snOfDoc);

        require(doc.head.typeOfDoc > 0, "DR.ST: zero typeOfDoc");
        require(caller == getKeeper(repo), "DR.ST: not keeper");

        doc.head.creator = caller;
        doc.head.version = _increaseCounterOfVersions(repo, doc.head.typeOfDoc);
        doc.head.createDate = uint48(block.timestamp);
        doc.body = body;

        if (repo.snList.add(codifyHead(doc.head))) {
            repo.docs[doc.head.typeOfDoc][doc.head.version][0] = doc;
        }
    }

    function createDoc(Repo storage repo, uint256 snOfDoc, uint40 creator)
        public returns (Doc memory doc)
    {
        doc.head = snParser(snOfDoc);

        require(doc.head.typeOfDoc > 0, "DR.CD: zero typeOfDoc");
        require(doc.head.version > 0, "DR.CD: zero version");
        require(creator > 0, "DR.CD: zero creator");

        doc.head.creator = creator;

        address temp = repo.docs[doc.head.typeOfDoc][doc.head.version][0].body;

        require(temp != address(0), "DR.CD: template not ready");
    
        doc.body = _createClone(temp);

        doc.head.seqOfDoc = _increaseCounterOfDocs(repo, doc.head.typeOfDoc, doc.head.version);
        doc.head.createDate = uint48(block.timestamp);

        if (repo.snList.add(codifyHead(doc.head))) {
            repo.docs[doc.head.typeOfDoc][doc.head.version][doc.head.seqOfDoc] = doc;
        }
    }

    function _setKeeper(Repo storage repo, uint40 keeper) private returns (bool flag) {
        if (keeper > 0) {
            repo.docs[0][0][0].head.creator = keeper;
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

    function getKeeper (Repo storage repo) public view returns(uint40 keeper) {
        keeper = repo.docs[0][0][0].head.creator;
    }

    // ==== SingleCheck ====

    function getTemplate(Repo storage repo, uint256 snOfDoc) public view returns (Doc memory doc) {
        Head memory head = snParser(snOfDoc);
        doc = repo.docs[head.typeOfDoc][head.version][0];
    }

    function docExist(Repo storage repo, uint256 snOfDoc) public view returns(bool) {
        return repo.snList.contains(snOfDoc);
    }

    function getDoc(Repo storage repo, uint256 snOfDoc) public view returns(Doc memory doc) {
        Head memory head = snParser(snOfDoc);
        doc = repo.docs[head.typeOfDoc][head.version][head.seqOfDoc];
    }

    function verifyDoc(Repo storage repo, uint256 snOfDoc) public view returns(bool flag) {
        address temp = getTemplate(repo, snOfDoc).body;
        address query = getDoc(repo, snOfDoc).body;

        flag = _isClone(temp, query);
    }

    // ==== BatchQuery ====

    function getAllSN(Repo storage repo) public view returns(uint256[] memory) {
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

    function getSNList(Repo storage repo, uint256 typeOfDoc, uint256 version) public view returns(uint256[] memory) {
        uint256 len = counterOfDocs(repo, typeOfDoc, version);
        uint256[] memory output = new uint256[](len);
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
