// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/lib/OptionsRepo.sol";
import "../common/lib/SwapsRepo.sol";

interface IROOKeeper {
    // #################
    // ##  ROOKeeper  ##
    // #################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    function execOption(uint256 seqOfOpt, uint256 caller)
        external;

    function placeSwapOrder(
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget,
        uint256 caller
    ) external;

    function lockSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        bytes32 hashLock, 
        uint256 caller
    ) external;

    function releaseSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        string memory hashKey 
    ) external;

    function execSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf,
        uint256 caller
    ) external;

    function revokeSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf,
        uint256 caller
    ) external;

}
