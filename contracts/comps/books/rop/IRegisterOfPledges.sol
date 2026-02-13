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

import "../../../lib/PledgesRepo.sol";

/// @title IRegisterOfPledges
/// @notice Interface for creating, transferring, and enforcing share pledges.
interface IRegisterOfPledges {

    //##################
    //##    Event     ##
    //##################

    /// @notice Emitted when a pledge is created.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param creditor Creditor account.
    /// @param paid Paid amount pledged.
    /// @param par Par amount pledged.
    event CreatePledge(
        uint256 indexed seqOfShare,
        uint256 indexed seqOfPld,
        uint256 creditor,
        uint256 indexed paid,
        uint256 par
    );

    /// @notice Emitted when a pledge is transferred.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Original pledge sequence.
    /// @param newSeqOfPld New pledge sequence.
    /// @param buyer New creditor account.
    /// @param paid Paid amount transferred.
    /// @param par Par amount transferred.
    event TransferPledge(
        uint256 indexed seqOfShare,
        uint256 indexed seqOfPld,
        uint256 indexed newSeqOfPld,
        uint256 buyer,
        uint256 paid,
        uint256 par
    );

    /// @notice Emitted when debt is refunded against a pledge.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param refundAmt Refunded amount.
    event RefundDebt(
        uint256 indexed seqOfShare,
        uint256 indexed seqOfPld,
        uint256 indexed refundAmt
    );

    /// @notice Emitted when a pledge execution is extended.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param extDays Extension days.
    event ExtendPledge(
        uint256 indexed seqOfShare,
        uint256 indexed seqOfPld,
        uint256 indexed extDays
    );

    /// @notice Emitted when a pledge is locked by hash.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param hashLock Hash lock.
    event LockPledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld, bytes32 indexed hashLock);

    /// @notice Emitted when a pledge is released by hash key.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param hashKey Hash key.
    event ReleasePledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld, string indexed hashKey);

    /// @notice Emitted when a pledge is executed.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    event ExecPledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld);

    /// @notice Emitted when a pledge is revoked.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    event RevokePledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld);

    //##################
    //##  Write I/O   ##
    //##################

    /// @notice Create a pledge from encoded inputs.
    /// @param snOfPld Pledge serial number.
    /// @param paid Paid amount pledged.
    /// @param par Par amount pledged.
    /// @param guaranteedAmt Guaranteed amount.
    /// @param execDays Execution days after default.
    /// @return head Pledge head.
    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) external returns(PledgesRepo.Head memory head);

    /// @notice Issue a pledge by head parameters.
    /// @param head Pledge head.
    /// @param paid Paid amount pledged.
    /// @param par Par amount pledged.
    /// @param guaranteedAmt Guaranteed amount.
    /// @param execDays Execution days after default.
    /// @return regHead Registered head.
    function issuePledge(
        PledgesRepo.Head memory head,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) external returns(PledgesRepo.Head memory regHead);

    /// @notice Register a pledge record.
    /// @param pld Pledge record.
    /// @return head Registered head.
    function regPledge(
        PledgesRepo.Pledge memory pld
    ) external returns(PledgesRepo.Head memory head);

    /// @notice Transfer pledge to a new creditor.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param buyer New creditor account.
    /// @param amt Transfer amount.
    /// @param caller Caller user number.
    /// @return newPld New pledge record.
    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint caller
    ) external returns (PledgesRepo.Pledge memory newPld);

    /// @notice Refund debt against a pledge.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param amt Refunded amount.
    /// @param caller Caller user number.
    /// @return newPld Updated pledge record.
    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        uint caller
    ) external returns (PledgesRepo.Pledge memory newPld);

    /// @notice Extend pledge execution days.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param extDays Extension days.
    /// @param caller Caller user number.
    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        uint caller
    ) external;

    // ==== Lock/Release/Exec/Revoke ====

    /// @notice Lock a pledge with hash lock.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param hashLock Hash lock.
    /// @param caller Caller user number.
    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint caller
    ) external;

    /// @notice Release a locked pledge with hash key.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param hashKey Hash key.
    /// @return releaseDate Release date.
    function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey)
        external returns (uint64 releaseDate);

    /// @notice Execute a pledge.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param caller Caller user number.
    function execPledge(
        uint seqOfShare, 
        uint256 seqOfPld,
        uint caller
    ) external;

    /// @notice Revoke a pledge.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @param caller Caller user number.
    function revokePledge(uint256 seqOfShare, uint256 seqOfPld, uint caller)
        external; 

    //################
    //##    Read    ##
    //################

    /// @notice Get pledge counter for a share.
    /// @param seqOfShare Share sequence.
    /// @return Counter value.
    function counterOfPledges(uint256 seqOfShare) 
        external view returns (uint16);

    /// @notice Check whether a pledge exists.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @return True if exists.
    function isPledge(uint256 seqOfShare, uint256 seqOfPld) 
        external view returns (bool);

    /// @notice Get pledge serial number list.
    /// @return Serial numbers.
    function getSNList() external view
        returns(bytes32[] memory);

    /// @notice Get pledge by sequence.
    /// @param seqOfShare Share sequence.
    /// @param seqOfPld Pledge sequence.
    /// @return Pledge record.
    function getPledge(uint256 seqOfShare, uint256 seqOfPld)
        external view returns (PledgesRepo.Pledge memory);

    /// @notice Get pledges of a share.
    /// @param seqOfShare Share sequence.
    /// @return Pledge list.
    function getPledgesOfShare(uint256 seqOfShare) 
        external view returns (PledgesRepo.Pledge[] memory);

    /// @notice Get all pledges.
    /// @return Pledge list.
    function getAllPledges() external view 
        returns (PledgesRepo.Pledge[] memory);

}
