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

    event CreateSwap(uint256 indexed seqOfSwap, uint40 rightholder, uint40 obligor, uint64 paidOfConsider, uint32 rateOfSwap);

    event CrystalizeSwap(uint256 indexed seqOfSwap, uint32 seqOfConsider, uint64 paidOfConsider, uint32 seqOfTarget, uint64 paidOfTarget);

    event LockSwap(uint256 indexed seqOfSwap, bytes32 hashLock);

    event ReleaseSwap(uint256 indexed seqOfSwap, string hashKey);

    event ExecSwap(uint256 indexed seqOfSwap);

    event RevokeSwap(uint256 indexed seqOfSwap);

    //#################
    //##    写接口    ##
    //#################

    function createSwap(
        uint256 sn,
        uint40 rightholder, 
        uint64 paidOfConsider
    ) external;

    function issueSwap(
        SwapsRepo.Head memory head,
        uint40 rightholder, 
        uint64 paidOfConsider
    ) external;
    
    function regSwap(SwapsRepo.Swap memory swap) external returns(SwapsRepo.Swap memory newSwap);

    function transferSwap(uint256 seqOfSwap, uint40 to, uint64 amt) external;

    function crystalizeSwap(uint256 seqOfSwap, uint32 seqOfConsider, uint32 seqOfTarget) 
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

    function isSwapSN(uint256 snOfSwap) external view returns(bool flag);

    function getSNList() external view returns (uint256[] memory);
}
