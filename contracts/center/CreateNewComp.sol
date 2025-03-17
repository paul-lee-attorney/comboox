// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2025 LI LI @ JINGTIAN & GONGCHENG.
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

import "./access/Ownable.sol";

import "./ICreateNewComp.sol";

contract CreateNewComp is ICreateNewComp, Ownable {

    address immutable public usdc;

    constructor(address _usdc) {
        usdc = _usdc;
    }

    function createComp(address dk) external 
    {
        address primeKeyOfOwner = msg.sender;
        
        address gk = _createDocAtLatestVersion(20, primeKeyOfOwner);
        IAccessControl(gk).initKeepers(address(this), gk);
        IGeneralKeeper(gk).createCorpSeal();

        address[16] memory keepers = 
            _deployKeepers(primeKeyOfOwner, dk, gk);

        _deployBooks(keepers, primeKeyOfOwner, gk);
    
        IAccessControl(gk).setDirectKeeper(dk);
    }

    function _deployKeepers(
        address primeKeyOfOwner, address dk, address gk
    ) private returns (address[16] memory keepers) {
        keepers[0] = dk;
        uint i = 1;
        while (i < 11) {
            keepers[i] = _createDocAtLatestVersion(i, primeKeyOfOwner);
            IAccessControl(keepers[i]).initKeepers(gk, gk);
            IGeneralKeeper(gk).regKeeper(i, keepers[i]);
            i++;
        }
    
        keepers[15] = _createDocAtLatestVersion(30, primeKeyOfOwner);
        IAccessControl(keepers[15]).initKeepers(dk, gk);
        IGeneralKeeper(gk).regKeeper(15, keepers[15]);
    
        while (i < 15) {
            keepers[i] = _createDocAtLatestVersion(i+20, primeKeyOfOwner);
            IAccessControl(keepers[i]).initKeepers(keepers[15], gk);
            IGeneralKeeper(gk).regKeeper(i, keepers[i]);
            i++;
        }

    }

    function _deployBooks(
        address[16] memory keepers,address primeKeyOfOwner,address gk
    ) private {
        address[12] memory books;
        uint8[10] memory types = [11, 12, 13, 14, 13, 15, 16, 17, 18, 19];
        uint8[10] memory seqOfDK = [1, 2, 3, 0, 5, 6, 7, 8, 0, 10];

        uint i;
        while (i < 10) {
            books[i] = _createDocAtLatestVersion(types[i], primeKeyOfOwner);
            IAccessControl(books[i]).initKeepers(keepers[seqOfDK[i]], gk);
            IGeneralKeeper(gk).regBook(i+1, books[i]);
            i++;
        }

        books[10] = _createDocAtLatestVersion(28, primeKeyOfOwner);
        IAccessControl(books[10]).initKeepers(keepers[15], gk);
        IGeneralKeeper(gk).regBook(11, books[10]);

        IGeneralKeeper(gk).regBook(12, usdc);

        books[11] = _createDocAtLatestVersion(29, primeKeyOfOwner);
        IAccessControl(books[11]).initKeepers(keepers[13], gk);
        IGeneralKeeper(gk).regBook(13, books[11]);

    }

    function _createDocAtLatestVersion(uint256 typeOfDoc, address primeKeyOfOwner) internal
        returns(address body)
    {
        uint256 latest = _rc.counterOfVersions(typeOfDoc);
        bytes32 snOfDoc = bytes32((typeOfDoc << 224) + uint224(latest << 192));
        body = _rc.createDoc(snOfDoc, primeKeyOfOwner).body;
    }

}
