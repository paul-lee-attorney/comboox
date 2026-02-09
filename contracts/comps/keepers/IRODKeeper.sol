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

import "../common/components/IMeetingMinutes.sol";

import "../../lib/InterfacesHub.sol";
import "../../lib/MotionsRepo.sol";

/// @title IRODKeeper
/// @notice Interface for director and officer appointment actions.
interface IRODKeeper {

    // ==== Directors ====

    /// @notice Take a director seat after motion approval.
    /// @param seqOfMotion Motion sequence.
    /// @param seqOfPos Position sequence.
    /// @param msgSender Caller address.
    function takeSeat(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        address msgSender 
    ) external;

    /// @notice Remove a director after motion approval.
    /// @param seqOfMotion Motion sequence.
    /// @param seqOfPos Position sequence.
    /// @param msgSender Caller address.
    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        address msgSender
    ) external;

    // ==== Officers ====

    /// @notice Take an officer position after motion approval.
    /// @param seqOfMotion Motion sequence.
    /// @param seqOfPos Position sequence.
    /// @param msgSender Caller address.
    function takePosition(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        address msgSender 
    ) external;

    /// @notice Remove an officer after motion approval.
    /// @param seqOfMotion Motion sequence.
    /// @param seqOfPos Position sequence.
    /// @param msgSender Caller address.
    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        address msgSender
    ) external;

    // ==== Quit ====

    /// @notice Quit an officer position.
    /// @param seqOfPos Position sequence.
    /// @param msgSender Caller address.
    function quitPosition(uint256 seqOfPos, address msgSender) external;

}
