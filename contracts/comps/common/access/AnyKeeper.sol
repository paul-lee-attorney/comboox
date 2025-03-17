// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2025 LI LI @ JINGTIAN & GONGCHENG.
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

import "./AccessControl.sol";

contract AnyKeeper is AccessControl {

    function _isKeeper(address msgSender) internal view returns(bool) {
        uint i = 1;
        address keeper = _gk.getKeeper(i);

        if (msgSender == _dk.addr) {
            return true;
        }
 
        while(keeper != address(0)) {
            if (keeper == msgSender) {
                return true;
            }
            i++;
            keeper = _gk.getKeeper(i);
        }

        return false;
    }

    modifier anyKeeper() {
        require(_isKeeper(msg.sender),
            "AnyKeeper: not");
        _;
    }

}