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

import "../comps/modules/IBaseKeeper.sol";

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

library BooksRepo {

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
    
    //##################
    //##   read I/O   ##
    //##################

    // ==== Books ====

    function getROC(IBaseKeeper gk) public view returns (IRegisterOfConstitution) {
        return IRegisterOfConstitution(gk.getBook(uint8(Books.ROC)));
    }

    function getSHA(IBaseKeeper gk) public view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(getROC(gk).pointer());
    }

    function getROD(IBaseKeeper gk) public view returns (IRegisterOfDirectors) {
        return IRegisterOfDirectors(gk.getBook(uint8(Books.ROD)));
    }

    function getBMM(IBaseKeeper gk) public view returns (IMeetingMinutes) {
        return IMeetingMinutes(gk.getBook(uint8(Books.BMM)));
    }

    function getROM(IBaseKeeper gk) public view returns (IRegisterOfMembers) {
        return IRegisterOfMembers(gk.getBook(uint8(Books.ROM)));
    }

    function getGMM(IBaseKeeper gk) public view returns (IMeetingMinutes) {
        return IMeetingMinutes(gk.getBook(uint8(Books.GMM)));
    }

    function getROA(IBaseKeeper gk) public view returns (IRegisterOfAgreements) {
        return IRegisterOfAgreements(gk.getBook(uint8(Books.ROA)));
    }

    function getROO(IBaseKeeper gk) public view returns (IRegisterOfOptions) {
        return IRegisterOfOptions(gk.getBook(uint8(Books.ROO)));
    }

    function getROP(IBaseKeeper gk) public view returns (IRegisterOfPledges) {
        return IRegisterOfPledges(gk.getBook(uint8(Books.ROP)));
    }

    function getROS(IBaseKeeper gk) public view returns (IRegisterOfShares) {
        return IRegisterOfShares(gk.getBook(uint8(Books.ROS)));
    }

    function getLOO(IBaseKeeper gk) public view returns (IListOfOrders) {
        return IListOfOrders(gk.getBook(uint8(Books.LOO)));
    }

    function getROI(IBaseKeeper gk) public view returns (IRegisterOfInvestors) {
        return IRegisterOfInvestors(gk.getBook(uint8(Books.ROI)));
    }

    function getBank(IBaseKeeper gk) public view returns (IUSDC) {
        return IUSDC(gk.getBook(uint8(Books.Bank)));
    }

    function getCashier(IBaseKeeper gk) public view returns (ICashier) {
        return ICashier(gk.getBook(uint8(Books.Cashier)));
    }

    function getROR(IBaseKeeper gk) public view returns (IRegisterOfRedemptions) {
        return IRegisterOfRedemptions(gk.getBook(uint8(Books.ROR)));
    }

    // ==== Keepers ====

    function getROCKeeper(IBaseKeeper gk) public view returns (IROCKeeper) {
        return IROCKeeper(gk.getKeeper(uint8(Keepers.ROCK)));
    }

    function getRODKeeper(IBaseKeeper gk) public view returns (IRODKeeper) {
        return IRODKeeper(gk.getKeeper(uint8(Keepers.RODK)));
    }

    function getBMMKeeper(IBaseKeeper gk) public view returns (IBMMKeeper) {
        return IBMMKeeper(gk.getKeeper(uint8(Keepers.BMMK)));
    }

    function getROMKeeper(IBaseKeeper gk) public view returns (IROMKeeper) {
        return IROMKeeper(gk.getKeeper(uint8(Keepers.ROMK)));
    }

    function getGMMKeeper(IBaseKeeper gk) public view returns (IGMMKeeper) {
        return IGMMKeeper(gk.getKeeper(uint8(Keepers.GMMK)));
    }

    function getROAKeeper(IBaseKeeper gk) public view returns (IROAKeeper) {
        return IROAKeeper(gk.getKeeper(uint8(Keepers.ROAK)));
    }

    function getROOKeeper(IBaseKeeper gk) public view returns (IROOKeeper) {
        return IROOKeeper(gk.getKeeper(uint8(Keepers.ROOK)));
    }

    function getROPKeeper(IBaseKeeper gk) public view returns (IROPKeeper) {
        return IROPKeeper(gk.getKeeper(uint8(Keepers.ROPK)));
    }

    function getSHAKeeper(IBaseKeeper gk) public view returns (ISHAKeeper) {
        return ISHAKeeper(gk.getKeeper(uint8(Keepers.SHAK)));
    }

    function getLOOKeeper(IBaseKeeper gk) public view returns (ILOOKeeper) {
        return ILOOKeeper(gk.getKeeper(uint8(Keepers.LOOK)));
    }

    function getROIKeeper(IBaseKeeper gk) public view returns (IROIKeeper) {
        return IROIKeeper(gk.getKeeper(uint8(Keepers.ROIK)));
    }

    function getAccountant(IBaseKeeper gk) public view returns (IAccountant) {
        return IAccountant(gk.getKeeper(uint8(Keepers.Accountant)));
    }

    function getRORKeeper(IBaseKeeper gk) public view returns (IRORKeeper) {
        return IRORKeeper(gk.getKeeper(uint8(Keepers.RORK)));
    }

}
