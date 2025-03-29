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

    event ReceiveUsd(address indexed from, uint indexed amt, bytes32 indexed remark);

    event ForwardUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark);

    event CustodyUsd(address indexed from, uint indexed amt, bytes32 indexed remark);

    event ReleaseUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark);

    event TransferUsd(address indexed to, uint indexed amt, bytes32 indexed remark);

    event DistributeUsd(uint indexed amt);

    event PickupUsd(address indexed msgSender, uint indexed caller, uint indexed value);

    //###############
    //##   Write   ##
    //###############

    function collectUsd(TransferAuth memory auth) external;

    function collectUsd(TransferAuth memory auth, bytes32 remark) external;

    function forwardUsd(TransferAuth memory auth, address to, bytes32 remark) external;

    function custodyUsd(TransferAuth memory auth, bytes32 remark) external;

    function releaseUsd(address from, address to, uint amt, bytes32 remark) external;

    function transferUsd(address to, uint amt, bytes32 remark) external;

    function distributeUsd(uint amt) external;

    function pickupUsd() external; 

    //##################
    //##   Read I/O   ##
    //##################

    function custodyOf(address acct) external view returns(uint);

    function totalEscrow() external view returns(uint);

    function totalDeposits() external view returns(uint);

    function depositOfMine(uint user) external view returns(uint);    

    function balanceOfComp() external view returns(uint);
}
