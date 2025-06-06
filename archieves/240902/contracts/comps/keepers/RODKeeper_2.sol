// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "../common/access/RoyaltyCharge.sol";

import "./IRODKeeper_2.sol";

contract RODKeeper_2 is IRODKeeper_2, RoyaltyCharge {    

    //###############
    //##   Write   ##
    //###############

    // ==== Directors ====

    function takeSeat(
        uint256 seqOfMotion,
        uint256 seqOfPos,
        address msgSender 
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);

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
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);

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
        address msgSender 
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);

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
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);

        IMeetingMinutes _bmm = _gk.getBMM();

        require(_bmm.getMotion(seqOfMotion).head.typeOfMotion == 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer), 
            "BODK.removeOfficer: not a suitable motion");

        _bmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().removeOfficer(seqOfPos);        
    }

    // ==== Quit ====

    function quitPosition(uint256 seqOfPos, address msgSender)
        external onlyDK 
    {
        uint caller = _msgSender(msgSender, 18000);
        _gk.getROD().quitPosition(seqOfPos, caller);
    }

}
