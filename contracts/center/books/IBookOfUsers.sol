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

pragma solidity ^0.8.8;

import "../../lib/UsersRepo.sol";

interface IBookOfUsers {

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Config ====

    event SetPlatformRule(bytes32 indexed snOfRule);

    event TransferOwnership(address indexed newOwner);

    event TurnOverCenterKey(address indexed newKeeper);

    // ##################
    // ##    Write     ##
    // ##################

    // ==== Opts Setting ====

    function transferOwnership(address newOwner) external;

    function handoverCenterKey(address newKeeper) external;
 
    // ==== User ====

    function setBackupKey(address bKey) external;

    function upgradeBackupToPrime() external;

    // ==== Royalty & Coupon ====

    function setPlatformRule(bytes32 snOfRule) external;

    function setRoyaltyRule(bytes32 snOfRoyalty) external;

    // #################
    // ##   Read      ##
    // #################

    // ==== Config ====

    function getOwner() external view returns (address);

    function getBookeeper() external view returns (address);

    function getPlatformRule() external returns(UsersRepo.Rule memory);
        
    // ==== Users ====

    function isUserNo(uint acct) external view returns (bool);

    // function getMyUserNo() external view returns (uint40);

    function counterOfUsers() external view returns(uint);

    function getUserNoList() external view returns(uint[] memory);

    // function getMyUser() external view returns (UsersRepo.User memory);

    // ==== Royalty & Coupon ====

    function getRoyaltyRule(uint author)external view returns (UsersRepo.Key memory);

    // ==== Keys ====

    function usedKey(address key) external view returns (bool);

    function isPrimeKey(address key) external view returns (bool);

}
