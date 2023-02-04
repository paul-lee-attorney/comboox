// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ITerm.sol";

interface ILockUp is ITerm {
    // ################
    // ##   Write    ##
    // ################

    function setLocker(uint32 ssn, uint48 dueDate) external;

    function delLocker(uint32 ssn) external;

    function addKeyholder(uint32 ssn, uint40 keyholder) external;

    function removeKeyholder(uint32 ssn, uint40 keyholder) external;

    // ################
    // ##  查询接口  ##
    // ################

    function isLocked(uint32 ssn) external view returns (bool);

    function getLocker(uint32 ssn)
        external
        view
        returns (uint48 dueDate, uint40[] memory keyHolders);

    function lockedShares() external view returns (uint32[] memory);
}
