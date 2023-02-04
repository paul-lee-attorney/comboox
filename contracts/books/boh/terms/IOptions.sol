// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IOptions {
    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        bytes32 sn,
        uint40 rightholder,
        uint40[] memory obligors,
        uint64 paid,
        uint64 par
    ) external returns (bytes32 _sn);

    function delOption(bytes32 sn) external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOpts() external view returns (uint32);

    function isOption(bytes32 sn) external view returns (bool);

    function qtyOfOpts() external view returns (uint256);

    function isObligor(bytes32 sn, uint40 acct) external view returns (bool);

    function getOption(bytes32 sn)
        external
        view
        returns (
            uint40 rightholder,
            uint64 paid,
            uint64 par
        );

    function obligorsOfOption(bytes32 sn)
        external
        view
        returns (uint40[] memory);

    function optsList() external view returns (bytes32[] memory);
}
