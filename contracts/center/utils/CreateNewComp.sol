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

pragma solidity ^0.8.24;

// import "../access/Ownable.sol";

import "../../openzeppelin/proxy/utils/Initializable.sol";
import "../../openzeppelin/proxy/utils/UUPSUpgradeable.sol";

import "./ICreateNewComp.sol";
import "../../lib/InterfacesHub.sol";

contract CreateNewComp is ICreateNewComp, Initializable, UUPSUpgradeable {
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
        GK, // 15
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

    address public rc;
    address public bank;
    uint[20] private _docs4FundKeeper;
    uint[20] private _docs4Keeper;
    uint[20] private _docs4Book;

    // ==== UUPSUpgradable ====

    uint[50] private __gap;

    function initialize(
        address _usdc, address _rc
    ) external initializer {
        if (_rc == address(0)) 
            revert CNC_WrongInput(bytes32("CNC_ZeroRC"));
        if (_usdc == address(0)) 
            revert CNC_WrongInput(bytes32("CNC_ZeroUSDC"));

        rc = _rc;
        bank = _usdc;
        _initDocs4Keeper();
        _initDocs4FundKeeper();
        _initDocs4Book();
    }

    function _authorizeUpgrade(address newImpl) internal override onlyKeeper{}

    function upgradeCNCTo(address newImpl) external onlyKeeper onlyProxy {
        upgradeTo(newImpl);
        rc.getRC().upgradeDoc(newImpl);
    }

    //######################
    //##  Error & Event   ##
    //######################

    error CNC_WrongParty(bytes32 reason);

    error CNC_WrongInput(bytes32 reason);

    //##################
    //##  Modifiers   ##
    //##################

    modifier onlyKeeper {
        if (rc.getRC().getBookeeper() != msg.sender) 
            revert CNC_WrongParty(bytes32("CNC_NotKeeper"));
        _;
    }

    // ==== Type Setting ====

    /// @dev Initialize the document type mapping for keepers and books.
    /// uint32(uint(keccak256("ROCKeeper"))) = 0x4c9c9582
    function _initDocs4Keeper() private {
        _docs4Keeper[uint8(Keepers.ROCK)]       = 0x4c9c9582;
        _docs4Keeper[uint8(Keepers.RODK)]       = 0x4218a169;
        _docs4Keeper[uint8(Keepers.BMMK)]       = 0xca6e13b7;
        _docs4Keeper[uint8(Keepers.ROMK)]       = 0xa223ca65;
        _docs4Keeper[uint8(Keepers.GMMK)]       = 0x49148247;
        _docs4Keeper[uint8(Keepers.ROAK)]       = 0x7eaeb1a4;
        _docs4Keeper[uint8(Keepers.ROOK)]       = 0x3ac07862;
        _docs4Keeper[uint8(Keepers.ROPK)]       = 0x4fcfb5a7;
        _docs4Keeper[uint8(Keepers.SHAK)]       = 0x2beb4fa1;
        _docs4Keeper[uint8(Keepers.LOOK)]       = 0xf9b45faf;
        _docs4Keeper[uint8(Keepers.ROIK)]       = 0xd042852b;
        _docs4Keeper[uint8(Keepers.Accountant)] = 0x671969be;
        _docs4Keeper[uint8(Keepers.GK)]         = 0x25586efd;
    }

    function _initDocs4FundKeeper() private {
        _docs4FundKeeper[uint8(Keepers.ROCK)]       = 0x1590b2fb;
        _docs4FundKeeper[uint8(Keepers.RODK)]       = 0x4218a169;
        _docs4FundKeeper[uint8(Keepers.BMMK)]       = 0xca6e13b7;
        _docs4FundKeeper[uint8(Keepers.ROMK)]       = 0xa223ca65;
        _docs4FundKeeper[uint8(Keepers.GMMK)]       = 0x6c88e247;
        _docs4FundKeeper[uint8(Keepers.ROAK)]       = 0x7eaeb1a4;
        _docs4FundKeeper[uint8(Keepers.ROOK)]       = 0x3ac07862;
        _docs4FundKeeper[uint8(Keepers.ROPK)]       = 0x4fcfb5a7;
        _docs4FundKeeper[uint8(Keepers.SHAK)]       = 0x2beb4fa1;
        _docs4FundKeeper[uint8(Keepers.LOOK)]       = 0x6ab7d4a6;
        _docs4FundKeeper[uint8(Keepers.ROIK)]       = 0x918b186a;
        _docs4FundKeeper[uint8(Keepers.Accountant)] = 0x797eb8dd;
        _docs4FundKeeper[uint8(Keepers.RORK)]       = 0x7ecb1211;
    }

    function _initDocs4Book() private {
        _docs4Book[uint8(Books.ROC)]        = 0xd37755d2;
        _docs4Book[uint8(Books.ROD)]        = 0xe46d6d1a;
        _docs4Book[uint8(Books.BMM)]        = 0x741de5d6;
        _docs4Book[uint8(Books.ROM)]        = 0x2d24e68a;
        _docs4Book[uint8(Books.GMM)]        = 0x741de5d6;
        _docs4Book[uint8(Books.ROA)]        = 0xdf54d158;
        _docs4Book[uint8(Books.ROO)]        = 0x0329c3b1;
        _docs4Book[uint8(Books.ROP)]        = 0xc4a1057a;
        _docs4Book[uint8(Books.ROS)]        = 0x021dad98;
        _docs4Book[uint8(Books.LOO)]        = 0x198962ae;
        _docs4Book[uint8(Books.ROI)]        = 0x01716bf1;
        _docs4Book[uint8(Books.Cashier)]    = 0xa019f9ef;
        _docs4Book[uint8(Books.ROR)]        = 0x8bb6c49c;
    }

    // ==== configuration ====

    function updateRC(address _rc) external onlyKeeper {
        rc = _rc;
        emit UpdateRC(_rc, msg.sender);
    }

    function updateBank(address _bank) external onlyKeeper {
        bank = _bank;
        emit UpdateBank(_bank, msg.sender);
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
    function createComp(uint typeOfEntity, address dk) external {
        if (dk == address(0)) 
            revert CNC_WrongInput(bytes32("CNC_ZeroDK"));

        if (typeOfEntity == 0 || typeOfEntity > 9) 
            revert CNC_WrongInput(bytes32("CNC_InvalidTypeOfEntity"));

        address gk = _createProxyAtLatestVersion(_docs4Keeper[uint8(Keepers.GK)]);
        IAccessControl(gk).initKeepers(address(this), gk);
        gk.getGK().createCorpSeal(uint8(typeOfEntity));

        _deployKeepers(typeOfEntity, gk);

        _deployBooks(typeOfEntity, dk, gk);

        IOwnable(gk).setNewOwner(msg.sender);
        IAccessControl(gk).setDirectKeeper(dk);
    }

    function _createProxyAtLatestVersion(uint256 typeOfDoc) private
        returns(address body)
    {
        uint256 latest = rc.getRC().counterOfVersions(typeOfDoc);
        body = rc.getRC().proxyDoc(typeOfDoc, latest).body;
    }

    function _deployKeepers(uint typeOfEntity, address gk) private {
        uint i = 1;
        while (i <= 16) {

            if (i == uint8(Keepers.Blank_1) || 
                i == uint8(Keepers.Blank_2) || 
                i == uint8(Keepers.GK)
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

            address keeper = typeOfEntity > 4
                ? _getLatestVersionOfTemp(_docs4FundKeeper[i])
                : _getLatestVersionOfTemp(_docs4Keeper[i]);

            gk.getGK().regKeeper(i, keeper);
            i++;
        }
    }

    function _getLatestVersionOfTemp(
        uint typeOfDoc
    ) private view returns(address temp) {
        uint256 latest = rc.getRC().counterOfVersions(typeOfDoc);
        temp = rc.getRC().getTemp(typeOfDoc, latest).body;
    }

    function _deployBooks(
        uint typeOfEntity, address dk, address gk
    ) private {
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

            address book = _createProxyAtLatestVersion(_docs4Book[i]);
            if (i == uint8(Books.ROS) || i == uint8(Books.ROM)) {
                IAccessControl(book).initKeepers(dk, gk);
            } else {
                IAccessControl(book).initKeepers(gk, gk);
            }
            gk.getGK().regBook(i, book);
            IOwnable(book).setNewOwner(msg.sender);            
            i++;
        }
    }

}
