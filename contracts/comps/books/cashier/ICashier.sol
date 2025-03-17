// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.4
 *
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

import "../../../center/ERC20/IUSDC.sol";

import "../../../lib/UsdLockersRepo.sol";

interface ICashier {

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

    event ReceiveUsd(address indexed from, uint indexed amt);

    event ForwardUsd(address indexed from, address indexed to, uint indexed amt);

    event CustodyUsd(address indexed from, uint indexed amt);

    event ReleaseUsd(address indexed from, address indexed to, uint indexed amt);

    event TransferUsd(address indexed to, uint indexed amt);

    event LockUsd(address indexed from, address indexed to, uint indexed amt,
        uint expireDate, bytes32 lock);

    event LockConsideration(address indexed from, address indexed to,
        uint indexed amt, uint expireDate, bytes32 lock);

    event UnlockUsd(address indexed from, address indexed to, uint indexed amt, bytes32 lock);

    event WithdrawUsd(address indexed from, uint indexed amt, bytes32 lock);

    //###############
    //##   Write   ##
    //###############

    function collectUsd(TransferAuth memory auth) external;

    function forwardUsd(TransferAuth memory auth, address to) external;

    function custodyUsd(TransferAuth memory auth) external;

    function releaseUsd(address from, address to, uint amt) external;

    function transferUsd(address to, uint amt) external;

    function lockUsd(
        TransferAuth memory auth, address to, uint expireDate, bytes32 lock
    ) external;

    function lockConsideration(
        TransferAuth memory auth, address to, uint expireDate, 
        address counterLocker, bytes calldata payload, bytes32 hashLock
    ) external;

    function unlockUsd(
        bytes32 lock, string memory key, address msgSender
    ) external;

    function withdrawUsd(
        bytes32 lock, address msgSender
    ) external;

    //##################
    //##   Read I/O   ##
    //##################

    function isLocked(bytes32 lock) external view returns(bool);

    function counterOfLockers() external view returns(uint);

    function getHeadOfLocker(bytes32 lock) external view returns(UsdLockersRepo.Head memory);

    function getLocker(bytes32 lock) external view returns(UsdLockersRepo.Locker memory);

    function getLockersList() external view returns (bytes32[] memory);

    function custodyOf(address acct) external view returns(uint);

    function totalCustody() external view returns(uint);

    function totalLocked() external view returns(uint);

    function balanceOfComp() external view returns(uint);
}
