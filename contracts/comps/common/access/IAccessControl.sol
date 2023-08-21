// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../lib/RolesRepo.sol";

import "../../../center/IRegCenter.sol";
import "../../IGeneralKeeper.sol";

interface IAccessControl {

    // enum TitleOfBooks {
    //     ZeroPoint,
    //     ROC,    // 1
    //     ROD,    // 2
    //     BMM,    // 3
    //     ROM,    // 4
    //     GMM,    // 5
    //     ROA,    // 6
    //     ROO,    // 7
    //     ROP,    // 8
    //     ROS,    // 9
    //     BOS    // 10
    // }

    // enum TitleOfKeepers {
    //     ZeroPoint,
    //     ROCKeeper, // 1
    //     RODKeeper, // 2
    //     BMMKeeper, // 3
    //     ROMKeeper, // 4
    //     GMMKeeper, // 5
    //     ROAKeeper, // 6
    //     ROOKeeper, // 7
    //     ROPKeeper, // 8
    //     ROSKeeper, // 9
    //     SHAKeeper // 10
    // }

    // ##################
    // ##   Event      ##
    // ##################

    event Init(
        address indexed owner,
        address indexed directKeeper,
        address regCenter,
        address indexed generalKeeper
    );

    event SetOwner(address indexed acct);

    event SetDirectKeeper(address indexed keeper);

    event SetRoleAdmin(bytes32 indexed role, address indexed acct);

    event LockContents();

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        address owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    ) external;

    function setOwner(address acct) external;

    function setDirectKeeper(address keeper) external;

    function takeBackKeys(address target) external;

    function setRoleAdmin(bytes32 role, address acct) external;

    function grantRole(bytes32 role, address acct) external;

    function revokeRole(bytes32 role, address acct) external;

    function renounceRole(bytes32 role) external;

    function abandonRole(bytes32 role) external;

    function lockContents() external;

    // ##################
    // ##   查询端口    ##
    // ##################

    function getOwner() external view returns (address);

    function getDK() external view returns (address);

    function isFinalized() external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (address);

    function hasRole(bytes32 role, address acct) external view returns (bool);

}
