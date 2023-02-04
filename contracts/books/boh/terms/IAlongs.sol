// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IAlongs {
    // ################
    // ##   Write    ##
    // ################

    function createLink(bytes32 rule, uint40 drager) external;

    function addFollower(uint40 drager, uint40 follower) external;

    function removeFollower(uint40 drager, uint40 follower) external;

    function removeDrager(uint40 drager) external;

    function delLink(bytes32 rule) external;

    // ###############
    // ##  查询接口  ##
    // ###############

    function linkRule(uint40 drager) external view returns (bytes32);

    function isDrager(uint40 drager) external view returns (bool);

    function isLinked(uint40 drager, uint40 follower)
        external
        view
        returns (bool);

    function dragers() external view returns (uint40[] memory);

    function followers(uint40 drager) external view returns (uint40[] memory);

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) external view returns (bool);

    function isTriggered(address ia, bytes32 sn) external view returns (bool);
}
