// SPDX-License-Identifier: UNLICENSED

/* *
 *
 * v0.2.4
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

import "./IOwnable.sol";

contract Ownable is IOwnable {

    Admin private _owner;
    IRegCenter internal _rc;

    // ################
    // ##  Modifier  ##
    // ################

    modifier onlyOwner {
        require(
            _owner.addr == msg.sender,
            "O.onlyOwner: NOT"
        );
        _;
    }

    // #################
    // ##  Write I/O  ##
    // #################

    function init(
        address owner,
        address regCenter
    ) public {
        require(_owner.state == 0, "already inited");
        _owner.addr = owner;
        _owner.state = 1;
        _rc = IRegCenter(regCenter);
    }

    function setNewOwner(address acct) onlyOwner public {
        _owner.addr = acct;
        emit SetNewOwner(acct);
    }

    // ################
    // ##  Read I/O  ##
    // ################

    function getOwner() public view returns (address) {
        return _owner.addr;
    }

    function getRegCenter() public view returns (address) {
        return address(_rc);
    }

}
