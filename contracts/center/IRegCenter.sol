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


import "../lib/UsersRepo.sol";
import "../lib/DocsRepo.sol";

import "./books/IBookOfDocs.sol";
import "./books/IBookOfPoints.sol";
import "./books/IBookOfUsers.sol";

import "../openzeppelin/token/ERC20/IERC20.sol";

interface IRegCenter is IBookOfPoints, IERC20, IBookOfDocs, IBookOfUsers{

    enum TypeOfDoc{
        ZeroPoint,
        ROCKeeper,      // 1
        RODKeeper,      // 2
        BMMKeeper,      // 3
        ROMKeeper,      // 4
        GMMKeeper,      // 5
        ROAKeeper,      // 6
        ROOKeeper,      // 7
        ROPKeeper,      // 8
        SHAKeeper,      // 9
        LOOKeeper,      // 10
        ROC,            // 11
        ROD,            // 12
        MeetingMinutes, // 13
        ROM,            // 14
        ROA,            // 15
        ROO,            // 16
        ROP,            // 17
        ROS,            // 18
        LOO,            // 19
        GeneralKeeper,  // 20
        IA,             // 21
        SHA,            // 22 
        AntiDilution,   // 23
        LockUp,         // 24
        Alongs,         // 25
        Options,        // 26
        LOP             // 27
    }

    function regUser() external;

    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40);

    // ==== Self Query ====

    function getMyUserNo() external view returns(uint40);

    function getMyUser() external view returns (UsersRepo.User memory);

    // ==== Admin Checking ====

    function getUserNo(address targetAddr) external view returns (uint40);

    function getUser(address targetAddr) external view returns (UsersRepo.User memory);

    function getUserByNo(uint acct) external view returns (UsersRepo.User memory);

}
