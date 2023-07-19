// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./IBODKeeper.sol";

contract BODKeeper is IBODKeeper, AccessControl {
    // using RulesParser for bytes32;

    IGeneralKeeper private _gk = _getGK();
    IBookOfDirectors private _bod = _gk.getBOD();
    IMeetingMinutes private _bmm = _gk.getBMM();
    IMeetingMinutes private _gmm = _gk.getGMM();

    //##################
    //##   Modifier   ##
    //##################

    modifier directorExist(uint256 acct) {
        require(_bod.isDirector(acct), 
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
        
        require(_gmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer), 
            "BODK.takeSeat: not a suitable motion");

        _gmm.execResolution(seqOfMotion, seqOfPos, caller);
        _bod.takePosition(seqOfPos, caller);
    }

    function removeDirector (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external onlyDK {

        require(_gmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer), 
            "BODK.removeDirector: not a suitable motion");

        _gmm.execResolution(seqOfMotion, seqOfPos, caller);
        _bod.removeOfficer(seqOfPos);
    }

    // ==== Officers ====

    function takePosition(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        uint caller 
    ) external onlyDK {
    
        require(_bmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer), 
            "BODK.takePos: not a suitable motion");

        _bmm.execResolution(seqOfMotion, seqOfPos, caller);
        _bod.takePosition(seqOfPos, caller);
    }

    function removeOfficer (
        uint256 seqOfMotion, 
        uint256 seqOfPos,
        uint caller
    ) external onlyDK {
        
        require(_bmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer), 
            "BODK.removeOfficer: not a suitable motion");

        _bmm.execResolution(seqOfMotion, seqOfPos, caller);
        _bod.removeOfficer(seqOfPos);        
    }

    // ==== Quit ====

    function quitPosition(uint256 seqOfPos, uint caller)
        external onlyDK 
    {
        _bod.quitPosition(seqOfPos, caller);
    }



}
