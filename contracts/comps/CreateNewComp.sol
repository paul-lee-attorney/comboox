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

import "./ICreateNewComp.sol";

contract CreateNewComp is ICreateNewComp, Ownable {

    enum GKs {
        ZeroPoint,
        PrivateComp,
        GrowingComp,
        ListedComp,
        FullFuncComp, // 4
        LPFund,
        ListedLPFund,
        OpenFund,
        ListedOpenFund,
        FullFuncFund
    }

    enum Keepers {
        ZeroPoint, 
        ROCK,
        RODK,
        BMMK,
        ROMK,
        GMMK,
        ROAK,
        ROOK,
        ROPK,
        SHAK,
        LOOK, // 10
        ROIK,
        Accountant,
        Blank_1,
        Blank_2,
        Blank_3,
        RORK
    }

    enum Books {
        ZeroPoint,
        ROC,
        ROD,
        BMM,
        ROM,
        GMM,
        ROA,
        ROO,
        ROP,
        ROS,
        LOO, // 10
        ROI,
        Bank,
        Blank_1,
        Blank_2,
        Cashier,
        ROR
    }

    address public bank;
    uint[20] private _docs4GK;
    uint[20] private _docs4FundKeeper;
    uint[20] private _docs4Keeper;
    uint[20] private _docs4Book;
    uint[20] private _dkMapping;

    function _initDocs4GK() private {
        _docs4GK[uint8(GKs.FullFuncComp)] = 20;
        _docs4GK[uint8(GKs.FullFuncFund)] = 40;
        _docs4GK[uint8(GKs.PrivateComp)] = 47;
        _docs4GK[uint8(GKs.GrowingComp)] = 48;
        _docs4GK[uint8(GKs.ListedComp)] = 49;
        _docs4GK[uint8(GKs.LPFund)] = 50;
        _docs4GK[uint8(GKs.ListedLPFund)] = 51;
        _docs4GK[uint8(GKs.OpenFund)] = 52;
        _docs4GK[uint8(GKs.ListedOpenFund)] = 53;
    }

    function _initDocs4Keeper() private {
        _docs4Keeper[uint8(Keepers.ROCK)] = 1;
        _docs4Keeper[uint8(Keepers.RODK)] = 2;
        _docs4Keeper[uint8(Keepers.BMMK)] = 3;
        _docs4Keeper[uint8(Keepers.ROMK)] = 4;
        _docs4Keeper[uint8(Keepers.GMMK)] = 5;
        _docs4Keeper[uint8(Keepers.ROAK)] = 6;
        _docs4Keeper[uint8(Keepers.ROOK)] = 7;
        _docs4Keeper[uint8(Keepers.ROPK)] = 8;
        _docs4Keeper[uint8(Keepers.SHAK)] = 9;
        _docs4Keeper[uint8(Keepers.LOOK)] = 10;
        _docs4Keeper[uint8(Keepers.ROIK)] = 35;
        _docs4Keeper[uint8(Keepers.Accountant)] = 37;
        _docs4Keeper[uint8(Keepers.RORK)] = 38;
    }

    function _initDocs4FundKeeper() private {
        _docs4FundKeeper[uint8(Keepers.ROCK)] = 44;
        _docs4FundKeeper[uint8(Keepers.RODK)] = 2;
        _docs4FundKeeper[uint8(Keepers.BMMK)] = 3;
        _docs4FundKeeper[uint8(Keepers.ROMK)] = 4;
        _docs4FundKeeper[uint8(Keepers.GMMK)] = 42;
        _docs4FundKeeper[uint8(Keepers.ROAK)] = 6;
        _docs4FundKeeper[uint8(Keepers.ROOK)] = 7;
        _docs4FundKeeper[uint8(Keepers.ROPK)] = 8;
        _docs4FundKeeper[uint8(Keepers.SHAK)] = 9;
        _docs4FundKeeper[uint8(Keepers.LOOK)] = 43;
        _docs4FundKeeper[uint8(Keepers.ROIK)] = 45;
        _docs4FundKeeper[uint8(Keepers.Accountant)] = 41;
        _docs4FundKeeper[uint8(Keepers.RORK)] = 38;
    }

    function _initDocs4Book() private {
        _docs4Book[uint8(Books.ROC)] = 11;
        _docs4Book[uint8(Books.ROD)] = 12;
        _docs4Book[uint8(Books.BMM)] = 13;
        _docs4Book[uint8(Books.ROM)] = 14;
        _docs4Book[uint8(Books.GMM)] = 13;
        _docs4Book[uint8(Books.ROA)] = 15;
        _docs4Book[uint8(Books.ROO)] = 16;
        _docs4Book[uint8(Books.ROP)] = 17;
        _docs4Book[uint8(Books.ROS)] = 18;
        _docs4Book[uint8(Books.LOO)] = 19;
        _docs4Book[uint8(Books.ROI)] = 36;
        _docs4Book[uint8(Books.Cashier)] = 28;
        _docs4Book[uint8(Books.ROR)] = 39;
    }

    function _initDKMapping() private {
        _dkMapping[uint8(Books.ROC)] = uint8(Keepers.ROCK);
        _dkMapping[uint8(Books.ROD)] = uint8(Keepers.RODK);
        _dkMapping[uint8(Books.BMM)] = uint8(Keepers.BMMK);
        _dkMapping[uint8(Books.ROM)] = uint8(Keepers.ZeroPoint);
        _dkMapping[uint8(Books.GMM)] = uint8(Keepers.GMMK);
        _dkMapping[uint8(Books.ROA)] = uint8(Keepers.ROAK);
        _dkMapping[uint8(Books.ROO)] = uint8(Keepers.ROOK);
        _dkMapping[uint8(Books.ROP)] = uint8(Keepers.ROPK);
        _dkMapping[uint8(Books.ROS)] = uint8(Keepers.ZeroPoint);
        _dkMapping[uint8(Books.LOO)] = uint8(Keepers.LOOK); // 10
        _dkMapping[uint8(Books.ROI)] = uint8(Keepers.ROIK);
        _dkMapping[uint8(Books.Bank)] = uint8(Keepers.ZeroPoint);
        _dkMapping[uint8(Books.Cashier)] = uint8(Keepers.Accountant);
        _dkMapping[uint8(Books.ROR)] = uint8(Keepers.RORK);
    }

    constructor(address _usdc) {
        bank = _usdc;

        _initDocs4GK();
        _initDocs4Keeper();
        _initDocs4FundKeeper();
        _initDocs4Book();
        _initDKMapping();
    }

    // ==== configuration ====

    function updateBank(address _bank) external onlyOwner {
        bank = _bank;
        emit UpdateBank(_bank, msg.sender);
    }

    function updateDocs4GK(uint typeOfEntity, uint seqOfDoc) external onlyOwner {
        _docs4GK[typeOfEntity] = seqOfDoc;
        emit UpdateDocs4GK(typeOfEntity, seqOfDoc);
    }

    function getSeqOfDoc4GK(uint typeOfDoc) external view returns(uint) {
        return _docs4GK[typeOfDoc];
    }

    function updateDocs4Keeper(uint typeOfDoc, uint seqOfDoc) external onlyOwner {
        _docs4Keeper[typeOfDoc] = seqOfDoc;
        emit UpdateDocs4Keeper(typeOfDoc, seqOfDoc);
    }

    function getSeqOfDoc4Keeper(uint typeOfDoc) external view returns(uint) {
        return _docs4Keeper[typeOfDoc];
    }

    function updateDocs4FundKeeper(uint typeOfDoc, uint seqOfDoc) external onlyOwner {
        _docs4FundKeeper[typeOfDoc] = seqOfDoc;
        emit UpdateDocs4FundKeeper(typeOfDoc, seqOfDoc);
    }

    function getSeqOfDoc4FundKeeper(uint typeOfDoc) external view returns(uint) {
        return _docs4FundKeeper[typeOfDoc];
    }

    function updateDocs4Book(uint typeOfDoc, uint seqOfDoc) external onlyOwner {
        _docs4Book[typeOfDoc] = seqOfDoc;
        emit UpdateDocs4Book(typeOfDoc, seqOfDoc);
    }

    function getSeqOfDoc4Book(uint typeOfDoc) external view returns(uint) {
        return _docs4Book[typeOfDoc];
    }

    // ==== Create Comp ====

    function createComp(uint typeOfEntity, address dk) external 
    {
        address primeKeyOfOwner = msg.sender;
        
        address gk = _createDocAtLatestVersion(_docs4GK[typeOfEntity], primeKeyOfOwner);
        IAccessControl(gk).initKeepers(address(this), gk);
        IBaseKeeper(gk).createCorpSeal();

        address[18] memory keepers = 
            _deployKeepers(typeOfEntity, primeKeyOfOwner, dk, gk);

        _deployBooks(typeOfEntity, keepers, primeKeyOfOwner, gk);
    
        IAccessControl(gk).setDirectKeeper(dk);
    }

    function _deployKeepers(
        uint typeOfEntity, address primeKeyOfOwner, address dk, address gk
    ) private returns (address[18] memory keepers) {
        keepers[0] = dk;
        uint i = 1;
        while (i <= 16) {

            if (i == uint8(Keepers.Blank_1) || 
                i == uint8(Keepers.Blank_2) || 
                i == uint8(Keepers.Blank_3)
            ) { i++; continue; }

            if (typeOfEntity < 5 && (
                i == uint8(Keepers.RORK)                
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.PrivateComp) && (
                i == uint8(Keepers.ROOK) ||
                i == uint8(Keepers.SHAK) ||
                i == uint8(Keepers.LOOK) 
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.GrowingComp) && (
                i == uint8(Keepers.LOOK)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.ListedComp) && (
                i == uint8(Keepers.ROOK) ||
                i == uint8(Keepers.SHAK) 
            )) { i++; continue;}

            if (typeOfEntity > 4 && (
                i == uint8(Keepers.ROOK) ||
                i == uint8(Keepers.SHAK)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.LPFund) && (
                i == uint8(Keepers.LOOK) ||
                i == uint8(Keepers.RORK)                
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.ListedLPFund) && (
                i == uint8(Keepers.RORK)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.OpenFund) && (
                i == uint8(Keepers.LOOK)
            )) { i++; continue; }

            keepers[i] = typeOfEntity > 4
                ? _createDocAtLatestVersion(_docs4FundKeeper[i], primeKeyOfOwner)
                : _createDocAtLatestVersion(_docs4Keeper[i], primeKeyOfOwner);

            IAccessControl(keepers[i]).initKeepers(gk, gk);
            IBaseKeeper(gk).regKeeper(i, keepers[i]);
            i++;
        }
    }

    function _deployBooks(
        uint typeOfEntity,
        address[18] memory keepers,
        address primeKeyOfOwner, address gk
    ) private {

        address[18] memory books;

        uint i = 1;
        while (i <= 16) {

            if (i == uint8(Books.Blank_1) ||
                i == uint8(Books.Blank_2)
            ) {i++; continue;}

            if (i == uint8(Books.Bank)) {
                IBaseKeeper(gk).regBook(i, bank);
                i++; continue;
            }

            if (typeOfEntity < 5 && (
                i == uint8(Books.ROR)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.PrivateComp) && (
                i == uint8(Books.ROO) ||
                i == uint8(Books.LOO)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.GrowingComp) && (
                i == uint8(Books.LOO)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.ListedComp) && (
                i == uint8(Books.ROO)
            )) { i++; continue;}

            if (typeOfEntity > 4 && (
                i == uint8(Books.ROO)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.LPFund) && (
                i == uint8(Books.LOO) ||
                i == uint8(Books.ROR)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.ListedLPFund) && (
                i == uint8(Books.ROR)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.OpenFund) && (
                i == uint8(Books.LOO)
            )) { i++; continue; }

            books[i] = _createDocAtLatestVersion(_docs4Book[i], primeKeyOfOwner);
            IAccessControl(books[i]).initKeepers(keepers[_dkMapping[i]], gk);
            IBaseKeeper(gk).regBook(i, books[i]);
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
