// SPDX-License-Identifier: UNLICENSED

/* *
 * V.0.2.4
 *
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

pragma solidity ^0.8.8;

import "./IAccessControl.sol";
import "../../../center/access/Ownable.sol";
import "../../../lib/InterfacesHub.sol";

contract AccessControl is IAccessControl, Ownable {
    using InterfacesHub for address;

    enum Books {
        ZeroPoint,
        ROC,
        ROD,
        BMM,
        ROM,
        GMM,
        ROA,
        ROO,
        ROP,
        ROS,
        LOO,
        ROI,
        Bank,
        Blank_1,
        Blank_2,
        Cashier,
        ROR
    }

    enum Keepers {
        ZeroPoint,
        ROCK,
        RODK,
        BMMK,
        ROMK,
        GMMK,
        ROAK,
        ROOK,
        ROPK,
        SHAK,
        LOOK,
        ROIK,
        Accountant,
        Blank_1,
        Blank_2,
        Blank_3,
        RORK
    }

    // direct keeper
    Admin public dk;
    // general keeper
    address public gk;

    uint[50] private __gap;

    function initialize(
        address owner, address regCenter,
        address directKeeper, address generalKeeper
    ) external virtual initializer {
        _init(owner, regCenter);
        _initKeepers(directKeeper, generalKeeper);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        require(
            msg.sender == gk ||
            msg.sender == dk.addr,
            "AC._authorizeUpgrade: NOT GK or DK"
        );
    }

    function upgradeTo(newImplementation) external virtual override {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
        rc.obtainBOD().upgradeDoc(newImplementation);
    }

    // ################
    // ##  Modifier  ##
    // ################

    modifier onlyDK {
        require(dk.addr == msg.sender,
            "AC.onlyDK: not");
        _;
    }

    modifier onlyKeeper virtual {
        require(gk.getGK().isKeeper(msg.sender) || 
            dk.addr == msg.sender, 
            "AC.onlyKeeper: NOT");
        _;
    }

    // #################
    // ##    Write    ##
    // #################


    function _initKeepers(address directKeeper,address generalKeeper) internal {
        require(dk.state == 0, 
            "AC.initKeepers: already inited");
        dk.addr = directKeeper;
        gk = generalKeeper;
        dk.state = 1;
    }

    function setDirectKeeper(address acct) external onlyDK {
        dk.addr = acct;
        emit SetDirectKeeper(acct);
    }

    function takeBackKeys (address target) external onlyDK {
        IAccessControl(target).setDirectKeeper(msg.sender);
    }

}
