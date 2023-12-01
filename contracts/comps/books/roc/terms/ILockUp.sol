// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS NOT FOR FREE AND IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
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
import "../../../../lib/EnumerableSet.sol";

import "../../../common/components/ISigPage.sol";

interface ILockUp {

    struct Locker {
        uint48 dueDate;
        EnumerableSet.UintSet keyHolders;
    }

    // ################
    // ##   Write    ##
    // ################

    function setLocker(uint256 seqOfShare, uint dueDate) external;

    function delLocker(uint256 seqOfShare) external;

    function addKeyholder(uint256 seqOfShare, uint256 keyholder) external;

    function removeKeyholder(uint256 seqOfShare, uint256 keyholder) external;

    // ################
    // ##  Read I/O  ##
    // ################

    function isLocked(uint256 seqOfShare) external view returns (bool);

    function getLocker(uint256 seqOfShare)
        external
        view
        returns (uint48 dueDate, uint256[] memory keyHolders);

    function lockedShares() external view returns (uint256[] memory);

    function isTriggered(DealsRepo.Deal memory deal) external view returns (bool);

    function isExempted(address ia, DealsRepo.Deal memory deal) external view returns (bool);

}
