// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ITerm.sol";

interface IAntiDilution is ITerm {
    // ################
    // ##   Write    ##
    // ################
    function setMaxQtyOfMarks(uint16 max) external;

    function addBenchmark(uint256 class, uint32 price) external;

    function updateBenchmark(
        uint256 class,
        uint32 deltaPrice,
        bool increase
    ) external;

    function delBenchmark(uint256 class) external;

    function addObligor(uint256 class, uint256 obligor) external;

    function removeObligor(uint256 class, uint256 obligor) external;

    // ############
    // ##  read  ##
    // ############

    function isMarked(uint256 class) external view returns (bool);

    function markedClasses() external view returns (uint256[] memory);

    function getBenchmark(uint256 class) external view returns (uint64);

    function obligors(uint256 class) external view returns (uint256[] memory);

    function giftPar(address ia, uint256 snOfDeal, uint256 seqOfShare)
        external
        view
        returns (uint64);
}
