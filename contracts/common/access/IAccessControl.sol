// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../books/boh/IShareholdersAgreement.sol";

interface IAccessControl {

    // ##################
    // ##   Event      ##
    // ##################

    event Init(
        uint40 owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    );

    event SetDirectKeeper(address keeper);

    event SetOwner(uint256 acct);

    event SetGeneralCounsel(uint256 acct);

    event LockContents();

    // ##################
    // ##    写端口    ##
    // ##################

    function init(
        uint40 owner,
        address directKeeper,
        address regCenter,
        address generalKeeper
    ) external;

    function setDirectKeeper(address keeper) external;

    function setOwner(uint40 acct) external;

    function setGeneralCounsel(uint40 acct) external;

    function grantRole(bytes32 role, uint40 acct) external;

    function revokeRole(bytes32 role, uint40 acct) external;

    function renounceRole(bytes32 role) external;

    function abandonRole(bytes32 role) external;

    function setRoleAdmin(bytes32 role, uint40 acct) external;

    function lockContents() external;

    // ##################
    // ##   查询端口    ##
    // ##################

    function getOwner() external view returns (uint40);

    function getGeneralCounsel() external view returns (uint40);

    function getBookeeper() external view returns (address);


    function finalized() external view returns (bool);

    function hasRole(bytes32 role, uint40 acct) external view returns (bool);
}
