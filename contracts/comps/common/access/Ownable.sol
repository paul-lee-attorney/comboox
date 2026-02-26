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

import "./IOwnable.sol";
import "../../../openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "../../../openzeppelin/proxy/utils/Initializable.sol";

contract Ownable is IOwnable, Initializable, UUPSUpgradeable {

    Admin internal _owner;
    address internal _rc;

    // ==== UUPSUpgradable ====

    uint[50] private __gap;

    constructor(){
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address regCenter_
    ) external virtual initializer {
        _init(owner_, regCenter_);
    }

    function _init(
        address owner_,
        address regCenter_
    ) internal {
        if (_owner.state != 0) {
            revert Ownable_WrongState(bytes32("Ownable_AlreadyInited"));
        }
        if (regCenter_ == address(0)) {
            revert Ownable_WrongInput(bytes32("Ownable_ZeroRegCenter"));
        }

        _owner.addr = owner_;
        _owner.state = 1;
        _rc = regCenter_;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    // ################
    // ##  Modifier  ##
    // ################

    modifier onlyOwner virtual {
        if (_owner.addr != msg.sender) {
            revert Ownable_WrongParty(bytes32("Ownable_NotOwner"));
        }
        _;
    }

    // #################
    // ##  Write I/O  ##
    // #################

    function setNewOwner(address acct) onlyOwner public {
        _owner.addr = acct;
        emit SetNewOwner(acct);
    }

    // #################
    // ##   Read I/O  ##
    // #################

    function getOwner() external view virtual returns (address) {
        return _owner.addr;
    }

    function getRegCenter() external view returns (address) {
        return _rc;
    }

}
