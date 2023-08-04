// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IROOKeeper.sol";

import "../common/access/AccessControl.sol";

contract ROOKeeper is IROOKeeper, AccessControl {

    // ##################
    // ##   Modifier   ##
    // ##################

    modifier onlyRightholder(uint256 seqOfOpt, uint256 caller) {
        require(_getGK().getROO().isRightholder(seqOfOpt, caller), 
            "BOOK.mf.OR: NOT rightholder");
        _;
    }

    modifier onlyObligor(uint256 seqOfOpt, uint256 caller) {
        require(_getGK().getROO().isObligor(seqOfOpt, caller), 
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
        _getGK().getROO().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt, uint256 caller)
        external
        onlyKeeper
        onlyRightholder(seqOfOpt, caller)
    {
        _getGK().getROO().execOption(seqOfOpt);
    }

    function placeSwapOrder(
        uint256 seqOfOpt,
        uint seqOfConsider,
        uint paidOfConsider,
        uint seqOfTarget,
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfOptions _roo = _gk.getROO(); 
        IRegisterOfSwaps _ros = _gk.getROS();
        
        SwapsRepo.Swap memory swap = 
            _roo.createSwapOrder(seqOfOpt, seqOfConsider, paidOfConsider, seqOfTarget);
        swap = _ros.regSwap(swap);
        swap.body = _ros.crystalizeSwap(swap.head.seqOfSwap, seqOfConsider, seqOfTarget);
        _roo.regSwapOrder(seqOfOpt, swap);
    }

    function lockSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        bytes32 hashLock, 
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        IGeneralKeeper _gk = _getGK();
    
        OptionsRepo.Brief memory brf = _gk.getROO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().lockSwap(brf.seqOfSwap, hashLock);
    }

    function releaseSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf, 
        string memory hashKey 
    ) external onlyKeeper {
        IGeneralKeeper _gk = _getGK();

        OptionsRepo.Brief memory brf = _gk.getROO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().releaseSwap(brf.seqOfSwap, hashKey);
    }

    function execSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf,
        uint256 caller
    ) external onlyKeeper onlyRightholder(seqOfOpt, caller) {
        IGeneralKeeper _gk = _getGK();
    
        OptionsRepo.Brief memory brf = _gk.getROO().getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().execSwap(brf.seqOfSwap);
    }

    function revokeSwapOrder(
        uint256 seqOfOpt, 
        uint256 seqOfBrf,
        uint256 caller
    ) external onlyKeeper {
        IGeneralKeeper _gk = _getGK();
        IRegisterOfOptions _roo = _gk.getROO(); 

        require(_roo.isRightholder(seqOfOpt, caller)||
            _roo.isObligor(seqOfOpt, caller), "BOOK.RSO: not interested party");

        OptionsRepo.Brief memory brf = _roo.getBrief(seqOfOpt, seqOfBrf);
        _gk.getROS().execSwap(brf.seqOfSwap);
    }    
}
