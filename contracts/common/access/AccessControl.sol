// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IAccessControl.sol";
import "./RegCenterSetting.sol";

contract AccessControl is IAccessControl, RegCenterSetting {
    using RolesRepo for RolesRepo.Roles;

    bytes32 private constant _ATTORNEYS = bytes32("Attorneys");

    RolesRepo.Roles private _roles;
    // ##################
    // ##   修饰器      ##
    // ##################

    modifier onlyOwner {
        require(
            _roles.isOwner(_msgSender()),
            "AC.ow: not owner"
        );
        _;
    }

    modifier onlyDirectKeeper() {
        require(
            _roles.isDirectKeeper(msg.sender),
            "AC.onlyDirectKeeper: not direct keeper"
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
            _roles.hasRole(_ATTORNEYS, _msgSender()),
            "AC.ot: not Attorney"
        );
        _;
    }

    modifier attorneyOrKeeper {
        require(
            _roles.hasRole(_ATTORNEYS, _msgSender()) ||
                _gk.isKeeper(msg.sender),
            "neither Attorney nor Bookeeper"
        );
        _;
    }

    modifier onlyFinalized() {
        require(_roles.state == 2, "AC.mf.OF: still pending");
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
        _roles.initDoc(owner, directKeeper);
        _setRegCenter(regCenter);
        _setGeneralKeeper(generalKeeper);
        emit Init(owner, directKeeper, regCenter, generalKeeper);
    }

    function setOwner(uint256 acct) external {
        _roles.setOwner(acct, _msgSender());
        emit SetOwner(acct);
    }

    function setDirectKeeper(address keeper) external {
        _roles.setBookeeper(keeper, msg.sender);
        emit SetDirectKeeper(keeper);
    }

    function removeDirectKeeper(address target) onlyDirectKeeper external {
        IAccessControl(target).setDirectKeeper(msg.sender);
        emit RemoveDirectKeeper(target);
    }

    function setGeneralCounsel(uint256 acct)
        external ownerOrDirectBookeeper
    {
        _roles.setGeneralCounsel(acct, _msgSender());
        emit SetGeneralCounsel(acct);
    }

    function setRoleAdmin(bytes32 role, uint256 acct) external {
        _roles.setRoleAdmin(role, acct, _msgSender());
    }

    function grantRole(bytes32 role, uint256 acct) external {
        _roles.grantRole(role, acct, _msgSender());
    }

    function revokeRole(bytes32 role, uint256 acct) external {
        _roles.revokeRole(role, acct, _msgSender());
    }

    function renounceRole(bytes32 role) external {
        _roles.renounceRole(role, _msgSender());
    }

    function abandonRole(bytes32 role) external {
        _roles.abandonRole(role, _msgSender());
    }

    function lockContents() public {
        require(_roles.state == 1, "AC.LC: Doc is finalized");

        _roles.abandonRole(_ATTORNEYS, _msgSender());
        _roles.setGeneralCounsel(0, _msgSender());
        _roles.setOwner(0, _msgSender());

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
