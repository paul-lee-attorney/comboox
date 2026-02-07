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

import "../center/IRegCenter.sol";
import "../center/books/IBookOfDocs.sol";
import "../center/books/IBookOfUsers.sol";

import "../comps/modules/IGeneralKeeper.sol";

import "../comps/books/roa/IRegisterOfAgreements.sol";
import "../comps/books/roc/IRegisterOfConstitution.sol";
import "../comps/books/roc/IShareholdersAgreement.sol";
import "../comps/books/rod/IRegisterOfDirectors.sol";
import "../comps/common/components/IMeetingMinutes.sol";
import "../comps/books/rom/IRegisterOfMembers.sol";
import "../comps/books/ros/IRegisterOfShares.sol";
import "../comps/books/loo/IListOfOrders.sol";
import "../comps/books/roo/IRegisterOfOptions.sol";
import "../comps/books/rop/IRegisterOfPledges.sol";
import "../comps/books/roi/IRegisterOfInvestors.sol";
import "../center/ERC20/IUSDC.sol";
import "../comps/books/cashier/ICashier.sol";
import "../comps/books/ror/IRegisterOfRedemptions.sol";

import "../comps/keepers/IROCKeeper.sol";
import "../comps/keepers/IRODKeeper.sol";
import "../comps/keepers/IBMMKeeper.sol";
import "../comps/keepers/IROMKeeper.sol";
import "../comps/keepers/IGMMKeeper.sol";
import "../comps/keepers/IROAKeeper.sol";
import "../comps/keepers/IROOKeeper.sol";
import "../comps/keepers/IROPKeeper.sol";
import "../comps/keepers/ISHAKeeper.sol";
import "../comps/keepers/ILOOKeeper.sol";
import "../comps/keepers/IROIKeeper.sol";
import "../comps/keepers/IAccountant.sol";
import "../comps/keepers/IRORKeeper.sol";

library InterfacesHub {

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
        LOOK,
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
        LOO,
        ROI,
        Bank,
        Blank_1,
        Blank_2,
        Cashier,
        ROR
    }

    // ==== RegCenter ====
    
    function getRC(address rc) public pure returns(IRegCenter) {
        return IRegCenter(rc);
    }

    function obtainBOU(address rc) public view returns (IBookOfUsers) {
        return getBOU(getRC(rc).bou());
    }

    function obtainBOD(address rc) public view returns (IBookOfDocs) {
        return getBOD(getRC(rc).bod());
    }

    function getBOU(address bou) public pure returns (IBookOfUsers) {
        return IBookOfUsers(bou);
    }

    function getBOD(address bod) public pure returns (IBookOfDocs) {
        return IBookOfDocs(bod);
    }

    // ==== GeneralKeeper ====

    function getGK(address gk) public pure returns (IGeneralKeeper) {
        return IGeneralKeeper(gk);
    }

    // ==== Books ====
    function getROC(address gk) public view returns (IRegisterOfConstitution) {
        return IRegisterOfConstitution(IGeneralKeeper(gk).getBook(uint8(Books.ROC)));
    }

    function getSHA(address gk) public view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(getROC(gk).pointer());
    }

    function getROD(address gk) public view returns (IRegisterOfDirectors) {
        return IRegisterOfDirectors(IGeneralKeeper(gk).getBook(uint8(Books.ROD)));
    }

    function getBMM(address gk) public view returns (IMeetingMinutes) {
        return IMeetingMinutes(IGeneralKeeper(gk).getBook(uint8(Books.BMM)));
    }

    function getROM(address gk) public view returns (IRegisterOfMembers) {
        return IRegisterOfMembers(IGeneralKeeper(gk).getBook(uint8(Books.ROM)));
    }

    function getGMM(address gk) public view returns (IMeetingMinutes) {
        return IMeetingMinutes(IGeneralKeeper(gk).getBook(uint8(Books.GMM)));
    }

    function getROA(address gk) public view returns (IRegisterOfAgreements) {
        return IRegisterOfAgreements(IGeneralKeeper(gk).getBook(uint8(Books.ROA)));
    }

    function getROO(address gk) public view returns (IRegisterOfOptions) {
        return IRegisterOfOptions(IGeneralKeeper(gk).getBook(uint8(Books.ROO)));
    }

    function getROP(address gk) public view returns (IRegisterOfPledges) {
        return IRegisterOfPledges(IGeneralKeeper(gk).getBook(uint8(Books.ROP)));
    }

    function getROS(address gk) public view returns (IRegisterOfShares) {
        return IRegisterOfShares(IGeneralKeeper(gk).getBook(uint8(Books.ROS)));
    }

    function getLOO(address gk) public view returns (IListOfOrders) {
        return IListOfOrders(IGeneralKeeper(gk).getBook(uint8(Books.LOO)));
    }

    function getROI(address gk) public view returns (IRegisterOfInvestors) {
        return IRegisterOfInvestors(IGeneralKeeper(gk).getBook(uint8(Books.ROI)));
    }

    function getBank(address gk) public view returns (IUSDC) {
        return IUSDC(IGeneralKeeper(gk).getBook(uint8(Books.Bank)));
    }

    function getCashier(address gk) public view returns (ICashier) {
        return ICashier(IGeneralKeeper(gk).getBook(uint8(Books.Cashier)));
    }

    function getROR(address gk) public view returns (IRegisterOfRedemptions) {
        return IRegisterOfRedemptions(IGeneralKeeper(gk).getBook(uint8(Books.ROR)));
    }

    // ==== Keepers ====

    function getROCKeeper(address gk) public view returns (IROCKeeper) {
        return IROCKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROCK)));
    }

    function getRODKeeper(address gk) public view returns (IRODKeeper) {
        return IRODKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.RODK)));
    }

    function getBMMKeeper(address gk) public view returns (IBMMKeeper) {
        return IBMMKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.BMMK)));
    }

    function getROMKeeper(address gk) public view returns (IROMKeeper) {
        return IROMKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROMK)));
    }

    function getGMMKeeper(address gk) public view returns (IGMMKeeper) {
        return IGMMKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.GMMK)));
    }

    function getROAKeeper(address gk) public view returns (IROAKeeper) {
        return IROAKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROAK)));
    }

    function getROOKeeper(address gk) public view returns (IROOKeeper) {
        return IROOKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROOK)));
    }

    function getROPKeeper(address gk) public view returns (IROPKeeper) {
        return IROPKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROPK)));
    }

    function getSHAKeeper(address gk) public view returns (ISHAKeeper) {
        return ISHAKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.SHAK)));
    }

    function getLOOKeeper(address gk) public view returns (ILOOKeeper) {
        return ILOOKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.LOOK)));
    }

    function getROIKeeper(address gk) public view returns (IROIKeeper) {
        return IROIKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROIK)));
    }

    function getAccountant(address gk) public view returns (IAccountant) {
        return IAccountant(IGeneralKeeper(gk).getKeeper(uint8(Keepers.Accountant)));
    }

    function getRORKeeper(address gk) public view returns (IRORKeeper) {
        return IRORKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.RORK)));
    }

}
