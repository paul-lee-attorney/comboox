// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfSwaps.sol";

import "../../common/access/AccessControl.sol";

import "../../common/ruting/BOSSetting.sol";
import "../../common/ruting/ROMSetting.sol";

import "../../common/lib/EnumerableSet.sol";

contract RegisterOfSwaps is IRegisterOfSwaps, BOSSetting, ROMSetting, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using SwapsRepo for SwapsRepo.Repo;
    using SwapsRepo for SwapsRepo.Swap;
    using SwapsRepo for uint256;

    SwapsRepo.Repo private _repo;

    //#################
    //##    写接口    ##
    //#################

    function createSwap(
        uint256 sn,
        uint40 rightholder, 
        uint64 paidOfConsider
    ) external onlyKeeper {
        SwapsRepo.Head memory head = _repo.createSwap(sn, rightholder, paidOfConsider, _getROM());
        emit CrateSwap(head.seqOfSwap, rightholder, head.obligor, paidOfConsider, head.rateOfSwap);
    }

    function issueSwap(
        SwapsRepo.Head memory head,
        uint40 rightholder, 
        uint64 paidOfConsider
    ) external onlyKeeper {
        SwapsRepo.Head memory regHead = _repo.issueSwap(head, rightholder, paidOfConsider, _getROM());
        emit CrateSwap(regHead.seqOfSwap, rightholder, regHead.obligor, paidOfConsider, regHead.rateOfSwap);
    }
    
    function regSwap(SwapsRepo.Swap memory swap) external onlyKeeper {
        SwapsRepo.Head memory regHead = _repo.regSwap(swap, _getROM());
        SwapsRepo.Body memory body = _repo.swaps[regHead.seqOfSwap].body;
        emit CrateSwap(regHead.seqOfSwap, body.rightholder, regHead.obligor, body.paidOfConsider, regHead.rateOfSwap);
    }

    function transferSwap(uint256 seqOfSwap, uint40 to, uint64 amt)
        external onlyKeeper
    {
        SwapsRepo.Swap memory swap;

        swap.head = _repo.transferSwap(seqOfSwap, to, amt, _getROM());
        swap = _repo.swaps[swap.head.seqOfSwap];

        emit CrateSwap(swap.head.seqOfSwap, swap.body.rightholder, swap.head.obligor, swap.body.paidOfConsider, swap.head.rateOfSwap);
    }

    function crystalizeSwap(uint256 seqOfSwap, uint32 seqOfConsider, uint32 seqOfTarget)
        external onlyKeeper returns(SwapsRepo.Body memory body)
    {        
        body = _repo.swaps[seqOfSwap].crystalizeSwap(seqOfConsider, seqOfTarget, _getBOS());
        emit CrystalizeSwap(seqOfSwap, seqOfConsider, body.paidOfConsider, seqOfTarget, body.paidOfTarget);
    }

    function lockSwap(uint256 seqOfSwap, bytes32 hashLock)
        external onlyKeeper 
    {
        if (_repo.swaps[seqOfSwap].lockSwap(hashLock)) {
            emit LockSwap(seqOfSwap, hashLock);
        }
    }

    function releaseSwap(uint256 seqOfSwap, string memory hashKey)
        external onlyKeeper
    {
        SwapsRepo.Swap storage swap = _repo.swaps[seqOfSwap];
        if (swap.releaseSwap(hashKey)) emit ReleaseSwap(seqOfSwap, hashKey);
    }

    function execSwap(uint256 seqOfSwap) external onlyKeeper {
        if (_repo.swaps[seqOfSwap].execSwap())
            emit ExecSwap(seqOfSwap);
    }

    function revokeSwap(uint256 seqOfSwap) external onlyKeeper {
        if (_repo.swaps[seqOfSwap].revokeSwap()) {
            emit RevokeSwap(seqOfSwap);
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

    function getSwaps() external view returns(SwapsRepo.Swap[] memory) {
        return _repo.getSwaps();
    }

    // ==== SNList ====

    function isSwapSN(uint256 snOfSwap) external view returns(bool flag) {
        flag = _repo.snList.contains(snOfSwap);
    }

    function getSNList() external view returns (uint256[] memory) {
        return _repo.snList.values();
    }
}
