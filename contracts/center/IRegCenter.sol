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

pragma solidity ^0.8.24;

/// @title IRegCenter
/// @notice Registry center interface combining docs, users, points, and ERC20 operations.
/// @dev Extends IBookOfPoints, IBookOfDocs, IBookOfUsers, and IERC20.

import "../lib/UsersRepo.sol";
import "../lib/DocsRepo.sol";
import "./books/IBookOfDocs.sol";
import "./books/IBookOfPoints.sol";
import "./books/IBookOfUsers.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";

interface IRegCenter is IBookOfPoints, IBookOfDocs, IBookOfUsers, IERC20{

    /// @notice Register caller as a user and mint initial gift points if configured.
    function regUser() external;

    /// @notice Resolve userNo and charge license fee according to royalty rules.
    /// @param targetAddr User address to resolve.
    /// @param fee License fee amount (in points' smallest unit).
    /// @param author Author userNo.
    /// @return userNo Resolved user number.
    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40);

    // ==== Self Query ====

    /// @notice Get caller's user number.
    function getMyUserNo() external view returns(uint40);

    /// @notice Get caller's user record.
    function getMyUser() external view returns (UsersRepo.User memory);

    // ==== Admin Checking ====

    /// @notice Get user number by address (admin access in implementation).
    /// @param targetAddr User address.
    function getUserNo(address targetAddr) external view returns (uint40);

    /// @notice Get user record by address (admin access in implementation).
    /// @param targetAddr User address.
    function getUser(address targetAddr) external view returns (UsersRepo.User memory);

    /// @notice Get user record by user number (admin access in implementation).
    /// @param acct User number.
    function getUserByNo(uint acct) external view returns (UsersRepo.User memory);

}
