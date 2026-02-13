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

import "./IAccessControl.sol";
import "../../../center/access/Ownable.sol";
import "../../../lib/InterfacesHub.sol";

contract AccessControl is IAccessControl, Ownable {
    using InterfacesHub for address;

    enum Books {
        ZeroPoint,
        ROC,        //1
        ROD,
        BMM,
        ROM,
        GMM,        //5
        ROA,
        ROO,
        ROP,
        ROS,
        LOO,        //10
        ROI,
        Bank,
        Blank_1,
        Blank_2,
        Cashier,    //15
        ROR
    }

    enum Keepers {
        ZeroPoint,
        ROCK,       //1
        RODK,
        BMMK,
        ROMK,
        GMMK,       //5
        ROAK,
        ROOK,
        ROPK,
        SHAK,
        LOOK,       //10
        ROIK,       
        Accountant,
        Blank_1,
        Blank_2,
        Blank_3,    //15
        RORK
    }

    /// @notice Direct keeper admin record.
    Admin public dk;
    /// @notice General keeper address.
    address public gk;

    // ==== UUPSUpgradable ====

    /// @dev Storage gap for upgrade safety.
    uint[50] private __gap;

    function initKeepers(
        address directKeeper, 
        address generalKeeper
    ) external virtual reinitializer(2) {
        _initKeepers(directKeeper, generalKeeper);
    }

    /// @dev Authorize UUPS upgrades. Caller must be GK or DK.
    function _authorizeUpgrade(address newImplementation) internal virtual override {
        require(
            msg.sender == gk ||
            msg.sender == dk.addr,
            "AC._authorizeUpgrade: NOT GK or DK"
        );
        require(rc.getRC().tempExist(newImplementation),
            "AC.authUpgrade: temp NOT exist");
    }

    function upgradeDocTo(address newImplementation) external virtual {
        upgradeTo(newImplementation);
        rc.getRC().upgradeDoc(newImplementation);
    }

    // ################
    // ##  Modifier  ##
    // ################

    /// @notice Restrict to direct keeper.
    modifier onlyDK {
        require(dk.addr == msg.sender,
            "AC.onlyDK: not");
        _;
    }

    /// @notice Restrict to general keeper or direct keeper.
    modifier onlyKeeper virtual {
        require(gk == msg.sender || 
            dk.addr == msg.sender, 
            "AC.onlyKeeper: NOT");
        _;
    }

    /// @notice Restrict to delegatecall context on GeneralKeeper.
    modifier onlyGKProxy {
        require(address(this) == gk, "AC.onlyGKProxy: NOT");
        _;
    }

    // #################
    // ##    Write    ##
    // #################

    /// @notice Initialize keeper addresses (one-time).
    /// @param directKeeper Direct keeper address.
    /// @param generalKeeper General keeper address.
    function _initKeepers(address directKeeper,address generalKeeper) internal {
        require(dk.state == 0, 
            "AC.initKeepers: already inited");
        dk.addr = directKeeper;
        gk = generalKeeper;
        dk.state = 1;
    }

    /// @notice Update direct keeper address.
    /// @param acct New direct keeper address.
    function setDirectKeeper(address acct) external onlyDK {
        dk.addr = acct;
        emit SetDirectKeeper(acct);
    }

    /// @notice Reclaim keeper control from a subordinate contract.
    /// @param target Target contract address.
    function takeBackKeys (address target) external onlyDK {
        IAccessControl(target).setDirectKeeper(msg.sender);
    }

}
