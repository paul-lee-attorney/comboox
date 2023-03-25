// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IROSKeeper.sol";

import "../common/access/AccessControl.sol";

import "../common/ruting/BOSSetting.sol";
import "../common/ruting/ROSSetting.sol";

import "../common/lib/EnumerableSet.sol";
import "../common/lib/SwapsRepo.sol";

contract ROSKeeper is IROSKeeper, ROSSetting, BOSSetting, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using SwapsRepo for SwapsRepo.Repo;
    using SwapsRepo for SwapsRepo.Swap;
    using SwapsRepo for uint256;

    //#################
    //##    写接口    ##
    //#################

    function createSwap(
        uint256 sn,
        uint40 rightholder, 
        uint64 paidOfConsider,
        uint40 caller
    ) external onlyDirectKeeper {
        require(caller == uint40(sn >> 40), "ROSK.CS: not obligor");
        _getROS().createSwap(sn, rightholder, paidOfConsider);
    }

    function transferSwap(uint256 seqOfSwap, uint40 to, uint64 amt, uint40 caller)
        external onlyDirectKeeper
    {
        IRegisterOfSwaps _ros;

        SwapsRepo.Body memory body = _ros.getSwap(seqOfSwap).body;
        require(body.rightholder == caller, "ROSK.TS: not rightholder");

        _ros.transferSwap(seqOfSwap, to, amt);
    }

    function crystalizeSwap(uint256 seqOfSwap, uint32 seqOfConsider, uint32 seqOfTarget, uint40 caller)
        external onlyDirectKeeper
    {   
        IRegisterOfSwaps _ros;

        SwapsRepo.Body memory body = _ros.getSwap(seqOfSwap).body;
        require(body.rightholder == caller, "ROSK.CS: not rightholder");

        body = _ros.crystalizeSwap(seqOfSwap, seqOfConsider, seqOfTarget);

        IBookOfShares _bos;
        _bos.decreaseCleanPaid(body.seqOfConsider, body.paidOfConsider);
        _bos.decreaseCleanPaid(body.seqOfTarget, body.paidOfTarget);        
    }

    function lockSwap(uint256 seqOfSwap, bytes32 hashLock, uint40 caller)
        external onlyDirectKeeper 
    {
        IRegisterOfSwaps _ros;

        SwapsRepo.Body memory body = _ros.getSwap(seqOfSwap).body;
        require(body.rightholder == caller, "ROSK.LS: not rightholder");

        _ros.lockSwap(seqOfSwap, hashLock);
    }

    function releaseSwap(uint256 seqOfSwap, string memory hashKey, uint40 caller)
        external onlyDirectKeeper
    {
        IRegisterOfSwaps _ros;

        SwapsRepo.Swap memory swap = _ros.getSwap(seqOfSwap);
        require(swap.head.obligor == caller, "ROSK.RS: not obligor");

        _ros.releaseSwap(seqOfSwap, hashKey);        

        IBookOfShares _bos;
        _bos.increaseCleanPaid(swap.body.seqOfConsider, swap.body.paidOfConsider);
        _bos.increaseCleanPaid(swap.body.seqOfTarget, swap.body.paidOfTarget);        
    }

    function execSwap(uint256 seqOfSwap, uint40 caller) external onlyDirectKeeper {
        IRegisterOfSwaps _ros;

        SwapsRepo.Swap memory swap = _ros.getSwap(seqOfSwap);
        require(swap.body.rightholder == caller, "ROSK.ES: not rightholder");

        _ros.execSwap(seqOfSwap);

        IBookOfShares _bos;
        SharesRepo.Head memory headOfTarget = _bos.getShare(swap.body.seqOfTarget).head;
        SharesRepo.Head memory headOfConsider = _bos.getShare(swap.body.seqOfConsider).head;

        _bos.transferShare(
            swap.body.seqOfTarget, 
            swap.body.paidOfTarget, 
            swap.body.paidOfTarget, 
            swap.body.rightholder, 
            headOfConsider.price * 10000 / swap.head.rateOfSwap
        );

        _bos.transferShare(
            swap.body.seqOfConsider, 
            swap.body.paidOfConsider, 
            swap.body.paidOfConsider, 
            swap.head.obligor,
            headOfTarget.price * swap.head.rateOfSwap / 10000
        ); 
    }

    function revokeSwap(uint256 seqOfSwap, uint40 caller) external onlyDirectKeeper {
        IRegisterOfSwaps _ros;

        SwapsRepo.Swap memory swap = _ros.getSwap(seqOfSwap);
        require(swap.head.obligor == caller || swap.body.rightholder == caller, 
            "ROSK.RS: neither rightholder nor obligor");

        _ros.revokeSwap(seqOfSwap);
    }
}
