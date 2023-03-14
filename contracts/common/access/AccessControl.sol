// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IAccessControl.sol";
import "./RegCenterSetting.sol";
import "../lib/RolesRepo.sol";

import "../../books/boh/IShareholdersAgreement.sol";
import "../../books/boh/IBookOfSHA.sol";

contract AccessControl is IAccessControl, RegCenterSetting {
    using RolesRepo for RolesRepo.Roles;

    bytes32 constant ATTORNEYS = bytes32("Attorneys");

    RolesRepo.Roles internal _roles;
    // ##################
    // ##   修饰器      ##
    // ##################

    modifier onlyDirectKeeper() {
        require(
            _roles.isDirectKeeper(msg.sender),
            "AC.onlyDirectKeeper: not direct keeper"
        );
        _;
    }

    modifier onlyOwner {
        require(
            _roles.isOwner(_msgSender()),
            "AC.ow: not owner"
        );
        _;
    }

    modifier onlyGeneralCounsel {
        require(
            _roles.isGeneralCounsel(_msgSender()),
            "AC.ogc: not general counsel"
        );
        _;
    }

    modifier ownerOrDirectBookeeper() {
        require(
            _roles.isDirectKeeper(msg.sender) ||
                _roles.isOwner(_msgSender()),
            "AC.ownerOrDirectBookeeper: neither owner nor bookeeper"
        );
        _;
    }

    modifier onlyKeeper {
        require(_gk.isKeeper(msg.sender), "AC.ok: not Keeper");
        _;
    }

    modifier onlyAttorney {
        require(
            _roles.hasRole(ATTORNEYS, _msgSender()),
            "AC.ot: not Attorney"
        );
        _;
    }

    modifier attorneyOrKeeper {
        require(
            _roles.hasRole(ATTORNEYS, _msgSender()) ||
                _gk.isKeeper(msg.sender),
            "neither Attorney nor Bookeeper"
        );
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
        uint256 owner,
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

    function setOwner(uint256 acct)
        external
        virtual
        ownerOrDirectBookeeper
    {
        _roles.setOwner(acct);
        emit SetOwner(acct);
    }

    function setGeneralCounsel(uint256 acct)
        external
        virtual
        ownerOrDirectBookeeper
    {
        _roles.setGeneralCounsel(acct);
        emit SetGeneralCounsel(acct);
    }

    function setRoleAdmin(bytes32 role, uint256 acct) external {
        _roles.setRoleAdmin(role, _msgSender(), acct);
    }

    function grantRole(bytes32 role, uint256 acct) external {
        _roles.grantRole(role, _msgSender(), acct);
    }

    function revokeRole(bytes32 role, uint256 acct) external {
        _roles.revokeRole(role, _msgSender(), acct);
    }

    function renounceRole(bytes32 role) external {
        uint40 msgSender = _msgSender();
        _roles.renounceRole(role, msgSender);
    }

    function abandonRole(bytes32 role) external onlyDirectKeeper {
        _roles.abandonRole(role);
    }

    function lockContents() public onlyDirectKeeper {
        require(_roles.state == 1, "AC.onlyPending: Doc is finalized");

        _roles.abandonRole(ATTORNEYS);
        _roles.setGeneralCounsel(0);
        _roles.state = 2;

        emit LockContents();
    }

    // ##################
    // ##   查询端口   ##
    // ##################

    function getOwner() public view returns (uint40) {
        return _roles.getOwner();
    }

    function getGeneralCounsel() public view returns (uint40) {
        return _roles.getGeneralCounsel();
    }

    function getBookeeper() public view returns (address) {
        return _roles.getKeeper();
    }


    function finalized() public view returns (bool) {
        return _roles.state == 2;
    }

    function hasRole(bytes32 role, uint256 acct) public view returns (bool) {
        return _roles.hasRole(role, acct);
    }
}
