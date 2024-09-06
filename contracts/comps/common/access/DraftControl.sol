// SPDX-License-Identifier: UNLICENSED

/* *
 * V.0.2.4
 *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

import "./IDraftControl.sol";
import "./AccessControl.sol";

contract DraftControl is IDraftControl, AccessControl {
    using RolesRepo for RolesRepo.Repo;

    bytes32 private constant _ATTORNEYS = bytes32("Attorneys");
    RolesRepo.Repo private _roles;

    // ################
    // ##  Modifier  ##
    // ################

    modifier onlyGC {
        require(_roles.getRoleAdmin(_ATTORNEYS) == 
            msg.sender,"AC.onlyGC: NOT");
        _;
    }

    modifier onlyAttorney {
        require(_roles.hasRole(_ATTORNEYS, msg.sender),
            "AC.onlyAttorney: NOT");
        _;
    }

    modifier attorneyOrKeeper {
        require(_roles.hasRole(_ATTORNEYS, msg.sender) ||
            _gk.isKeeper(msg.sender),
            "AC.md.attorneyOrKeeper: NOT");
        _;
    }

    // #################
    // ##    Write    ##
    // #################

    function setRoleAdmin(bytes32 role, address acct) external onlyOwner {
        _roles.setRoleAdmin(role, acct);
        emit SetRoleAdmin(role, acct);
    }

    function grantRole(bytes32 role, address acct) external {
        _roles.grantRole(role, acct, msg.sender);
    }

    function revokeRole(bytes32 role, address acct) external {
        _roles.revokeRole(role, acct, msg.sender);
    }

    function renounceRole(bytes32 role) external {
        _roles.renounceRole(role, msg.sender);
    }

    function abandonRole(bytes32 role) external onlyOwner {
        _roles.abandonRole(role);
    }

    function lockContents() public onlyOwner {
        require(_dk.state == 1, 
            "AC.lockContents: wrong state");

        _roles.abandonRole(_ATTORNEYS);
        setNewOwner(address(0));
        _dk.state = 2;

        emit LockContents();
    }

    // ##############
    // ##   Read   ##
    // ##############

    function isFinalized() public view returns (bool) {
        return _dk.state == 2;
    }

    function getRoleAdmin(bytes32 role) public view returns (address) {
        return _roles.getRoleAdmin(role);
    }

    function hasRole(bytes32 role, address acct) public view returns (bool) {
        return _roles.hasRole(role, acct);
    }

}
