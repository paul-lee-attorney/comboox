// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../../lib/ArrayUtils.sol";
import "../../../../lib/BallotsBox.sol";
import "../../../../lib/DealsRepo.sol";
import "../../../../lib/EnumerableSet.sol";

import "../../../common/components/ISigPage.sol";

interface ILockUp {

    // 股票锁定柜
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
    // ##  查询接口  ##
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