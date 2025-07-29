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

import "../center/access/Ownable.sol";

import "../comps/ICreateNewComp.sol";

contract CreateNewFund is ICreateNewComp, Ownable {

    address immutable public usdc;

    constructor(address _usdc) {
        usdc = _usdc;
    }

    function createComp(address dk) external {
        address primeKeyOfOwner = msg.sender;
        
        address gk = _createDocAtLatestVersion(40, primeKeyOfOwner);
        IAccessControl(gk).initKeepers(address(this), gk);
        IGeneralKeeper(gk).createCorpSeal();

        address[12] memory keepers = 
            _deployKeepers(primeKeyOfOwner, dk, gk);

        _deployBooks(keepers, primeKeyOfOwner, gk);
    
        IAccessControl(gk).setDirectKeeper(dk);
    }

    function _deployKeepers(
        address primeKeyOfOwner, address dk, address gk
    ) private returns (address[12] memory keepers) {

        keepers[0] = dk;
        uint8[11] memory typeOfDocs   = [1, 2, 3, 4, 42, 6, 8, 43, 45, 41, 38];
        uint8[11] memory seqOfKeepers = [1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 16];

        uint i = 1;
        while (i < 12) {
            keepers[i] = _createDocAtLatestVersion(typeOfDocs[i-1], primeKeyOfOwner);
            IAccessControl(keepers[i]).initKeepers(gk, gk);
            IGeneralKeeper(gk).regKeeper(seqOfKeepers[i-1], keepers[i]);
            i++;
        }
    }

    function _deployBooks(
        address[12] memory keepers,address primeKeyOfOwner,address gk
    ) private {
        address[13] memory books;
        uint8[13] memory typesOfDocs = [11, 12, 13, 14, 13, 15, 17, 18, 19, 36, 0, 28, 39];
        uint8[13] memory seqOfBoox   = [1,  2,  3,  4,  5,  6,  8,  9,  10, 11, 12, 15, 16];
        uint8[13] memory seqOfKeeper = [1,  2,  3,  0,  5,  6,  7,  0,  8,  9,  0,  10, 11];

        books[10] = usdc;

        uint i;
        while (i < 13) {
            if (i != 10) {
                books[i] = _createDocAtLatestVersion(typesOfDocs[i], primeKeyOfOwner);
                IAccessControl(books[i]).initKeepers(keepers[seqOfKeeper[i]], gk);
            } 

            IGeneralKeeper(gk).regBook(seqOfBoox[i], books[i]);

            i++;
        }
    }

    function _createDocAtLatestVersion(uint256 typeOfDoc, address primeKeyOfOwner) internal
        returns(address body)
    {
        uint256 latest = _rc.counterOfVersions(typeOfDoc);
        bytes32 snOfDoc = bytes32((typeOfDoc << 224) + uint224(latest << 192));
        body = _rc.createDoc(snOfDoc, primeKeyOfOwner).body;
    }

}
