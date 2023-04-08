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
        uint40 rightholder, 
        uint64 paidOfConsider,
        uint40 caller
    ) external;

    function transferSwap(
        uint256 seqOfSwap, 
        uint40 to, 
        uint64 amt,
        uint40 caller
    ) external;

    function crystalizeSwap(
        uint256 seqOfSwap, 
        uint32 seqOfConsider, 
        uint32 seqOfTarget,
        uint40 caller
    ) external;

    function lockSwap(
        uint256 seqOfSwap, 
        bytes32 hashLock,
        uint40 caller
    ) external;

    function releaseSwap(uint256 seqOfSwap, string memory hashKey, uint40 caller)
        external;

    function execSwap(uint256 seqOfSwap, uint40 caller) external;

    function revokeSwap(uint256 seqOfSwap, uint40 caller) external;

    function requestToBuy(
        uint256 seqOfMotion,
        uint256 seqOfDeal,
        uint32 seqOfTarget,
        uint256 caller
    ) external;

}
