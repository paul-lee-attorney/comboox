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

/// @title IAccessControl
/// @notice Access control interface for keeper-based upgrade and key management.
/// @dev Used by router/keeper contracts to regain control over subordinate contracts.
interface IAccessControl {

    // ##################
    // ##   Event      ##
    // ##################

    /// @notice Emitted when direct keeper is updated.
    /// @param keeper New direct keeper address.
    event SetDirectKeeper(address indexed keeper);

    // ##################
    // ##    Write     ##
    // ##################

    // ==== UUPS Upgradeability ====
    
    /// @notice Initialize owner, registry center, and keeper addresses.
    /// @param owner Owner address.
    /// @param regCenter Registry center address.
    /// @param directKeeper Direct keeper address.
    /// @param generalKeeper General keeper address.
    function initialize(
        address owner, 
        address regCenter, 
        address directKeeper, 
        address generalKeeper
    ) external;

    function initKeepers(
        address directKeeper, 
        address generalKeeper
    ) external;

    /// @notice Upgrade implementation and register the upgrade in RegCenter.
    /// @param newImplementation New implementation address.
    function upgradeDocTo(address newImplementation) external;

    // ==== Keeper Control ====


    /// @notice Set direct keeper address.
    /// @param keeper New direct keeper address.
    function setDirectKeeper(address keeper) external;

    /// @notice Reclaim keeper control from a subordinate contract.
    /// @param target Target contract address.
    function takeBackKeys(address target) external;
}
