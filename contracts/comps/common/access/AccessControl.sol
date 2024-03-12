// SPDX-License-Identifier: UNLICENSED

/* *
 * V.0.2.1
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

import "./IAccessControl.sol";
import "../../../center/access/Ownable.sol";

contract AccessControl is IAccessControl, Ownable {
    using RolesRepo for RolesRepo.Repo;

    bytes32 private constant _ATTORNEYS = bytes32("Attorneys");

    RolesRepo.Repo private _roles;

    Admin private _dk;
    IGeneralKeeper internal _gk;

    // ################
    // ##  Modifier  ##
    // ################

    modifier onlyDK {
        require(_dk.addr == msg.sender,
            "AC.onlyDK: not");
        _;
    }

    modifier onlyGC {
        require(_roles.getRoleAdmin(_ATTORNEYS) == 
            msg.sender,"AC.onlyGC: NOT");
        _;
    }

    modifier onlyKeeper {
        require(_gk.isKeeper(msg.sender) || 
            _dk.addr == msg.sender, 
            "AC.onlyKeeper: NOT");
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

    function initKeepers(address dk,address gk) external {
        require(_dk.state == 0, 
            "AC.initKeepers: already inited");
        _dk.addr = dk;
        _gk = IGeneralKeeper(gk);
        _dk.state = 1;
    }

    function setDirectKeeper(address acct) external onlyDK {
        _dk.addr = acct;
        emit SetDirectKeeper(acct);
    }

    function takeBackKeys (address target) external onlyDK {
        IAccessControl(target).setDirectKeeper(msg.sender);
    }

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

    function getDK() external view returns (address) {
        return _dk.addr;
    }

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
