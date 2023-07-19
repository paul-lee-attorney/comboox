// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IBOOKeeper.sol";

import "../common/access/AccessControl.sol";

contract BOOKeeper is IBOOKeeper, AccessControl {

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(uint256 seqOfOpt, uint256 caller) {
        require(_getGK().getBOO().isRightholder(seqOfOpt, caller), 
            "BOOK.mf.OR: NOT rightholder");
        _;
    }

    modifier onlyObligor(uint256 seqOfOpt, uint256 caller) {
        require(_getGK().getBOO().isObligor(seqOfOpt, caller), 
            "BOOK.mf.OO: NOT obligor");
        _;
    }

    // ##################
    // ##    Option    ##
    // ##################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external onlyDK {
        _getGK().getBOO().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt, uint256 caller)
        external
        onlyKeeper
        onlyRightholder(seqOfOpt, caller)
    {
        _getGK().getBOO().execOption(seqOfOpt);
    }

    function placeSwapOrder(
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget,
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        IGeneralKeeper _gk = _getGK();
        IBookOfOptions _boo = _gk.getBOO(); 
        IRegisterOfSwaps _ros = _gk.getROS();
        
        SwapsRepo.Swap memory swap = 
            _boo.createSwapOrder(seqOfOpt, seqOfConsider, paidOfConsider, seqOfTarget);
        swap = _ros.regSwap(swap);
        swap.body = _ros.crystalizeSwap(swap.head.seqOfSwap, seqOfConsider, seqOfTarget);
        _boo.regSwapOrder(seqOfOpt, swap);
    }

    function lockSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        bytes32 hashLock, 
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        IGeneralKeeper _gk = _getGK();
    
        OptionsRepo.Brief memory brf = _gk.getBOO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().lockSwap(brf.seqOfSwap, hashLock);
    }

    function releaseSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        string memory hashKey 
    ) external onlyKeeper {
        IGeneralKeeper _gk = _getGK();

        OptionsRepo.Brief memory brf = _gk.getBOO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().releaseSwap(brf.seqOfSwap, hashKey);
    }

    function execSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf,
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        IGeneralKeeper _gk = _getGK();
    
        OptionsRepo.Brief memory brf = _gk.getBOO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().execSwap(brf.seqOfSwap);
    }

    function revokeSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf,
        uint256 caller
    ) external onlyKeeper {
        IGeneralKeeper _gk = _getGK();
        IBookOfOptions _boo = _gk.getBOO(); 

        require(_boo.isRightholder(seqOfOpt, caller)||
            _boo.isObligor(seqOfOpt, caller), "BOOK.RSO: not interested party");

        OptionsRepo.Brief memory brf = _boo.getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().execSwap(brf.seqOfSwap);
    }    
}
