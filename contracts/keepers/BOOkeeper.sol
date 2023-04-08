// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOOKeeper.sol";

import "../common/access/AccessControl.sol";

// import "../common/ruting/BOOSetting.sol";
// import "../common/ruting/ROSSetting.sol";

contract BOOKeeper is IBOOKeeper, AccessControl {

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(uint256 seqOfOpt, uint256 caller) {
        require(_gk.getBOO().isRightholder(seqOfOpt, caller), 
            "BOOK.mf.OR: NOT rightholder");
        _;
    }

    modifier onlyObligor(uint256 seqOfOpt, uint256 caller) {
        require(_gk.getBOO().isObligor(seqOfOpt, caller), 
            "BOOK.mf.OO: NOT obligor");
        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

    function updateOracle(
        uint256 seqOfOpt,
        uint64 d1,
        uint64 d2,
        uint64 d3
    ) external onlyDirectKeeper {
        _gk.getBOO().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt, uint256 caller)
        external
        onlyKeeper
        onlyRightholder(seqOfOpt, caller)
    {
        _gk.getBOO().execOption(seqOfOpt);
    }

    function placeSwapOrder(
        uint256 seqOfOpt,
        uint32 seqOfConsider,
        uint32 paidOfConsider,
        uint32 seqOfTarget,
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        SwapsRepo.Swap memory swap = 
            _gk.getBOO().createSwapOrder(seqOfOpt, seqOfConsider, paidOfConsider, seqOfTarget);
        swap = _gk.getROS().regSwap(swap);
        swap.body = _gk.getROS().crystalizeSwap(swap.head.seqOfSwap, seqOfConsider, seqOfTarget);
        _gk.getBOO().regSwapOrder(seqOfOpt, swap);
    }

    function lockSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        bytes32 hashLock, 
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        OptionsRepo.Brief memory brf = _gk.getBOO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().lockSwap(brf.seqOfSwap, hashLock);
    }

    function releaseSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        string memory hashKey, 
        uint256 caller
    ) external onlyKeeper onlyObligor(seqOfOpt, caller) {
        OptionsRepo.Brief memory brf = _gk.getBOO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().releaseSwap(brf.seqOfSwap, hashKey);
    }

    function execSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf,
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        OptionsRepo.Brief memory brf = _gk.getBOO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().execSwap(brf.seqOfSwap);
    }

    function revokeSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf,
        uint256 caller
    ) external onlyKeeper {
        require(_gk.getBOO().isRightholder(seqOfOpt, caller)||
            _gk.getBOO().isObligor(seqOfOpt, caller), "BOOK.RSO: not interested party");

        OptionsRepo.Brief memory brf = _gk.getBOO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().execSwap(brf.seqOfSwap);
    }    
}
