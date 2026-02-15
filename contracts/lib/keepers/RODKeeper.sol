// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
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

pragma solidity ^0.8.24;

import "../utils/RoyaltyCharge.sol";

library RODKeeper {    
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // uint32(uint(keccak256("RODKeeper")));
    uint public constant TYPE_OF_DOC = 0x4218a169;
    uint public constant VERSION = 1;

    //###############
    //##   Error   ##
    //###############

    error RODK_WrongTypeOfMotion(bytes32 reason);
    
    // ==== Directors ====

    function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        IMeetingMinutes _gmm = _gk.getGMM();
        
        if (_gmm.getMotion(seqOfMotion).head.typeOfMotion != 
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer)) {
            revert RODK_WrongTypeOfMotion(bytes32("RODK_NotElectOfficer"));
        }

        _gmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().takePosition(seqOfPos, caller);
    }

    function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        IMeetingMinutes _gmm = _gk.getGMM();

        if (_gmm.getMotion(seqOfMotion).head.typeOfMotion != 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer)) {
            revert RODK_WrongTypeOfMotion(bytes32("RODK_NotRemoveOfficer"));
        }

        _gmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().removeOfficer(seqOfPos);
    }

    // ==== Officers ====

    function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        IMeetingMinutes _bmm = _gk.getBMM();
    
        if (_bmm.getMotion(seqOfMotion).head.typeOfMotion != 
            uint8(MotionsRepo.TypeOfMotion.ElectOfficer)) {
            revert RODK_WrongTypeOfMotion(bytes32("RODK_NotElectOfficer"));
        }

        _bmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().takePosition(seqOfPos, caller);
    }

    function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        IMeetingMinutes _bmm = _gk.getBMM();

        if (_bmm.getMotion(seqOfMotion).head.typeOfMotion != 
            uint8(MotionsRepo.TypeOfMotion.RemoveOfficer)) {
            revert RODK_WrongTypeOfMotion(bytes32("RODK_NotRemoveOfficer"));
        }

        _bmm.execResolution(seqOfMotion, seqOfPos, caller);
        _gk.getROD().removeOfficer(seqOfPos);        
    }

    // ==== Quit ====

    function quitPosition(uint256 seqOfPos) external  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);
        _gk.getROD().quitPosition(seqOfPos, caller);
    }

}
