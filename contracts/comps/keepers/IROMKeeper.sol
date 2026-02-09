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

import "../books/ros/IRegisterOfShares.sol";
import "../books/cashier/ICashier.sol";

import "../../lib/InterfacesHub.sol";
import "../../lib/SharesRepo.sol";

/// @title IROMKeeper
/// @notice Interface for member/pay-in related actions.
interface IROMKeeper {

    /// @notice Emitted when capital is paid in and recorded with deal value.
    /// @param seqOfShare Share sequence.
    /// @param amt Paid-in amount.
    /// @param valueOfDeal Deal value.
    event PayInCapital(uint indexed seqOfShare, uint indexed amt, uint indexed valueOfDeal);

    // #################
    // ##   Write IO  ##
    // #################

    // ==== BOS funcs ====

    /// @notice Set maximum number of members.
    /// @param max Max member count.
    function setMaxQtyOfMembers(uint max) external;

    /// @notice Set a pay-in amount with hash lock.
    /// @param seqOfShare Share sequence.
    /// @param amt Amount to pay in.
    /// @param expireDate Lock expiry timestamp.
    /// @param hashLock Hash lock.
    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external;

    /// @notice Request paid-in capital release by hash key.
    /// @param hashLock Hash lock.
    /// @param hashKey Hash key.
    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    /// @notice Withdraw locked pay-in amount.
    /// @param hashLock Hash lock.
    /// @param seqOfShare Share sequence.
    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;

    /// @notice Pay in capital for a share using transfer authorization.
    /// @param auth Transfer authorization.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param msgSender Caller address.
    function payInCapital(
        ICashier.TransferAuth memory auth,
        uint seqOfShare, 
        uint paid,
        address msgSender
    ) external;

    /// @notice Decrease capital for a share.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount decreased.
    /// @param par Par amount decreased.
    /// @param amt Amount to deduct.
    function decreaseCapital(
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint amt
    ) external;

    /// @notice Update paid-in deadline for a share.
    /// @param seqOfShare Share sequence.
    /// @param line New deadline timestamp.
    function updatePaidInDeadline(uint256 seqOfShare, uint line) external;
}
