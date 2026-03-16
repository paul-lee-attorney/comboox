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

import "../../../lib/books/InvestorsRepo.sol";
import "../../../openzeppelin/utils/structs/EnumerableSet.sol";

/// @title IRegisterOfInvestors
/// @notice Interface for investor registry and compliance controls.
interface IRegisterOfInvestors {

     // ################
     // ##    Error   ##
     // ################

    error ROI_WrongState(bytes32 reason);

    error ROI_Overflow(bytes32 reason);

     // ################
     // ##  Event(s)  ##
     // ################

    /// @notice Emitted when LOO operations are paused.
    /// @param agent Operator user number.
    event Paused(uint indexed agent);

    /// @notice Emitted when LOO operations are unpaused.
    /// @param agent Operator user number.
    event UnPaused(uint indexed agent);

    /// @notice Emitted when a share is frozen for compliance.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount frozen.
    /// @param caller Operator user number.
    /// @param hashOrder Related order hash.
    event FreezeShare(uint indexed seqOfShare, uint indexed paid, uint indexed caller, bytes32 hashOrder);
    
    /// @notice Emitted when a frozen share is unfrozen.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount unfrozen.
    /// @param caller Operator user number.
    /// @param hashOrder Related order hash.
    event UnfreezeShare(uint indexed seqOfShare, uint indexed paid, uint indexed caller, bytes32 hashOrder);
    
    /// @notice Emitted when a forced transfer is executed for a frozen share.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount transferred.
    /// @param caller Operator user number.
    /// @param hashOrder Related order hash.
    event ForceTransfer(uint indexed seqOfShare, uint indexed paid, uint indexed caller, bytes32 hashOrder);

    /// @notice Emitted when an investor is registered.
    /// @param investor Investor user number.
    /// @param groupRep Group representative user number.
    /// @param idHash Investor id hash.
    event RegInvestor(uint indexed investor, uint indexed groupRep, bytes32 indexed idHash);

    /// @notice Emitted when an investor is approved.
    /// @param investor Investor user number.
    /// @param verifier Verifier user number.
    event ApproveInvestor(uint indexed investor, uint indexed verifier);

    /// @notice Emitted when an investor approval is revoked.
    /// @param investor Investor user number.
    /// @param verifier Verifier user number.
    event RevokeInvestor(uint indexed investor, uint indexed verifier);

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Pause LOO ====

    /// @notice Pause LOO operations.
    /// @param caller Operator user number.
    function pause(uint caller) external;

    /// @notice Unpause LOO operations.
    /// @param caller Operator user number.
    function unPause(uint caller) external;

    // ==== Freeze Share ====

    /// @notice Freeze a share for an investor.
    /// @param userNo Investor user number.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param caller Operator user number.
    /// @param hashOrder Order hash.
    function freezeShare(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external;

    /// @notice Unfreeze a share for an investor.
    /// @param userNo Investor user number.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param caller Operator user number.
    /// @param hashOrder Order hash.
    function unfreezeShare(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external;

    /// @notice Force transfer a frozen share.
    /// @param userNo Investor user number.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount.
    /// @param caller Operator user number.
    /// @param hashOrder Order hash.
    function forceTransfer(
        uint userNo, uint seqOfShare, uint paid, uint caller,
        bytes32 hashOrder
    ) external;

    // ==== Investor ====

    /// @notice Register or update an investor.
    /// @param userNo Investor user number.
    /// @param groupRep Group representative.
    /// @param idHash ID hash.
    function regInvestor(uint userNo,uint groupRep,bytes32 idHash) external;

    /// @notice Approve an investor.
    /// @param userNo Investor user number.
    /// @param verifier Verifier user number.
    function approveInvestor(uint userNo,uint verifier) external;

    /// @notice Revoke an investor.
    /// @param userNo Investor user number.
    /// @param verifier Verifier user number.
    function revokeInvestor(uint userNo,uint verifier) external;

    /// @notice Restore investors repo from snapshots.
    /// @param list Investor list.
    /// @param qtyOfInvestors Approved investor count.
    function restoreInvestorsRepo(InvestorsRepo.Investor[] memory list, uint qtyOfInvestors) external;

    //################
    //##  Read I/O  ##
    //################

    // ==== Paused ====

    /// @notice Check if paused.
    /// @return True if paused.
    function isPaused() external view returns (bool);

    // ==== Freeze ====

    /// @notice Check if investor is frozen.
    /// @param userNo Investor user number.
    /// @return True if frozen.
    function isFrozen(uint userNo) external view returns(bool); 

    /// @notice Check if share is frozen.
    /// @param seqOfShare Share sequence.
    /// @return True if frozen.
    function isFrozenShare(uint seqOfShare) external view returns(bool);

    /// @notice Get frozen shares of an investor.
    /// @param userNo Investor user number.
    /// @return Share list.
    function frozenShares(uint userNo) external view returns(uint[] memory); 
    
    /// @notice Get frozen paid amount for a share.
    /// @param seqOfShare Share sequence.
    /// @return Paid amount.
    function frozenPaid(uint seqOfShare) external view returns(uint);

    // ==== Investor ====

    /// @notice Check if investor exists.
    /// @param userNo Investor user number.
    /// @return True if exists.
    function isInvestor(uint userNo) external view returns(bool);

    /// @notice Get investor record.
    /// @param userNo Investor user number.
    /// @return Investor record.
    function getInvestor(uint userNo) external view returns(InvestorsRepo.Investor memory);

    /// @notice Get approved investor count.
    /// @return Count.
    function getQtyOfInvestors() external view returns(uint);

    /// @notice Get investor list.
    /// @return Investor user numbers.
    function investorList() external view returns(uint[] memory);

    /// @notice Get investor info list.
    /// @return Investor records.
    function investorInfoList() external view returns(InvestorsRepo.Investor[] memory);

}
