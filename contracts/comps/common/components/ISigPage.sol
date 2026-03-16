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

import "../../../lib/utils/ArrayUtils.sol";
import "../../../openzeppelin/utils/structs/EnumerableSet.sol";
import "../../../lib/books/SigsRepo.sol";

/// @title ISigPage
/// @notice Interface for managing signature pages and signing status.
interface ISigPage {

    /// @notice Emitted when the document is circulated.
    event CirculateDoc();

    //##################
    //##   Write I/O  ##
    //##################

    /// @notice Circulate the document and start timing.
    function circulateDoc() external;

    /// @notice Set signing and closing windows (in days).
    /// @param initPage True for the initial page, false for the secondary page.
    /// @param signingDays Signing window in days.
    /// @param closingDays Closing window in days.
    function setTiming(bool initPage, uint signingDays, uint closingDays) external;

    /// @notice Add a blank (party + deal) to a page.
    /// @param initPage True for the initial page, false for the secondary page.
    /// @param beBuyer True if the party is a buyer.
    /// @param seqOfDeal Deal sequence number.
    /// @param acct Party account id.
    function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256 acct)
        external;

    /// @notice Remove a blank from a page.
    /// @param initPage True for the initial page, false for the secondary page.
    /// @param seqOfDeal Deal sequence number.
    /// @param acct Party account id.
    function removeBlank(bool initPage, uint256 seqOfDeal, uint256 acct)
        external;

    /// @notice Record a signature for a party.
    /// @param initPage True for the initial page, false for the secondary page.
    /// @param caller Party account id.
    /// @param sigHash Signature hash.
    function signDoc(bool initPage, uint256 caller, bytes32 sigHash) 
        external;    

    /// @notice Register a signature with a provided date.
    /// @param signer Party account id.
    /// @param sigDate Signature timestamp.
    /// @param sigHash Signature hash.
    function regSig(uint256 signer, uint sigDate, bytes32 sigHash)
        external returns(bool flag);

    //##################
    //##   read I/O   ##
    //##################

    /// @notice Get base parameters of a page.
    /// @param initPage True for the initial page, false for the secondary page.
    function getParasOfPage(bool initPage) external view 
        returns (SigsRepo.Signature memory);

    /// @notice Check whether the document has been circulated.
    function circulated() external view returns(bool);

    /// @notice Check whether all required signatures are collected.
    function established() external view
        returns (bool flag);

    /// @notice Get circulate date.
    function getCirculateDate() external view returns(uint48);

    /// @notice Get signing window in days.
    function getSigningDays() external view returns(uint16);

    /// @notice Get closing window in days.
    function getClosingDays() external view returns(uint16);

    /// @notice Get signature deadline timestamp.
    function getSigDeadline() external view returns(uint48);

    /// @notice Get closing deadline timestamp.
    function getClosingDeadline() external view returns(uint48);

    /// @notice Check whether an account is a buyer.
    /// @param initPage True for the initial page, false for the secondary page.
    /// @param acct Party account id.
    function isBuyer(bool initPage, uint256 acct)
        external view returns(bool flag);

    /// @notice Check whether an account is a seller.
    /// @param initPage True for the initial page, false for the secondary page.
    /// @param acct Party account id.
    function isSeller(bool initPage, uint256 acct)
        external view returns(bool flag);

    /// @notice Check whether an account is a party on any page.
    /// @param acct Party account id.
    function isParty(uint256 acct)
        external view returns(bool flag);

    /// @notice Check whether an account signed the initial page.
    /// @param acct Party account id.
    function isInitSigner(uint256 acct)
        external view returns (bool flag);


    /// @notice Check whether an account signed any page.
    /// @param acct Party account id.
    function isSigner(uint256 acct)
        external view returns (bool flag);

    /// @notice Get buyers of a page.
    /// @param initPage True for the initial page, false for the secondary page.
    function getBuyers(bool initPage)
        external view returns (uint256[] memory buyers);

    /// @notice Get sellers of a page.
    /// @param initPage True for the initial page, false for the secondary page.
    function getSellers(bool initPage)
        external view returns (uint256[] memory sellers);

    /// @notice Get all parties across pages.
    function getParties() external view
        returns (uint256[] memory parties);

    /// @notice Get signature data of a party.
    /// @param initParty True for the initial page, false for the secondary page.
    /// @param acct Party account id.
    function getSigOfParty(bool initParty, uint256 acct) external view
        returns (
            uint256[] memory seqOfDeals, 
            SigsRepo.Signature memory sig,
            bytes32 sigHash
        );

    /// @notice Get signatures for a page by buyers and sellers.
    /// @param initPage True for the initial page, false for the secondary page.
    function getSigsOfPage(bool initPage) external view
        returns (
            SigsRepo.Signature[] memory sigsOfBuyer, 
            SigsRepo.Signature[] memory sigsOfSeller
        );
}
