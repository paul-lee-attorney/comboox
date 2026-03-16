// SPDX-License-Identifier: UNLICENSED

/* *
 *
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

import "../../../lib/books/RedemptionsRepo.sol";

/// @title IRegisterOfRedemptions
/// @notice Interface for redemption requests, NAV price, and class packs.
interface IRegisterOfRedemptions {

    /// @notice Emitted when a redeemable class is added.
    /// @param class Share class id.
    event AddRedeemableClass(uint indexed class);

    /// @notice Emitted when a redeemable class is removed.
    /// @param class Share class id.
    event RemoveRedeemableClass(uint indexed class);

    /// @notice Emitted when NAV price is updated.
    /// @param class Share class id.
    /// @param price NAV price.
    event UpdateNavPrice(uint indexed class, uint indexed price);

    /// @notice Emitted when a redemption request is submitted.
    /// @param class Share class id.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount requested.
    /// @param value Redemption value.
    event RequestForRedemption(uint class, uint indexed seqOfShare, uint indexed paid, uint indexed value);

    /// @notice Emitted when a class pack is redeemed.
    /// @param class Share class id.
    /// @param sumOfPaid Total paid amount redeemed.
    /// @param totalValue Total redemption value.
    event RedeemClass(uint indexed class, uint indexed sumOfPaid, uint indexed totalValue);

    /// @notice Emitted when a share is redeemed.
    /// @param shareholder Shareholder user number.
    /// @param class Share class id.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount redeemed.
    /// @param value Redemption value.
    event RedeemShare(uint shareholder, uint indexed class, uint seqOfShare, uint indexed paid, uint indexed value);

    //###############
    //##   Write   ##
    //###############

    // ==== Config ====

    /// @notice Add a redeemable share class.
    /// @param class Share class id.
    function addRedeemableClass(uint class) external;

    /// @notice Remove a redeemable share class.
    /// @param class Share class id.
    function removeRedeemableClass(uint class) external;

    /// @notice Update NAV price for a class.
    /// @param class Share class id.
    /// @param price NAV price.
    function updateNavPrice(uint class, uint price) external;

    /// @notice Create a redemption request for a share.
    /// @param caller Caller user number.
    /// @param class Share class id.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount to redeem.
    /// @return request Request record.
    function requestForRedemption(
        uint caller, 
        uint class, 
        uint seqOfShare, 
        uint paid
    ) external returns(
        RedemptionsRepo.Request memory request
    );

    /// @notice Redeem a pack for a class.
    /// @param class Share class id.
    /// @param seqOfPack Pack sequence.
    /// @return list Requests in pack.
    /// @return info Pack info.
    function redeem(uint class, uint seqOfPack) external returns(
        RedemptionsRepo.Request[] memory list, RedemptionsRepo.Request memory info
    );

    //##################
    //##   Read I/O   ##
    //##################

    /// @notice Check whether a class is redeemable.
    /// @param class Share class id.
    /// @return True if redeemable.
    function isRedeemable(uint class) external view returns(bool);

    /// @notice Get list of redeemable classes.
    /// @return list Class ids.
    function getClassesList() external view returns(uint[] memory list);

    // ==== Class ====

    /// @notice Get redemption info for a class.
    /// @param class Share class id.
    /// @return info Class info.
    function getInfoOfClass(uint class) external view returns(
        RedemptionsRepo.Request memory info
    );

    /// @notice Get packs list for a class.
    /// @param class Share class id.
    /// @return list Pack ids.
    function getPacksList(uint class) external view returns(uint[] memory list); 

    // ==== Pack ====

    /// @notice Get pack info.
    /// @param class Share class id.
    /// @param seqOfPack Pack sequence.
    /// @return info Pack info.
    function getInfoOfPack(uint class, uint seqOfPack) external view returns(
        RedemptionsRepo.Request memory info    
    );

    /// @notice Get shares list in a pack.
    /// @param class Share class id.
    /// @param seqOfPack Pack sequence.
    /// @return list Share sequences.
    function getSharesList(uint class, uint seqOfPack) external view returns(uint[] memory list);

    /// @notice Get redemption request for a share in a pack.
    /// @param class Share class id.
    /// @param seqOfPack Pack sequence.
    /// @param seqOfShare Share sequence.
    /// @return request Request record.
    function getRequest(uint class, uint seqOfPack, uint seqOfShare) external view returns(
        RedemptionsRepo.Request memory request
    );

    /// @notice Get all requests in a pack.
    /// @param class Share class id.
    /// @param seqOfPack Pack sequence.
    /// @return requests Request list.
    function getRequests(uint class, uint seqOfPack) external view returns(
        RedemptionsRepo.Request[] memory requests
    );
}
