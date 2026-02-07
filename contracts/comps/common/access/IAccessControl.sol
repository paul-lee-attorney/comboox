// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
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

interface IAccessControl {

    // ##################
    // ##   Event      ##
    // ##################

    event SetDirectKeeper(address indexed keeper);

    // event SetNewGK(address indexed gk);

    // ##################
    // ##    Write     ##
    // ##################

    // function initKeepers(address dk,address gk) external;

    // function setNewGK(address gk) external;

    function initialize(
        address owner, address regCenter,
        address directKeeper, address generalKeeper
    ) external;


    function setDirectKeeper(address keeper) external;

    function takeBackKeys(address target) external;

    // ##################
    // ##   Read I/O   ##
    // ##################

    // function getDK() external view returns (address);
}
