// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/lib/OptionsRepo.sol";

interface IOptions {
    // ################
    // ##   写接口   ##
    // ################

    function createOption(
        bytes32 sn,
        uint256 rightholder,
        uint256 obligor,
        uint64 paid,
        uint64 par
    ) external returns (uint32 seqOfOpt);

    function delOption(uint256 seqOfOpt) external;

    function addObligorIntoOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external returns (bool flag);

    function removeObligorFromOpt(
        uint256 seqOfOpt,
        uint256 obligor
    ) external returns (bool flag);

    function optRegistered(uint256 seqOfOpt)
        external;

    // ################
    // ##  查询接口  ##
    // ################

    function counterOfOpts() external view returns (uint32);

    function isOption(uint256 seqOfOpt) external view returns (bool);

    function isObligor(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Head memory head, OptionsRepo.Body memory body);

    function obligorsOfOption(uint256 seqOfOpt) external view
        returns (uint256[] memory);
}
