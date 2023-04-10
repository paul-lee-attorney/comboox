// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IROSKeeper {

    // ##################
    // ##    Write     ##
    // ##################

    function createSwap(
        uint256 sn,
        uint rightholder, 
        uint paidOfConsider,
        uint caller
    ) external;

    function transferSwap(
        uint256 seqOfSwap, 
        uint to, 
        uint amt,
        uint caller
    ) external;

    function crystalizeSwap(
        uint256 seqOfSwap, 
        uint seqOfConsider, 
        uint seqOfTarget,
        uint caller
    ) external;

    function lockSwap(
        uint256 seqOfSwap, 
        bytes32 hashLock,
        uint caller
    ) external;

    function releaseSwap(uint256 seqOfSwap, string memory hashKey, uint caller)
        external;

    function execSwap(uint256 seqOfSwap, uint caller) external;

    function revokeSwap(uint256 seqOfSwap, uint caller) external;

    function requestToBuy(
        uint256 seqOfMotion,
        uint256 seqOfDeal,
        uint seqOfTarget,
        uint256 caller
    ) external;

}
