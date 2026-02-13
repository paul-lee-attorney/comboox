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

import "../center/IRegCenter.sol";

import "../comps/IGeneralKeeper.sol";

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
import "../center/utils/MockUSDC/IUSDC.sol";
import "../comps/books/cashier/ICashier.sol";
import "../comps/books/ror/IRegisterOfRedemptions.sol";

import "../comps/books/roc/IShareholdersAgreement.sol";
import "../comps/books/roc/terms/IAntiDilution.sol";
import "../comps/books/roc/terms/IAlongs.sol";

import "../comps/books/roa/IInvestmentAgreement.sol";

import "../comps/common/components/IFilesFolder.sol";
import "../comps/common/components/ISigPage.sol";

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

import "../comps/common/access/IDraftControl.sol";
import "../comps/common/access/IAccessControl.sol";
import "../center/access/IOwnable.sol";

library InterfacesHub {

    /// @notice Keeper type identifiers.
    enum Keepers {
        ZeroPoint,
        ROCK,       //1
        RODK,       
        BMMK,       
        ROMK,       
        GMMK,       //5 
        ROAK,       
        ROOK,       
        ROPK,       
        SHAK,       
        LOOK,       //10
        ROIK,
        Accountant,
        Blank_1,
        Blank_2,
        Blank_3,    //15
        RORK
    }

    /// @notice Book type identifiers.
    enum Books {
        ZeroPoint,
        ROC,        //1
        ROD,
        BMM,
        ROM,
        GMM,        //5
        ROA,
        ROO,
        ROP,
        ROS,
        LOO,        //10
        ROI,
        Bank,
        Blank_1,
        Blank_2,
        Cashier,    //15
        ROR
    }

    // ==== RegCenter ====
    
    /// @notice Cast address to RegCenter interface.
    /// @param rc RegCenter address (non-zero).
    function getRC(address rc) public pure returns(IRegCenter) {
        return IRegCenter(rc);
    }

    // ==== GeneralKeeper ====

    /// @notice Cast address to GeneralKeeper interface.
    /// @param gk GeneralKeeper address (non-zero).
    function getGK(address gk) public pure returns (IGeneralKeeper) {
        return IGeneralKeeper(gk);
    }

    // ==== Books ====
    /// @notice Get ROC (Register of Constitution).
    /// @param gk GeneralKeeper address.
    function getROC(address gk) public view returns (IRegisterOfConstitution) {
        return IRegisterOfConstitution(IGeneralKeeper(gk).getBook(uint8(Books.ROC)));
    }

    /// @notice Get Shareholders Agreement (current pointer).
    /// @param gk GeneralKeeper address.
    function getSHA(address gk) public view returns (IShareholdersAgreement) {
        return IShareholdersAgreement(getROC(gk).pointer());
    }

    /// @notice Get Register of Directors.
    /// @param gk GeneralKeeper address.
    function getROD(address gk) public view returns (IRegisterOfDirectors) {
        return IRegisterOfDirectors(IGeneralKeeper(gk).getBook(uint8(Books.ROD)));
    }

    /// @notice Get Board Meeting Minutes.
    /// @param gk GeneralKeeper address.
    function getBMM(address gk) public view returns (IMeetingMinutes) {
        return IMeetingMinutes(IGeneralKeeper(gk).getBook(uint8(Books.BMM)));
    }

    /// @notice Get Register of Members.
    /// @param gk GeneralKeeper address.
    function getROM(address gk) public view returns (IRegisterOfMembers) {
        return IRegisterOfMembers(IGeneralKeeper(gk).getBook(uint8(Books.ROM)));
    }

    /// @notice Get General Meeting Minutes.
    /// @param gk GeneralKeeper address.
    function getGMM(address gk) public view returns (IMeetingMinutes) {
        return IMeetingMinutes(IGeneralKeeper(gk).getBook(uint8(Books.GMM)));
    }

    /// @notice Get Register of Agreements.
    /// @param gk GeneralKeeper address.
    function getROA(address gk) public view returns (IRegisterOfAgreements) {
        return IRegisterOfAgreements(IGeneralKeeper(gk).getBook(uint8(Books.ROA)));
    }

    /// @notice Get Register of Options.
    /// @param gk GeneralKeeper address.
    function getROO(address gk) public view returns (IRegisterOfOptions) {
        return IRegisterOfOptions(IGeneralKeeper(gk).getBook(uint8(Books.ROO)));
    }

    /// @notice Get Register of Pledges.
    /// @param gk GeneralKeeper address.
    function getROP(address gk) public view returns (IRegisterOfPledges) {
        return IRegisterOfPledges(IGeneralKeeper(gk).getBook(uint8(Books.ROP)));
    }

    /// @notice Get Register of Shares.
    /// @param gk GeneralKeeper address.
    function getROS(address gk) public view returns (IRegisterOfShares) {
        return IRegisterOfShares(IGeneralKeeper(gk).getBook(uint8(Books.ROS)));
    }

    /// @notice Get List of Orders.
    /// @param gk GeneralKeeper address.
    function getLOO(address gk) public view returns (IListOfOrders) {
        return IListOfOrders(IGeneralKeeper(gk).getBook(uint8(Books.LOO)));
    }

    /// @notice Get Register of Investors.
    /// @param gk GeneralKeeper address.
    function getROI(address gk) public view returns (IRegisterOfInvestors) {
        return IRegisterOfInvestors(IGeneralKeeper(gk).getBook(uint8(Books.ROI)));
    }

    /// @notice Get USDC bank contract.
    /// @param gk GeneralKeeper address.
    function getBank(address gk) public view returns (IUSDC) {
        return IUSDC(IGeneralKeeper(gk).getBook(uint8(Books.Bank)));
    }

    /// @notice Get Cashier contract.
    /// @param gk GeneralKeeper address.
    function getCashier(address gk) public view returns (ICashier) {
        return ICashier(IGeneralKeeper(gk).getBook(uint8(Books.Cashier)));
    }

    /// @notice Get Register of Redemptions.
    /// @param gk GeneralKeeper address.
    function getROR(address gk) public view returns (IRegisterOfRedemptions) {
        return IRegisterOfRedemptions(IGeneralKeeper(gk).getBook(uint8(Books.ROR)));
    }

    // ==== Keepers ====

    /// @notice Get ROC Keeper.
    /// @param gk GeneralKeeper address.
    function getROCKeeper(address gk) public view returns (IROCKeeper) {
        return IROCKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROCK)));
    }

    /// @notice Get ROD Keeper.
    /// @param gk GeneralKeeper address.
    function getRODKeeper(address gk) public view returns (IRODKeeper) {
        return IRODKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.RODK)));
    }

    /// @notice Get BMM Keeper.
    /// @param gk GeneralKeeper address.
    function getBMMKeeper(address gk) public view returns (IBMMKeeper) {
        return IBMMKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.BMMK)));
    }

    /// @notice Get ROM Keeper.
    /// @param gk GeneralKeeper address.
    function getROMKeeper(address gk) public view returns (IROMKeeper) {
        return IROMKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROMK)));
    }

    /// @notice Get GMM Keeper.
    /// @param gk GeneralKeeper address.
    function getGMMKeeper(address gk) public view returns (IGMMKeeper) {
        return IGMMKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.GMMK)));
    }

    /// @notice Get ROA Keeper.
    /// @param gk GeneralKeeper address.
    function getROAKeeper(address gk) public view returns (IROAKeeper) {
        return IROAKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROAK)));
    }

    /// @notice Get ROO Keeper.
    /// @param gk GeneralKeeper address.
    function getROOKeeper(address gk) public view returns (IROOKeeper) {
        return IROOKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROOK)));
    }

    /// @notice Get ROP Keeper.
    /// @param gk GeneralKeeper address.
    function getROPKeeper(address gk) public view returns (IROPKeeper) {
        return IROPKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROPK)));
    }

    /// @notice Get SHA Keeper.
    /// @param gk GeneralKeeper address.
    function getSHAKeeper(address gk) public view returns (ISHAKeeper) {
        return ISHAKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.SHAK)));
    }

    /// @notice Get LOO Keeper.
    /// @param gk GeneralKeeper address.
    function getLOOKeeper(address gk) public view returns (ILOOKeeper) {
        return ILOOKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.LOOK)));
    }

    /// @notice Get ROI Keeper.
    /// @param gk GeneralKeeper address.
    function getROIKeeper(address gk) public view returns (IROIKeeper) {
        return IROIKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.ROIK)));
    }

    /// @notice Get Accountant Keeper.
    /// @param gk GeneralKeeper address.
    function getAccountant(address gk) public view returns (IAccountant) {
        return IAccountant(IGeneralKeeper(gk).getKeeper(uint8(Keepers.Accountant)));
    }

    /// @notice Get ROR Keeper.
    /// @param gk GeneralKeeper address.
    function getRORKeeper(address gk) public view returns (IRORKeeper) {
        return IRORKeeper(IGeneralKeeper(gk).getKeeper(uint8(Keepers.RORK)));
    }

}
