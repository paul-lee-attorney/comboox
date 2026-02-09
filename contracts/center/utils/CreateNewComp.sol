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

import "../access/Ownable.sol";

import "./ICreateNewComp.sol";
import "../../lib/InterfacesHub.sol";

contract CreateNewComp is ICreateNewComp, Ownable {
    using InterfacesHub for address;

    enum GKs {
        ZeroPoint,
        PrivateComp,
        GrowingComp,
        ListedComp,
        GeneralComp, // 4
        CloseFund,
        ListedCloseFund,
        OpenFund,
        ListedOpenFund,
        GeneralFund
    }

    enum Keepers {
        ZeroPoint, 
        ROCK,
        RODK,
        BMMK,
        ROMK,
        GMMK, // 5
        ROAK,
        ROOK,
        ROPK,
        SHAK,
        LOOK, // 10
        ROIK,
        Accountant,
        Blank_1,
        Blank_2,
        Blank_3, // 15
        RORK
    }

    enum Books {
        ZeroPoint,
        ROC,
        ROD,
        BMM,
        ROM,
        GMM, // 5
        ROA,
        ROO,
        ROP,
        ROS,
        LOO, // 10
        ROI,
        Bank,
        Blank_1,
        Blank_2,
        Cashier, // 15
        ROR
    }

    address public bank;
    uint[20] private _docs4GK;
    uint[20] private _docs4FundKeeper;
    uint[20] private _docs4Keeper;
    uint[20] private _docs4Book;
    uint[20] private _dkMapping;

    // ==== UUPSUpgradable ====

    uint[50] private __gap;

    function initialize(
        address _usdc,
        address regCenter
    ) external override initializer {
        _init(address(0), regCenter);
        _initTypeSetting(_usdc);
    }

    function _initTypeSetting(address _usdc) private {
        bank = _usdc;

        _initDocs4GK();
        _initDocs4Keeper();
        _initDocs4FundKeeper();
        _initDocs4Book();
        _initDKMapping();
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        require(
            rc.getRC().getBookeeper() == msg.sender,
            "CNC._authorizeUpgrade: NOT"
        );
    }

    function upgradeDocTo(address newImplementation) external virtual {
        upgradeTo(newImplementation);
        rc.getRC().upgradeDoc(newImplementation);
    }

    // ==== Modifier ====

    modifier onlyKeeper {
        require(
            rc.getRC().getBookeeper() == msg.sender,
            "CNC.onlyKeeper: NOT"
        );
        _;
    }

    // ==== Type Setting ====

    function _initDocs4GK() private {
        _docs4GK[uint8(GKs.PrivateComp)]        = 0x030e0101;
        _docs4GK[uint8(GKs.GrowingComp)]        = 0x030e0102;
        _docs4GK[uint8(GKs.ListedComp)]         = 0x030e0103;
        _docs4GK[uint8(GKs.GeneralComp)]        = 0x030e0104;
        _docs4GK[uint8(GKs.CloseFund)]          = 0x030e0201;
        _docs4GK[uint8(GKs.ListedCloseFund)]    = 0x030e0202;
        _docs4GK[uint8(GKs.OpenFund)]           = 0x030e0203;
        _docs4GK[uint8(GKs.ListedOpenFund)]     = 0x030e0204;
        _docs4GK[uint8(GKs.GeneralFund)]        = 0x030e0205;
    }

    function _initDocs4Keeper() private {
        _docs4Keeper[uint8(Keepers.ROCK)]       = 0x03010101;
        _docs4Keeper[uint8(Keepers.RODK)]       = 0x03020101;
        _docs4Keeper[uint8(Keepers.BMMK)]       = 0x03030101;
        _docs4Keeper[uint8(Keepers.ROMK)]       = 0x03040101;
        _docs4Keeper[uint8(Keepers.GMMK)]       = 0x03050101;
        _docs4Keeper[uint8(Keepers.ROAK)]       = 0x03060101;
        _docs4Keeper[uint8(Keepers.ROOK)]       = 0x03070101;
        _docs4Keeper[uint8(Keepers.ROPK)]       = 0x03080101;
        _docs4Keeper[uint8(Keepers.SHAK)]       = 0x03090101;
        _docs4Keeper[uint8(Keepers.LOOK)]       = 0x030a0101;
        _docs4Keeper[uint8(Keepers.ROIK)]       = 0x030b0101;
        _docs4Keeper[uint8(Keepers.Accountant)] = 0x030c0101;
        _docs4Keeper[uint8(Keepers.RORK)]       = 0x03100201;
    }

    function _initDocs4FundKeeper() private {
        _docs4FundKeeper[uint8(Keepers.ROCK)]       = 0x03010201;
        _docs4FundKeeper[uint8(Keepers.RODK)]       = 0x03020101;
        _docs4FundKeeper[uint8(Keepers.BMMK)]       = 0x03030101;
        _docs4FundKeeper[uint8(Keepers.ROMK)]       = 0x03040101;
        _docs4FundKeeper[uint8(Keepers.GMMK)]       = 0x03050201;
        _docs4FundKeeper[uint8(Keepers.ROAK)]       = 0x03060101;
        _docs4FundKeeper[uint8(Keepers.ROOK)]       = 0x03070101;
        _docs4FundKeeper[uint8(Keepers.ROPK)]       = 0x03080101;
        _docs4FundKeeper[uint8(Keepers.SHAK)]       = 0x03090101;
        _docs4FundKeeper[uint8(Keepers.LOOK)]       = 0x030a0201;
        _docs4FundKeeper[uint8(Keepers.ROIK)]       = 0x030b0201;
        _docs4FundKeeper[uint8(Keepers.Accountant)] = 0x030c0201;
        _docs4FundKeeper[uint8(Keepers.RORK)]       = 0x03100201;
    }

    function _initDocs4Book() private {
        _docs4Book[uint8(Books.ROC)]        = 0x02010101;
        _docs4Book[uint8(Books.ROD)]        = 0x02020101;
        _docs4Book[uint8(Books.BMM)]        = 0x02050101;
        _docs4Book[uint8(Books.ROM)]        = 0x02040101;
        _docs4Book[uint8(Books.GMM)]        = 0x02050101;
        _docs4Book[uint8(Books.ROA)]        = 0x02060101;
        _docs4Book[uint8(Books.ROO)]        = 0x02070101;
        _docs4Book[uint8(Books.ROP)]        = 0x02080101;
        _docs4Book[uint8(Books.ROS)]        = 0x02090101;
        _docs4Book[uint8(Books.LOO)]        = 0x020a0101;
        _docs4Book[uint8(Books.ROI)]        = 0x020b0101;
        _docs4Book[uint8(Books.Cashier)]    = 0x020f0101;
        _docs4Book[uint8(Books.ROR)]        = 0x02100201;
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

    // ==== configuration ====

    function updateBank(address _bank) external onlyKeeper {
        bank = _bank;
        emit UpdateBank(_bank, msg.sender);
    }

    function updateDocs4GK(uint typeOfEntity, uint typeOfDoc) external onlyKeeper {
        _docs4GK[typeOfEntity] = typeOfDoc;
        emit UpdateDocs4GK(typeOfEntity, typeOfDoc);
    }

    function getSeqOfDoc4GK(uint typeOfEntity) external view returns(uint) {
        return _docs4GK[typeOfEntity];
    }

    function updateDocs4Keeper(uint titleOfKeeper, uint typeOfDoc) external onlyKeeper {
        _docs4Keeper[titleOfKeeper] = typeOfDoc;
        emit UpdateDocs4Keeper(titleOfKeeper, typeOfDoc);
    }

    function getSeqOfDoc4Keeper(uint titleOfKeeper) external view returns(uint) {
        return _docs4Keeper[titleOfKeeper];
    }

    function updateDocs4FundKeeper(uint titleOfKeeper, uint typeOfDoc) external onlyKeeper {
        _docs4FundKeeper[titleOfKeeper] = typeOfDoc;
        emit UpdateDocs4FundKeeper(titleOfKeeper, typeOfDoc);
    }

    function getSeqOfDoc4FundKeeper(uint titleOfKeeper) external view returns(uint) {
        return _docs4FundKeeper[titleOfKeeper];
    }

    function updateDocs4Book(uint titelOfBook, uint typeOfDoc) external onlyKeeper {
        _docs4Book[titelOfBook] = typeOfDoc;
        emit UpdateDocs4Book(titelOfBook, typeOfDoc);
    }

    function getSeqOfDoc4Book(uint titelOfBook) external view returns(uint) {
        return _docs4Book[titelOfBook];
    }

    // ==== Create Comp ====

    function createComp(uint typeOfEntity, address dk) external 
    {     
        require(dk != address(0),
            "CNC.createComp: zero dk");
        require(typeOfEntity > 0 && typeOfEntity < 10,
            "CNC.createComp: invalid typeOfEntity");

        address gk = _createProxyAtLatestVersion(
            _docs4GK[typeOfEntity]
        );
        IAccessControl(gk).initKeepers(address(this), gk);

        address[18] memory keepers = 
            _deployKeepers(typeOfEntity, dk, gk);

        _deployBooks(typeOfEntity, keepers, gk);
    
        IAccessControl(gk).setDirectKeeper(dk);
    }

    function _createProxyAtLatestVersion(uint256 typeOfDoc) private
        returns(address body)
    {
        uint256 latest = rc.getRC().counterOfVersions(typeOfDoc);
        body = rc.getRC().proxyDoc(typeOfDoc, latest).body;
        IOwnable(body).setNewOwner(msg.sender);
    }

    function _deployKeepers(
        uint typeOfEntity, address dk, address gk
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

            if (typeOfEntity == uint8(GKs.CloseFund) && (
                i == uint8(Keepers.LOOK) ||
                i == uint8(Keepers.RORK)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.ListedCloseFund) && (
                i == uint8(Keepers.RORK)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.OpenFund) && (
                i == uint8(Keepers.LOOK)
            )) { i++; continue; }

            keepers[i] = typeOfEntity > 4
                ? _createProxyAtLatestVersion(_docs4FundKeeper[i])
                : _createProxyAtLatestVersion(_docs4Keeper[i]);

            IAccessControl(keepers[i]).initKeepers(gk, gk);
            gk.getGK().regKeeper(i, keepers[i]);
            i++;
        }
    }

    function _deployBooks(
        uint typeOfEntity,
        address[18] memory keepers,
        address gk
    ) private {

        address[18] memory books;

        uint i = 1;
        while (i <= 16) {

            if (i == uint8(Books.Blank_1) ||
                i == uint8(Books.Blank_2)
            ) {i++; continue;}

            if (i == uint8(Books.Bank)) {
                gk.getGK().regBook(i, bank);
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

            if (typeOfEntity == uint8(GKs.CloseFund) && (
                i == uint8(Books.LOO) ||
                i == uint8(Books.ROR)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.ListedCloseFund) && (
                i == uint8(Books.ROR)
            )) { i++; continue;}

            if (typeOfEntity == uint8(GKs.OpenFund) && (
                i == uint8(Books.LOO)
            )) { i++; continue; }

            books[i] = _createProxyAtLatestVersion(_docs4Book[i]);
            IAccessControl(books[i]).initKeepers(keepers[_dkMapping[i]], gk);
            gk.getGK().regBook(i, books[i]);
            i++;
        }
    }

}
