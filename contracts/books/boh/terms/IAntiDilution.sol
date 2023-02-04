// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ITerm.sol";

interface IAntiDilution is ITerm {
    // ################
    // ##   Write    ##
    // ################
    function setMaxQtyOfMarks(uint16 max) external;

    function addBenchmark(uint16 class, uint32 price) external;

    function updateBenchmark(
        uint16 class,
        uint32 deltaPrice,
        bool increase
    ) external;

    function delBenchmark(uint16 class) external;

    function addObligor(uint16 class, uint40 obligor) external;

    function removeObligor(uint16 class, uint40 obligor) external;

    // ############
    // ##  read  ##
    // ############

    function isMarked(uint16 class) external view returns (bool);

    function markedClasses() external view returns (uint40[] memory);

    function getBenchmark(uint16 class) external view returns (uint64);

    function obligors(uint16 class) external view returns (uint40[] memory);

    function giftPar(bytes32 snOfDeal, bytes32 shareNumber)
        external
        view
        returns (uint64);
}
