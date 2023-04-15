// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/EnumerableSet.sol";
import "../../common/lib/SwapsRepo.sol";

interface IRegisterOfSwaps {

    //##################
    //##    Event     ##
    //##################

    event CreateSwap(uint256 indexed seqOfSwap, uint rightholder, uint obligor, uint paidOfConsider, uint rateOfSwap);

    event CrystalizeSwap(uint256 indexed seqOfSwap, uint seqOfConsider, uint paidOfConsider, uint seqOfTarget, uint paidOfTarget);

    event LockSwap(uint256 indexed seqOfSwap, bytes32 hashLock);

    event ReleaseSwap(uint256 indexed seqOfSwap, string hashKey);

    event ExecSwap(uint256 indexed seqOfSwap);

    event RevokeSwap(uint256 indexed seqOfSwap);

    //#################
    //##    写接口    ##
    //#################

    function createSwap(
        bytes32 snOfSwap,
        uint rightholder, 
        uint paidOfConsider
    ) external;

    function issueSwap(
        SwapsRepo.Head memory head,
        uint rightholder, 
        uint paidOfConsider
    ) external;
    
    function regSwap(SwapsRepo.Swap memory swap) external returns(SwapsRepo.Swap memory newSwap);

    function transferSwap(uint256 seqOfSwap, uint to, uint amt) external;

    function crystalizeSwap(uint256 seqOfSwap, uint seqOfConsider, uint seqOfTarget) 
        external returns(SwapsRepo.Body memory body);

    function lockSwap(uint256 seqOfSwap, bytes32 hashLock) external returns (bool flag);

    function releaseSwap(uint256 seqOfSwap, string memory hashKey) external returns (bool flag);

    function execSwap(uint256 seqOfSwap) external returns(bool flag);

    function revokeSwap(uint256 seqOfSwap) external returns(bool flag);

    //###################
    //##    查询接口    ##
    //##################

    function counterOfSwap() external view returns (uint32);

    function isSwapSeq(uint256 seqOfSwap) external view returns(bool flag);

    // ==== Swap ====

    function getSwap(uint256 seqOfSwap) external view returns(SwapsRepo.Swap memory);

    function getAllSwaps() external view returns(SwapsRepo.Swap[] memory);

    // ==== SNList ====

    function isSwapSN(bytes32 snOfSwap) external view returns(bool flag);

    function getSNList() external view returns (bytes32[] memory);
}
