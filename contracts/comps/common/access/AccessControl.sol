// SPDX-License-Identifier: UNLICENSED

/* *
 * V.0.2.4
 *
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

import "./IAccessControl.sol";
import "../../../center/access/Ownable.sol";

contract AccessControl is IAccessControl, Ownable {

    Admin internal _dk;
    IBaseKeeper internal _gk;

    // ################
    // ##  Modifier  ##
    // ################

    modifier onlyDK {
        require(_dk.addr == msg.sender,
            "AC.onlyDK: not");
        _;
    }

    modifier onlyKeeper {
        require(_gk.isKeeper(msg.sender) || 
            _dk.addr == msg.sender, 
            "AC.onlyKeeper: NOT");
        _;
    }

    // #################
    // ##    Write    ##
    // #################

    function initKeepers(address dk,address gk) external {
        require(_dk.state == 0, 
            "AC.initKeepers: already inited");
        _dk.addr = dk;
        _gk = IBaseKeeper(gk);
        _dk.state = 1;
    }

    function setNewGK(address gk) external onlyDK {
        _gk = IBaseKeeper(gk);
        emit SetNewGK(gk);
    }

    function setDirectKeeper(address acct) external onlyDK {
        _dk.addr = acct;
        emit SetDirectKeeper(acct);
    }

    function takeBackKeys (address target) external onlyDK {
        IAccessControl(target).setDirectKeeper(msg.sender);
    }

    // ##############
    // ##   Read   ##
    // ##############

    function getDK() external view returns (address) {
        return _dk.addr;
    }

}
