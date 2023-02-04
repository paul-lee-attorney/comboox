// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IAccessControl.sol";
import "./RegCenterSetting.sol";
import "../lib/RolesRepo.sol";

contract AccessControl is IAccessControl, RegCenterSetting {
    using RolesRepo for RolesRepo.Roles;

    enum TitleOfKeepers {
        BOAKeeper, // 0
        BODKeeper, // 1
        BOHKeeper, // 2
        BOMKeeper, // 3
        BOOKeeper, // 4
        BOPKeeper, // 5
        BOSKeeper, // 6
        ROMKeeper, // 7
        SHAKeeper // 8
    }

    enum TitleOfManagers {
        Owner,
        GeneralCounsel
    }

    bytes32 constant ATTORNEYS = bytes32("Attorneys");

    RolesRepo.Roles internal _roles;

    // ##################
    // ##   修饰器      ##
    // ##################

    modifier onlyDK() {
        require(
            _roles.isDirectKeeper(msg.sender),
            "AC.onlyDK: not direct keeper"
        );
        _;
    }

    modifier ownerOrBookeeper() {
        require(
            _roles.isDirectKeeper(msg.sender) ||
                _roles.isManager(0, _msgSender()),
            "AC.ownerOrBookeeper: neither owner nor bookeeper"
        );
        _;
    }

    modifier onlyManager(uint8 title) {
        require(
            _roles.isManager(title, _msgSender()),
            "AC.onlyManager: not the specific manager"
        );
        _;
    }

    modifier onlyKeeper(uint8 title) {
        require(_gk.isKeeper(title, msg.sender), "AC.onlyKeeper: not Keeper");
        _;
    }

    modifier onlyAttorney() {
        require(
            _roles.hasRole(ATTORNEYS, _msgSender()),
            "AC.onlyAttorney: not Attorney"
        );
        _;
    }

    modifier attorneyOrKeeper(uint8 title) {
        require(
            _roles.hasRole(ATTORNEYS, _msgSender()) ||
                _gk.isKeeper(title, msg.sender),
            "not Attorney or Bookeeper"
        );
        _;
    }

    modifier onlyPending() {
        require(_roles.state == 1, "AC.onlyPending: Doc is finalized");
        _;
    }

    modifier onlyFinalized() {
        require(_roles.state == 2, "AC.onlyFinalized: Doc is still pending");
        _;
    }

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        uint40 owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    ) external {
        _setRegCenter(regCenter);

        _setGeneralKeeper(generalKeeper);

        _roles.initDoc(owner, directKeeper);

        emit Init(owner, directKeeper, regCenter, generalKeeper);
    }

    function setDirectKeeper(address keeper) external {
        _roles.setBookeeper(msg.sender, keeper);
        emit SetDirectKeeper(keeper);
    }

    function setManager(uint8 title, uint40 acct)
        external
        virtual
        ownerOrBookeeper
    {
        _roles.setManager(title, acct);
        emit SetManager(title, acct);
    }

    function setRoleAdmin(bytes32 role, uint40 acct) external {
        _roles.setRoleAdmin(role, _msgSender(), acct);
        // emit SetRoleAdmin(role, acct);
    }

    function grantRole(bytes32 role, uint40 acct) external {
        _roles.grantRole(role, _msgSender(), acct);
        // emit GrantRole(role, acct);
    }

    function revokeRole(bytes32 role, uint40 acct) external {
        _roles.revokeRole(role, _msgSender(), acct);
        // emit RevokeRole(role, acct);
    }

    function renounceRole(bytes32 role) external {
        uint40 msgSender = _msgSender();
        _roles.renounceRole(role, msgSender);
        // emit RenounceRole(role, msgSender);
    }

    function abandonRole(bytes32 role) external onlyDK {
        _roles.abandonRole(role);
        // emit AbandonRole(role);
    }

    function lockContents() public onlyPending onlyDK {
        _roles.abandonRole(ATTORNEYS);
        _roles.setManager(1, 0);
        _roles.state = 2;

        emit LockContents();
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getManager(uint8 title) public view returns (uint40) {
        return _roles.getManager(title);
    }

    function getBookeeper() public view returns (address) {
        return _roles.getKeeper();
    }

    function getManagerKey(uint8 title) public view returns (address) {
        return _rc.primeKey(getManager(title));
    }

    function finalized() public view returns (bool) {
        return _roles.state == 2;
    }

    function hasRole(bytes32 role, uint40 acct) public view returns (bool) {
        return _roles.hasRole(role, acct);
    }
}
