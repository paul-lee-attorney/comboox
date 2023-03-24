// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import "../../common/lib/OptionsRepo.sol";
import "../../common/lib/Checkpoints.sol";
import "../../common/lib/SwapsRepo.sol";

pragma solidity ^0.8.8;

interface IBookOfOptions {

    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(uint256 indexed seqOfOpt, uint256 codeOfOpt);

    event AddObligorIntoOpt(uint256 indexed seqOfOpt, uint256 obligor);

    event RemoveObligorFromOpt(uint256 indexed seqOfOpt, uint256 obligor);

    event UpdateOracle(uint256 indexed seqOfOpt, uint64 data1, uint64 data2, uint64 data3);

    event ExecOpt(uint256 indexed seqOfOpt);

    event RegSwapOrder(uint256 indexed seqOfOpt, uint256 codeOfBrf);

    event UpdateStateOfBrief(uint256 indexed seqOfOpt, uint256 seqOfBrf, uint8 state);

    function createOption(
        uint256 sn,
        uint256 snOfCond,
        uint40 rightholder,
        uint64 paid,
        uint64 par
    ) external returns(OptionsRepo.Head memory head);

    function issueOption(OptionsRepo.Option memory opt) external 
        returns(OptionsRepo.Head memory head);

    function regOptionTerms(address opts) external;

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external;

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external;

    function updateOracle(
        uint256 seqOfOpt,
        uint64 d1,
        uint64 d2,
        uint64 d3
    ) external;

    function execOption(uint256 seqOfOpt) external;

    function createSwapOrder(
        uint256 seqOfOpt,
        uint32 seqOfConsider,
        uint64 paidOfConsider,
        uint32 seqOfTarget
    ) external view returns (SwapsRepo.Swap memory swap);

    function regSwapOrder(
        uint256 seqOfOpt,
        SwapsRepo.Swap memory swap
    ) external;

    function updateStateOfBrief(
        uint256 seqOfOpt,
        uint256 seqOfBrf,
        uint8 state
    ) external;

    // ################
    // ##  查询接口   ##
    // ################

    function counterOfOptions() external view returns (uint32);

    function isOption(uint256 seqOfOpt) external view returns (bool);

    function getOption(uint256 seqOfOpt) external view
        returns (OptionsRepo.Option memory opt);

    function getAllOptions() external view returns (OptionsRepo.Option[] memory);

    function isRightholder(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    function isObligor(uint256 seqOfOpt, uint256 acct) external view returns (bool);

    function getObligorsOfOption(uint256 seqOfOpt)
        external view returns (uint256[] memory);

    // ==== Brief ====
    function counterOfBriefs(uint256 seqOfOpt)
        external view returns (uint256);

    function getBrief(uint256 seqOfOpt, uint256 seqOfBrf)
        external view returns (OptionsRepo.Brief memory brf);

    function getAllBriefsOfOption(uint256 seqOfOpt)
        external
        view
        returns (OptionsRepo.Brief[] memory);

    // ==== oracles ====

    function getOracleAtDate(uint256 seqOfOpt, uint48 date)
        external view returns (Checkpoints.Checkpoint memory);

    function getALLOraclesOfOption(uint256 seqOfOpt)
        external view returns (Checkpoints.Checkpoint[] memory);
}
