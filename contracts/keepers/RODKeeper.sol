// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IRODKeeper.sol";

contract RODKeeper is IRODKeeper, AccessControl {
    // using RulesParser for bytes32;

    

    //##################
    //##   Modifier   ##
    //##################

    modifier directorExist(uint256 acct) {
        require(_getGK().getROD().isDirector(acct), 
            "BODK.DE: not director");
        _;
    }

    //###############
    //##   Write   ##
    //###############

    // ==== Directors ====

    function takeSeat(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IMeetingMinutes _gmm = _gk.getGMM();
        
        require(_gmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer), 
            "BODK.takeSeat: not a suitable motion");

        _gmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().takePosition(seqOfPos, caller);
    }

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IMeetingMinutes _gmm = _gk.getGMM();

        require(_gmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer), 
            "BODK.removeDirector: not a suitable motion");

        _gmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().removeOfficer(seqOfPos);
    }

    // ==== Officers ====

    function takePosition(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IMeetingMinutes _bmm = _gk.getBMM();
    
        require(_bmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer), 
            "BODK.takePos: not a suitable motion");

        _bmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().takePosition(seqOfPos, caller);
    }

    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external onlyDK {
        IGeneralKeeper _gk = _getGK();
        IMeetingMinutes _bmm = _gk.getBMM();

        require(_bmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer), 
            "BODK.removeOfficer: not a suitable motion");

        _bmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().removeOfficer(seqOfPos);        
    }

    // ==== Quit ====

    function quitPosition(uint256 seqOfPos, uint caller)
        external onlyDK 
    {
        _getGK().getROD().quitPosition(seqOfPos, caller);
    }



}
