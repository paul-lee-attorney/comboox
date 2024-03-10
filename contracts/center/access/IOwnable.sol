// SPDX-License-Identifier: UNLICENSED

/* *
 * V.0.2.1
 *
 * Copyright (c) 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
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

import "../IRegCenter.sol";

interface IOwnable {

    struct Admin{
        address addr;
        uint8 state;
    }

    event TransferOwnership(address indexed owner);

    // #################
    // ##    Write    ##
    // #################

    function init(address owner, address regCenter) external;

    function transferOwnership(address acct) external;

    // ##############
    // ##   Read   ##
    // ##############

    function getOwner() external view returns (address);

    function getRegCenter() external view returns (address);

}
