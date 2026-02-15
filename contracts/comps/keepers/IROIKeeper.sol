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

pragma solidity ^0.8.24;

/// @title IROIKeeper
/// @notice Interface for investor compliance actions and LOO pause.
interface IROIKeeper {

    //###############
    //##   Write   ##
    //###############

    // ==== Pause LOO ====

    /// @notice Pause LOO operations.
    /// @param seqOfLR Listing rule sequence.
    function pause(uint seqOfLR) external;

    /// @notice Unpause LOO operations.
    /// @param seqOfLR Listing rule sequence.
    function unPause(uint seqOfLR) external;

    // ==== Freeze Share ====

    /// @notice Freeze a share for compliance.
    /// @param seqOfLR Listing rule sequence.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param hashOrder Related order hash.
    function freezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        bytes32 hashOrder
    ) external;

    /// @notice Unfreeze a share.
    /// @param seqOfLR Listing rule sequence.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param hashOrder Related order hash.
    function unfreezeShare(
        uint seqOfLR, uint seqOfShare, uint paid, 
        bytes32 hashOrder
    ) external;

    /// @notice Force transfer a frozen share.
    /// @param seqOfLR Listing rule sequence.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param addrTo Recipient address.
    /// @param hashOrder Related order hash.
    function forceTransfer(
        uint seqOfLR, uint seqOfShare, uint paid, 
        address addrTo, bytes32 hashOrder
    ) external;

    // ==== Investor ====

    /// @notice Register an investor.
    /// @param bKey Investor key address.
    /// @param groupRep Group representative user number.
    /// @param idHash Investor id hash.
    function regInvestor(address bKey, uint groupRep, bytes32 idHash) external;

    /// @notice Approve an investor.
    /// @param userNo Investor user number.
    /// @param seqOfLR Listing rule sequence.
    function approveInvestor(uint userNo, uint seqOfLR) external;

    /// @notice Revoke an investor approval.
    /// @param userNo Investor user number.
    /// @param seqOfLR Listing rule sequence.
    function revokeInvestor(uint userNo, uint seqOfLR) external;

}
