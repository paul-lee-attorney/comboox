// SPDX-License-Identifier: UNLICENSED

/* *
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

import "../comps/common/access/OwnerControl.sol";

import "./ICreateNewComp.sol";

contract CreateNewComp is ICreateNewComp, OwnerControl {
        
    function createComp(address dk) external 
    {
        address primeKeyOfOwner = msg.sender;
        address rc = address(_rc);
        
        address gk = _createDocAtLatestVersion(20, primeKeyOfOwner);
        IAccessControl(gk).init(primeKeyOfOwner, address(this), rc, gk);
        IGeneralKeeper(gk).createCorpSeal();

        address[11] memory keepers = 
            _deployKeepers(primeKeyOfOwner, dk, rc, gk);

        _deployBooks(keepers, primeKeyOfOwner, rc, gk);
    
        IAccessControl(gk).setDirectKeeper(dk);
    }

    function _deployKeepers(
        address primeKeyOfOwner, 
        address dk,
        address rc,
        address gk
    ) private returns (address[11] memory keepers) {
        keepers[0] = dk;
        uint i = 1;
        while (i < 11) {
            keepers[i] = _createDocAtLatestVersion(i, primeKeyOfOwner);
            IAccessControl(keepers[i]).init(primeKeyOfOwner, gk, rc, gk);
            IGeneralKeeper(gk).regKeeper(i, keepers[i]);
            i++;
        }
    }

    function _deployBooks(
        address[11] memory keepers,
        address primeKeyOfOwner, 
        address rc,
        address gk
    ) private {
        address[10] memory books;
        uint8[10] memory types = [11, 12, 13, 14, 13, 15, 16, 17, 18, 19];
        uint8[10] memory seqOfDK = [1, 2, 3, 0, 5, 6, 7, 8, 0, 10];

        uint i;
        while (i < 10) {
            books[i] = _createDocAtLatestVersion(types[i], primeKeyOfOwner);
            IAccessControl(books[i]).init(primeKeyOfOwner, keepers[seqOfDK[i]], rc, gk);
            IGeneralKeeper(gk).regBook(i+1, books[i]);
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
