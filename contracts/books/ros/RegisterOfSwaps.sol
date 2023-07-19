// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfSwaps.sol";

import "../../common/access/AccessControl.sol";

contract RegisterOfSwaps is IRegisterOfSwaps, AccessControl {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SwapsRepo for SwapsRepo.Repo;
    using SwapsRepo for SwapsRepo.Swap;
    using SwapsRepo for uint256;

    
    SwapsRepo.Repo private _repo;

    //#################
    //##    写接口    ##
    //#################

    function createSwap(
        bytes32 snOfSwap,
        uint rightholder, 
        uint paidOfConsider
    ) external onlyKeeper {
        SwapsRepo.Head memory head = _repo.createSwap(snOfSwap, rightholder, paidOfConsider, _getGK());
        emit CreateSwap(head.seqOfSwap, rightholder, head.obligor, paidOfConsider, head.rateOfSwap);
    }

    function issueSwap(
        SwapsRepo.Head memory head,
        uint rightholder, 
        uint paidOfConsider
    ) external onlyKeeper {
        SwapsRepo.Head memory regHead = _repo.issueSwap(head, rightholder, paidOfConsider, _getGK());
        emit CreateSwap(regHead.seqOfSwap, rightholder, regHead.obligor, paidOfConsider, regHead.rateOfSwap);
    }
    
    function regSwap(SwapsRepo.Swap memory swap) external onlyKeeper 
        returns (SwapsRepo.Swap memory newSwap)
    {
        newSwap = _repo.regSwap(swap, _getGK());
        emit CreateSwap(newSwap.head.seqOfSwap, newSwap.body.rightholder, newSwap.head.obligor, newSwap.body.paidOfConsider, newSwap.head.rateOfSwap);
    }

    function transferSwap(uint256 seqOfSwap, uint to, uint amt)
        external onlyKeeper
    {
        SwapsRepo.Swap memory swap;

        swap.head = _repo.splitSwap(seqOfSwap, to, amt, _getGK());
        swap = _repo.swaps[swap.head.seqOfSwap];

        emit CreateSwap(swap.head.seqOfSwap, swap.body.rightholder, swap.head.obligor, swap.body.paidOfConsider, swap.head.rateOfSwap);
    }

    function crystalizeSwap(uint256 seqOfSwap, uint seqOfConsider, uint seqOfTarget)
        external onlyKeeper returns(SwapsRepo.Body memory body)
    {        
        body = _repo.swaps[seqOfSwap].crystalizeSwap(seqOfConsider, seqOfTarget, _getGK());
        emit CrystalizeSwap(seqOfSwap, seqOfConsider, body.paidOfConsider, seqOfTarget, body.paidOfTarget);
    }

    function lockSwap(uint256 seqOfSwap, bytes32 hashLock)
        external onlyKeeper returns(bool flag)
    {
        if (_repo.swaps[seqOfSwap].lockSwap(hashLock)) {
            emit LockSwap(seqOfSwap, hashLock);
            flag = true;
        }
    }

    function releaseSwap(uint256 seqOfSwap, string memory hashKey)
        external onlyKeeper returns(bool flag)
    {
        SwapsRepo.Swap storage swap = _repo.swaps[seqOfSwap];
        if (swap.releaseSwap(hashKey)) {
            emit ReleaseSwap(seqOfSwap, hashKey);
            flag = true;
        }
    }

    function execSwap(uint256 seqOfSwap) external onlyKeeper returns(bool flag) {
        if (_repo.swaps[seqOfSwap].execSwap()) {
            emit ExecSwap(seqOfSwap);
            flag = true;
        }
    }

    function revokeSwap(uint256 seqOfSwap) external onlyKeeper returns(bool flag){
        if (_repo.swaps[seqOfSwap].revokeSwap()) {
            emit RevokeSwap(seqOfSwap);
            flag = true;
        }
    }

    //###################
    //##    查询接口    ##
    //##################

    function counterOfSwap() external view returns (uint32) {
        return _repo.counterOfSwap();
    }

    function isSwapSeq(uint256 seqOfSwap) external view returns(bool flag) {
        flag = _repo.swaps[seqOfSwap].head.createDate > 0;
    }

    // ==== Swap ====

    function getSwap(uint256 seqOfSwap) external view returns(SwapsRepo.Swap memory) {
        return _repo.swaps[seqOfSwap];
    }

    function getAllSwaps() external view returns(SwapsRepo.Swap[] memory) {
        return _repo.getSwaps();
    }

    // ==== SNList ====

    function isSwapSN(bytes32 snOfSwap) external view returns(bool flag) {
        flag = _repo.snList.contains(snOfSwap);
    }

    function getSNList() external view returns (bytes32[] memory) {
        return _repo.snList.values();
    }
}
