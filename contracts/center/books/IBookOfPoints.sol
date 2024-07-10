// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "../../lib/LockersRepo.sol";

interface IBookOfPoints {

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Points ====

    event LockPoints(bytes32 indexed headSn, bytes32 indexed hashLock);

    event LockPointsInCoffer(address indexed beneficiary, uint indexed amt);

    event LockConsideration(bytes32 indexed headSn, address indexed counterLocker, bytes payload, bytes32 indexed hashLock);

    event PickupPoints(bytes32 indexed head);

    event PickupPointsFromCoffer(address indexed from, address indexed to, uint indexed amt);

    event WithdrawPoints(bytes32 indexed head);
    
    event WithdrawPointsFromLocker(address indexed from, uint indexed amt);


    // ##################
    // ##    Write     ##
    // ##################

    function mint(address to, uint amt) external;

    function burn(uint amt) external;

    function mintAndLockPoints(uint to, uint amtOfGLee, uint expireDate, bytes32 hashLock) external;

    // ==== Points Trade ====

    function lockPoints(uint to, uint amtOfGLee, uint expireDate, bytes32 hashLock) external;

    function lockConsideration(uint to, uint amtOfGLee, uint expireDate, address counterLocker, bytes memory payload, bytes32 hashLock) external;

    function pickupPoints(bytes32 hashLock, string memory hashKey) external;

    function withdrawPoints(bytes32 hashLock) external;

    // ##################
    // ##    Read      ##
    // ##################

    function getDepositAmt(address from) external view returns(uint);

    function getLocker(bytes32 hashLock) external view 
        returns (LockersRepo.Locker memory locker);

    function getLocksList() external view 
        returns (bytes32[] memory);
}
