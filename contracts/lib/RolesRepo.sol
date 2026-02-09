// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
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

/// @title RolesRepo
/// @notice Library for role membership and admin management.
library RolesRepo {

    /// @notice Role with admin and members.
    struct Role {
        address admin;
        mapping(address => bool) isMember;
    }

    /// @notice Repository of roles by id.
    struct Repo {
        mapping(bytes32 => Role) roles;
    }

    // ##################
    // ##    Modifier  ##
    // ##################

    /// @dev Reverts if caller is not role admin.
    /// @param repo Storage repo.
    /// @param role Role id.
    /// @param caller Caller address.
    modifier onlyAdmin(
        Repo storage repo, 
        bytes32 role, 
        address caller
    ) {
        require(repo.roles[role].admin == caller, 
            "RR.onlyAdmin: not admin");
        _;
    }

    // #################
    // ##    Write    ##
    // #################

    /// @notice Set role admin and add as member.
    /// @param repo Storage repo.
    /// @param role Role identifier (non-zero bytes32).
    /// @param acct Admin address (non-zero).
    function setRoleAdmin(
        Repo storage repo,
        bytes32 role,
        address acct
    ) public {
        repo.roles[role].admin = acct;
        repo.roles[role].isMember[acct] = true;
    }

    /// @notice Remove role admin and its membership.
    /// @param repo Storage repo.
    /// @param role Role identifier (non-zero bytes32).
    /// @param caller Current admin address.
    function quitRoleAdmin(
        Repo storage repo,
        bytes32 role,
        address caller
    ) public onlyAdmin(repo, role, caller) {
        delete repo.roles[role].admin;
        delete repo.roles[role].isMember[caller];
    }
    
    /// @notice Grant a role to an account.
    /// @param repo Storage repo.
    /// @param role Role identifier (non-zero bytes32).
    /// @param acct Account address (non-zero).
    /// @param caller Admin address.
    function grantRole(
        Repo storage repo,
        bytes32 role,
        address acct,
        address caller
    ) public onlyAdmin(repo, role, caller) {
        repo.roles[role].isMember[acct] = true;
    }

    /// @notice Revoke a role from an account.
    /// @param repo Storage repo.
    /// @param role Role identifier (non-zero bytes32).
    /// @param acct Account address (non-zero).
    /// @param caller Admin address.
    function revokeRole(
        Repo storage repo,
        bytes32 role,
        address acct,
        address caller
    ) public onlyAdmin(repo, role, caller) {
        delete repo.roles[role].isMember[acct];
    }

    /// @notice Renounce a role held by caller.
    /// @param repo Storage repo.
    /// @param role Role identifier (non-zero bytes32).
    /// @param caller Caller address.
    function renounceRole(
        Repo storage repo,
        bytes32 role,
        address caller
    ) public {
        delete repo.roles[role].isMember[caller];
    }

    /// @notice Abandon a role and all members.
    /// @param repo Storage repo.
    /// @param role Role identifier (non-zero bytes32).
    function abandonRole(
        Repo storage repo,
        bytes32 role
    ) public {
        delete repo.roles[role];
    }

    // ###############
    // ##   Read    ##
    // ###############

    /// @notice Get role admin address.
    /// @param repo Storage repo.
    /// @param role Role identifier (non-zero bytes32).
    function getRoleAdmin(Repo storage repo, bytes32 role)
        public view returns (address)
    {
        return repo.roles[role].admin;
    }

    /// @notice Check whether an account has a role.
    /// @param repo Storage repo.
    /// @param role Role identifier (non-zero bytes32).
    /// @param acct Account address (non-zero).
    function hasRole(
        Repo storage repo,
        bytes32 role,
        address acct
    ) public view returns (bool) {
        return repo.roles[role].isMember[acct];
    }
}
