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

import "../books/cashier/ICashier.sol";
import "../books/roa/IInvestmentAgreement.sol";
import "../books/roo/IRegisterOfOptions.sol";
import "../books/ros/IRegisterOfShares.sol";

import "../../lib/InterfacesHub.sol";
import "../../lib/MotionsRepo.sol";
import "../../lib/SwapsRepo.sol";

/// @title IROOKeeper
/// @notice Interface for option swaps and related transfers.
interface IROOKeeper {

    // #################
    // ##  ROOKeeper  ##
    // #################

    /// @notice Emitted when an option swap is paid off.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfSwap Swap sequence.
    /// @param from Payer address.
    /// @param to Recipient address.
    /// @param valueOfDeal Deal value.
    event PayOffSwap(
        uint seqOfOpt, uint seqOfSwap, address indexed from, 
        address indexed to, uint indexed valueOfDeal
    );

    /// @notice Emitted when a rejected deal swap is paid off.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfSwap Swap sequence.
    /// @param from Payer address.
    /// @param to Recipient address.
    /// @param valueOfDeal Deal value.
    event PayOffRejectedDeal(
        address ia, uint seqOfDeal, uint seqOfSwap, address indexed from, 
        address indexed to, uint indexed valueOfDeal
    );

    /// @notice Update oracle data for an option.
    /// @param seqOfOpt Option sequence.
    /// @param d1 Data slot 1.
    /// @param d2 Data slot 2.
    /// @param d3 Data slot 3.
    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    /// @notice Execute an option.
    /// @param seqOfOpt Option sequence.
    function execOption(uint256 seqOfOpt)external;

    /// @notice Create a swap for an option.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfTarget Target share sequence.
    /// @param paidOfTarget Paid target amount.
    /// @param seqOfPledge Pledge share sequence.
    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge
    ) external;

    /// @notice Pay off an option swap.
    /// @param auth Transfer authorization.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfSwap Swap sequence.
    /// @param to Recipient address.
    function payOffSwap(
        ICashier.TransferAuth memory auth, uint256 seqOfOpt, uint256 seqOfSwap, address to
    ) external;

    /// @notice Terminate an option swap.
    /// @param seqOfOpt Option sequence.
    /// @param seqOfSwap Swap sequence.
    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external;

    // ==== Swap ====

    // /// @notice Request to buy a target share via swap.
    // /// @param ia Investment agreement address.
    // /// @param seqOfDeal Deal sequence.
    // /// @param paidOfTarget Paid target amount.
    // /// @param seqOfPledge Pledge share sequence.
    // function requestToBuy(
    //     address ia,
    //     uint seqOfDeal,
    //     uint paidOfTarget,
    //     uint seqOfPledge
    // ) external;

    // /// @notice Pay off a rejected deal swap.
    // /// @param auth Transfer authorization.
    // /// @param ia Investment agreement address.
    // /// @param seqOfDeal Deal sequence.
    // /// @param seqOfSwap Swap sequence.
    // /// @param to Recipient address.
    // function payOffRejectedDeal(
    //     ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, 
    //     uint seqOfSwap, address to
    // ) external;

    // /// @notice Pick up pledged share for a rejected deal.
    // /// @param ia Investment agreement address.
    // /// @param seqOfDeal Deal sequence.
    // /// @param seqOfSwap Swap sequence.
    // function pickupPledgedShare(
    //     address ia,
    //     uint seqOfDeal,
    //     uint seqOfSwap
    // ) external;

}
