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

import "../../lib/PledgesRepo.sol";
import "../../lib/DealsRepo.sol";
import "../../lib/InvestorsRepo.sol";
import "../../lib/InterfacesHub.sol";

import "../books/rop/IRegisterOfPledges.sol";
import "../books/ros/IRegisterOfShares.sol";
import "../books/rom/IRegisterOfMembers.sol";

/// @title IROPKeeper
/// @notice Interface for pledge operations via keeper.
interface IROPKeeper {

    // ###################
    // ##   ROPKeeper   ##
    // ###################

    /// @notice Create a pledge.
    /// @param snOfPld Pledge serial number.
    /// @param paid Paid amount pledged.
    /// @param par Par amount pledged.
    /// @param guaranteedAmt Guaranteed amount.
    /// @param execDays Execution days after default.
    /// @param msgSender Caller address.
    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays,
        address msgSender
    ) external;

    /// @notice Transfer a pledge.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param buyer New creditor user number.
    /// @param amt Transfer amount.
    /// @param msgSender Caller address.
    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        address msgSender        
    ) external;

    /// @notice Refund debt against a pledge.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param amt Refunded amount.
    /// @param msgSender Caller address.
    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        address msgSender
    ) external;

    /// @notice Extend pledge execution days.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param extDays Extension days.
    /// @param msgSender Caller address.
    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        address msgSender
    ) external;

    /// @notice Lock a pledge with hash lock.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param hashLock Hash lock.
    /// @param msgSender Caller address.
    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        address msgSender
    ) external;

    /// @notice Release a pledge with hash key.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param hashKey Hash key.
    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey
    ) external;

    /// @notice Execute a pledge.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param buyer Buyer user number.
    /// @param groupOfBuyer Buyer group number.
    /// @param msgSender Caller address.
    function execPledge(
        uint seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint groupOfBuyer,
        address msgSender
    ) external;

    /// @notice Revoke a pledge.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param msgSender Caller address.
    function revokePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        address msgSender
    ) external;

}
