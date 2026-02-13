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
import "../../openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "../../openzeppelin/proxy/utils/Initializable.sol";

contract Ownable is IOwnable, Initializable, UUPSUpgradeable {

    Admin public owner;
    address public rc;

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
        require(owner.state == 0, "already inited");
        require(regCenter_ != address(0), "zero regCenter");
        owner.addr = owner_;
        owner.state = 1;
        rc = regCenter_;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    // ################
    // ##  Modifier  ##
    // ################

    modifier onlyOwner virtual {
        require(
            owner.addr == msg.sender,
            "O.onlyOwner: NOT"
        );
        _;
    }

    // #################
    // ##  Write I/O  ##
    // #################

    function setNewOwner(address acct) onlyOwner public {
        owner.addr = acct;
        emit SetNewOwner(acct);
    }

}
