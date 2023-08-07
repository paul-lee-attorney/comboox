// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import "../roc/terms/IOptions.sol";

import "../../common/lib/Checkpoints.sol";
import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/OptionsRepo.sol";
import "../../common/lib/SwapsRepo.sol";

pragma solidity ^0.8.8;

interface IRegisterOfOptions {

    // ################
    // ##   Event    ##
    // ################

    event CreateOpt(uint256 indexed seqOfOpt, bytes32 indexed codeOfOpt);

    event IssueOpt(uint256 indexed seqOfOpt, uint indexed issueDate);

    event AddObligorIntoOpt(uint256 indexed seqOfOpt, uint256 indexed obligor);

    event RemoveObligorFromOpt(uint256 indexed seqOfOpt, uint256 indexed obligor);

    event UpdateOracle(uint256 indexed seqOfOpt, uint indexed data1, uint indexed data2, uint data3);

    event ExecOpt(uint256 indexed seqOfOpt);

    event RegSwapOrder(uint256 indexed seqOfOpt, bytes32 indexed codeOfBrf);

    event UpdateStateOfBrief(uint256 indexed seqOfOpt, uint256 indexed seqOfBrf, uint indexed state);

    // ################
    // ##   Write    ##
    // ################

    function createOption(
        bytes32 sn,
        bytes32 snOfCond,
        uint rightholder,
        uint paid,
        uint par
    ) external returns(OptionsRepo.Head memory head);

    function issueOption(OptionsRepo.Option memory opt) external;

    function regOptionTerms(address opts) external;

    function addObligorIntoOption(uint256 seqOfOpt, uint256 obligor) external;

    function removeObligorFromOption(uint256 seqOfOpt, uint256 obligor) external;

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    function execOption(uint256 seqOfOpt) external;

    function createSwapOrder(
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget
    ) external view returns (SwapsRepo.Swap memory swap);

    function regSwapOrder(
        uint256 seqOfOpt,
        SwapsRepo.Swap memory swap
    ) external;

    function updateStateOfBrief(
        uint256 seqOfOpt,
        uint256 seqOfBrf,
        uint state
    ) external;

    // ################
    // ##  查询接口   ##
    // ################

    function counterOfOptions() external view returns (uint32);

    function qtyOfOptions() external view returns (uint);

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
        external view returns (OptionsRepo.Brief[] memory);

    // ==== oracles ====

    function getOracleAtDate(uint256 seqOfOpt, uint date)
        external view returns (Checkpoints.Checkpoint memory);

    function getLatestOracle(uint256 seqOfOpt) external 
        view returns(Checkpoints.Checkpoint memory);

    function getAllOraclesOfOption(uint256 seqOfOpt)
        external view returns (Checkpoints.Checkpoint[] memory);
}
