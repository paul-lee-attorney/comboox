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

import "../lib/UsdLockersRepo.sol";
import "./ERC20/IUSDC.sol";

interface ICashLockers {

    struct TransferAuth{
        address from;
        address to;
        uint256 value;
        uint256 validAfter;
        uint256 validBefore;
        bytes32 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // ##################
    // ##    Event     ##
    // ##################

    event LockUsd(
        address indexed from, address indexed to, uint indexed amt,
        uint expireDate, bytes32 lock
    );

    event LockConsideration(
        address indexed from, address indexed to,
        uint indexed amt, uint expireDate, bytes32 lock
    );

    event UnlockUsd(
        address indexed from, address indexed to, uint indexed amt, bytes32 lock
    );

    event WithdrawUsd(address indexed from, uint indexed amt, bytes32 lock);

    // ##################
    // ##    Write     ##
    // ##################

    function lockUsd(
        TransferAuth memory auth, address to, uint expireDate, bytes32 lock
    ) external;

    function lockConsideration(
        TransferAuth memory auth, address to, uint expireDate, 
        address counterLocker, bytes calldata payload, bytes32 hashLock
    ) external;

    function unlockUsd(bytes32 lock, string memory key) external;

    function withdrawUsd(bytes32 lock) external;

    //##################
    //##   Read I/O   ##
    //##################

    // function usdc() external view returns(IUSDC);

    function isLocked(bytes32 lock) external view returns(bool);

    function counterOfLockers() external view returns(uint);

    function getHeadOfLocker(bytes32 lock) external view returns(UsdLockersRepo.Head memory);

    function getLocker(bytes32 lock) external view returns(UsdLockersRepo.Locker memory);

    function getLockersList() external view returns (bytes32[] memory);

    function custodyOf(address acct) external view returns(uint);

    function totalCustody() external view returns(uint);

}