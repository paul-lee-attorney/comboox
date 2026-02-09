// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "../books/roi/IRegisterOfInvestors.sol";
import "../books/ros/IRegisterOfShares.sol";

import "../../lib/RulesParser.sol";
import "../../lib/InterfacesHub.sol";

/// @title IROIKeeper
/// @notice Interface for investor compliance actions and LOO pause.
interface IROIKeeper {

    //###############
    //##   Write   ##
    //###############

    // ==== Pause LOO ====

    /// @notice Pause LOO operations.
    /// @param seqOfLR Listing rule sequence.
    /// @param msgSender Caller address.
    function pause(uint seqOfLR, address msgSender) external;

    /// @notice Unpause LOO operations.
    /// @param seqOfLR Listing rule sequence.
    /// @param msgSender Caller address.
    function unPause(uint seqOfLR, address msgSender) external;

    // ==== Freeze Share ====

    /// @notice Freeze a share for compliance.
    /// @param seqOfLR Listing rule sequence.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param msgSender Caller address.
    /// @param hashOrder Related order hash.
    function freezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address msgSender, bytes32 hashOrder
    ) external;

    /// @notice Unfreeze a share.
    /// @param seqOfLR Listing rule sequence.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param msgSender Caller address.
    /// @param hashOrder Related order hash.
    function unfreezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address msgSender, bytes32 hashOrder
    ) external;

    /// @notice Force transfer a frozen share.
    /// @param seqOfLR Listing rule sequence.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param addrTo Recipient address.
    /// @param msgSender Caller address.
    /// @param hashOrder Related order hash.
    function forceTransfer(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address addrTo, address msgSender, bytes32 hashOrder
    ) external;

    // ==== Investor ====

    /// @notice Register an investor.
    /// @param msgSender Caller address.
    /// @param bKey Investor key address.
    /// @param groupRep Group representative user number.
    /// @param idHash Investor id hash.
    function regInvestor(address msgSender, address bKey, uint groupRep, bytes32 idHash) external;

    /// @notice Approve an investor.
    /// @param userNo Investor user number.
    /// @param msgSender Caller address.
    /// @param seqOfLR Listing rule sequence.
    function approveInvestor(uint userNo, address msgSender,uint seqOfLR) external;

    /// @notice Revoke an investor approval.
    /// @param userNo Investor user number.
    /// @param msgSender Caller address.
    /// @param seqOfLR Listing rule sequence.
    function revokeInvestor(uint userNo,address msgSender,uint seqOfLR) external;

}
