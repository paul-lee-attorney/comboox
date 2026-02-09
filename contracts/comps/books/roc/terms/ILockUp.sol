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

import "../../../../lib/ArrayUtils.sol";
import "../../../../lib/BallotsBox.sol";
import "../../../../lib/DealsRepo.sol";
import "../../../../openzeppelin/utils/structs/EnumerableSet.sol";
import "../../../../lib/InterfacesHub.sol";

import "../../../common/components/ISigPage.sol";

/// @title ILockUp
/// @notice Interface for share lock-up rules and exemptions.
interface ILockUp {

    /// @notice Lock-up configuration for a share.
    struct Locker {
        uint48 dueDate;
        EnumerableSet.UintSet keyHolders;
    }

    // ################
    // ##   Write    ##
    // ################

    /// @notice Set lock-up due date for a share.
    /// @param seqOfShare Share sequence number.
    /// @param dueDate Lock-up due date (timestamp).
    function setLocker(uint256 seqOfShare, uint dueDate) external;

    /// @notice Remove lock-up for a share.
    /// @param seqOfShare Share sequence number.
    function delLocker(uint256 seqOfShare) external;

    /// @notice Add a keyholder who can exempt a lock-up.
    /// @param seqOfShare Share sequence number.
    /// @param keyholder Account id.
    function addKeyholder(uint256 seqOfShare, uint256 keyholder) external;

    /// @notice Remove a keyholder.
    /// @param seqOfShare Share sequence number.
    /// @param keyholder Account id.
    function removeKeyholder(uint256 seqOfShare, uint256 keyholder) external;

    // ################
    // ##  Read I/O  ##
    // ################

    /// @notice Check whether a share is locked.
    /// @param seqOfShare Share sequence number.
    /// @return True if locked.
    function isLocked(uint256 seqOfShare) external view returns (bool);

    /// @notice Get lock-up info for a share.
    /// @param seqOfShare Share sequence number.
    /// @return dueDate Lock-up due date.
    /// @return keyHolders Exemption keyholders.
    function getLocker(uint256 seqOfShare)
        external
        view
        returns (uint48 dueDate, uint256[] memory keyHolders);

    /// @notice Get all locked shares.
    /// @return Share sequences.
    function lockedShares() external view returns (uint256[] memory);

    /// @notice Check whether a deal is blocked by lock-up.
    /// @param deal Deal data.
    /// @return True if blocked.
    function isTriggered(DealsRepo.Deal memory deal) external view returns (bool);

    /// @notice Check whether a deal is exempted from lock-up.
    /// @param ia Investment agreement address.
    /// @param deal Deal data.
    /// @return True if exempted.
    function isExempted(address ia, DealsRepo.Deal memory deal) external view returns (bool);

}
