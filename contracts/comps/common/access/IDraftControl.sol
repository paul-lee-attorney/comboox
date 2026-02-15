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

import "../../../lib/utils/RolesRepo.sol";

/// @title IDraftControl
/// @notice Draft-stage access control and finalization interface.
/// @dev Manages role administration and irreversible content locking.
interface IDraftControl {

    // #####################
    // ##  Error & Event  ##
    // #####################

    /// @notice Emitted when a non-GC attempts a GC-only action.
    error DC_NotGC();

    /// @notice Emitted when a non-attorney attempts an attorney-only action.
    error DC_NotAttorney();

    /// @notice Emitted when a non-attorney and non-GK attempts an attorney or GK-only action.
    error DC_NotAttorneyOrGK();

    /// @notice Emitted when an attempt to lock contents is made in the wrong state.
    error DC_LockContents_WrongState();

    /// @notice Emitted when a role admin is updated.
    /// @param role Role identifier.
    /// @param acct New admin address.
    event SetRoleAdmin(bytes32 indexed role, address indexed acct);    

    /// @notice Emitted when contents are finalized and roles are locked.
    event LockContents();

    // ##################
    // ##    Write     ##
    // ##################

    /// @notice Set the admin for a role.
    /// @param role Role identifier (non-zero bytes32).
    /// @param acct Admin address (must be a non-zero address).
    function setRoleAdmin(bytes32 role, address acct) external;

    /// @notice Grant a role to an account.
    /// @param role Role identifier (non-zero bytes32).
    /// @param acct Account address (non-zero).
    function grantRole(bytes32 role, address acct) external;

    /// @notice Revoke a role from an account.
    /// @param role Role identifier (non-zero bytes32).
    /// @param acct Account address (non-zero).
    function revokeRole(bytes32 role, address acct) external;

    /// @notice Renounce a role held by the caller.
    /// @param role Role identifier (non-zero bytes32).
    function renounceRole(bytes32 role) external;

    /// @notice Abandon a role by clearing its members.
    /// @param role Role identifier (non-zero bytes32).
    function abandonRole(bytes32 role) external;

    /// @notice Irreversibly lock contents by removing write authorities.
    /// @dev Typically sets owner to zero and abandons privileged roles.
    function lockContents() external;

    // ##################
    // ##   Read I/O   ##
    // ##################

    /// @notice Check whether contents are finalized.
    /// @return True if the contract is finalized and immutable.
    function isFinalized() external view returns (bool);

    /// @notice Get the admin address for a role.
    /// @param role Role identifier (non-zero bytes32).
    function getRoleAdmin(bytes32 role) external view returns (address);

    /// @notice Check whether an account has a role.
    /// @param role Role identifier (non-zero bytes32).
    /// @param acct Account address (non-zero).
    function hasRole(bytes32 role, address acct) external view returns (bool);

}
