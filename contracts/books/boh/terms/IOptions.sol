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
        uint256 sn,
        uint256 snOfCond,
        uint40 rightholder,
        uint40 obligor,
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

    // function optRegistered(uint256 seqOfOpt)
    //     external;

    // ###############
    // ##  查询接口  ##
    // ###############

    function counterOfOpts() external view returns (uint32);

    function isOption(uint256 seqOfOpt) external view returns (bool);

    function isObligor(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory option);

    function obligorsOfOption(uint256 seqOfOpt) external view
        returns (uint256[] memory);
}
