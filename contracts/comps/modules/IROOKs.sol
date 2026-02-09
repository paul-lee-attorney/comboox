// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
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

pragma solidity ^0.8.8;

import "../keepers/IROOKeeper.sol";

/// @title IROOKs
/// @notice Module interface for ROOKeeper option and swap workflows.
/// @dev Covers oracle updates, option execution, swaps, and post-deal actions.
interface IROOKs {

    // #################
    // ##  ROOKeeper  ##
    // #################

    /// @notice Update oracle values for an option.
    /// @param seqOfOpt Option sequence id (expected > 0).
    /// @param d1 Oracle data item 1 (uint, implementation-defined range).
    /// @param d2 Oracle data item 2 (uint, implementation-defined range).
    /// @param d3 Oracle data item 3 (uint, implementation-defined range).
    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    /// @notice Execute an option by its sequence id.
    /// @param seqOfOpt Option sequence id (expected > 0).
    function execOption(uint256 seqOfOpt) external;

    /// @notice Create a swap record linked to an option and a target.
    /// @param seqOfOpt Option sequence id (expected > 0).
    /// @param seqOfTarget Target share sequence id (expected > 0).
    /// @param paidOfTarget Paid amount/quantity for target (uint, expected > 0).
    /// @param seqOfPledge Pledge sequence id (expected > 0).
    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge
    ) external;

    /// @notice Pay off a swap using authorized USD transfer.
    /// @param auth Transfer authorization (must be valid for Cashier).
    /// @param seqOfOpt Option sequence id (expected > 0).
    /// @param seqOfSwap Swap sequence id (expected > 0).
    /// @param to Recipient address (non-zero).
    function payOffSwap(
        ICashier.TransferAuth memory auth, uint256 seqOfOpt, uint256 seqOfSwap, address to
    ) external;

    /// @notice Terminate a swap.
    /// @param seqOfOpt Option sequence id (expected > 0).
    /// @param seqOfSwap Swap sequence id (expected > 0).
    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external;

    /// @notice Request to buy the target in an IA deal.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param paidOfTarget Paid amount/quantity for target (uint, expected > 0).
    /// @param seqOfPledge Pledge sequence id (expected > 0).
    function requestToBuy(address ia, uint seqOfDeal, uint paidOfTarget, uint seqOfPledge) external;

    /// @notice Pay off a rejected deal and settle a related swap.
    /// @param auth Transfer authorization (must be valid for Cashier).
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param seqOfSwap Swap sequence id (expected > 0).
    /// @param to Recipient address (non-zero).
    function payOffRejectedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, uint seqOfSwap, address to
    ) external;

    /// @notice Pick up pledged shares after swap resolution.
    /// @param ia IA contract address (non-zero).
    /// @param seqOfDeal Deal sequence id (expected > 0).
    /// @param seqOfSwap Swap sequence id (expected > 0).
    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap
    ) external;

}
