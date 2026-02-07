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

/// @title IBookOfUsers
/// @notice User registry interface for platform ownership, keeper control, and user key management.
/// @dev Exposes read/write operations for user registration, platform rules, and royalty settings.

import "../../lib/UsersRepo.sol";

interface IBookOfUsers {

    // ##################
    // ##    Event     ##
    // ##################

    // ==== Config ====

    /// @notice Emitted when platform rule is updated.
    /// @param snOfRule Packed rule bytes.
    event SetPlatformRule(bytes32 indexed snOfRule);

    /// @notice Emitted when platform ownership changes.
    /// @param newOwner New owner address.
    event TransferOwnership(address indexed newOwner);

    /// @notice Emitted when platform keeper changes.
    /// @param newKeeper New keeper address.
    event TurnOverCenterKey(address indexed newKeeper);

    // ##################
    // ##    Write     ##
    // ##################

    // ==== Opts Setting ====

    /// @notice Transfer platform ownership.
    /// @param newOwner New owner address (non-zero in implementation).
    function transferOwnership(address newOwner) external;

    /// @notice Handover keeper role for platform control.
    /// @param newKeeper New keeper address (non-zero in implementation).
    function handoverCenterKey(address newKeeper) external;
 
    // ==== User ====

    /// @notice Set backup key for the caller.
    /// @param bKey Backup key address (non-zero, unused).
    function setBackupKey(address bKey) external;

    /// @notice Promote backup key to prime key for the caller.
    function upgradeBackupToPrime() external;

    // ==== Royalty & Coupon ====

    /// @notice Set platform rule values.
    /// @param snOfRule Packed rule bytes.
    function setPlatformRule(bytes32 snOfRule) external;

    /// @notice Set royalty rule for the caller.
    /// @param snOfRoyalty Packed royalty rule bytes.
    function setRoyaltyRule(bytes32 snOfRoyalty) external;

    // #################
    // ##   Read      ##
    // #################

    // ==== Config ====

    /// @notice Get platform owner address.
    /// @return Owner address.
    function getOwner() external view returns (address);

    /// @notice Get platform keeper address.
    /// @return Keeper address.
    function getBookeeper() external view returns (address);

    /// @notice Get current platform rule values.
    /// @return Current rule.
    function getPlatformRule() external returns(UsersRepo.Rule memory);
        
    // ==== Users ====

    /// @notice Check whether a userNo exists.
    /// @param acct User number.
    /// @return True if exists.
    function isUserNo(uint acct) external view returns (bool);

    /// @notice Get total number of registered users.
    /// @return Count of users.
    function counterOfUsers() external view returns(uint);

    /// @notice Get list of all user numbers.
    /// @return Array of user numbers.
    function getUserNoList() external view returns(uint[] memory);

    // ==== Royalty & Coupon ====

    /// @notice Get royalty rule for an author.
    /// @param author Author userNo (must be > 0).
    /// @return Royalty rule.
    function getRoyaltyRule(uint author)external view returns (UsersRepo.Key memory);

    // ==== Keys ====

    /// @notice Check if an address is already registered as a key.
    /// @param key Address to check.
    /// @return True if used.
    function usedKey(address key) external view returns (bool);

    /// @notice Check if an address is a user's prime key.
    /// @param key Address to check.
    /// @return True if prime key.
    function isPrimeKey(address key) external view returns (bool);

}
