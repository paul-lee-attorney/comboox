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

/// @title IAccountant
/// @notice Interface for class initialization, distributions, and fund transfers.
interface IAccountant {

    /// @notice Initialize waterfall class data.
    /// @param class Share class id.
    function initClass(uint class) external;

    /// @notice Distribute profits by distribution rule.
    /// @param amt Amount to distribute.
    /// @param expireDate Distribution expiry timestamp.
    /// @param seqOfDR Distribution rule sequence.
    /// @param seqOfMotion Motion sequence.
    function distrProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion
    ) external;

    /// @notice Distribute income to fund manager and recipients.
    /// @param amt Amount to distribute.
    /// @param expireDate Distribution expiry timestamp.
    /// @param seqOfDR Distribution rule sequence.
    /// @param fundManager Fund manager user number.
    /// @param seqOfMotion Motion sequence.
    function distrIncome(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint fundManager,
        uint seqOfMotion
    ) external;

    /// @notice Transfer funds from treasury to a recipient.
    /// @param fromBMM True if triggered by BMM, false for GMM.
    /// @param to Recipient address.
    /// @param isCBP True if paid in CBP, false for USDC.
    /// @param amt Amount to transfer.
    /// @param expireDate Transfer expiry timestamp.
    /// @param seqOfMotion Motion sequence.
    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion
    ) external;

}
