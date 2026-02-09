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

/// @title IOwnable
/// @notice Minimal ownership interface used by upgradeable components.
/// @dev Exposes implementation address for UUPS checks and an owner update hook.

interface IOwnable {

    /// @notice Admin state container.
    /// @dev `state` is a small flag used to guard initialization.
    struct Admin{
        address addr;
        uint8 state;
    }

    /// @notice Emitted when the owner address is updated.
    /// @param owner New owner address.
    event SetNewOwner(address indexed owner);

    // ==== UUPS Upgradeability ====

    /// @notice Initialize ownership and registry center for an upgradeable proxy.
    /// @param owner_ Initial owner/admin address (non-zero expected).
    /// @param regCenter_ Registry center contract address (non-zero expected).
    function initialize(address owner_,address regCenter_) external;

    /// @notice Return current implementation address (UUPS compatibility check).
    /// @return Implementation address.
    function getImplementation() external view returns (address);

    // #################
    // ##    Write    ##
    // #################
    
    /// @notice Update owner address.
    /// @param acct New owner address (non-zero in implementations).
    function setNewOwner(address acct) external;
}
