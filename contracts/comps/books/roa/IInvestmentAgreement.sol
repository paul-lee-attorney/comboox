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

import "../../../lib/SwapsRepo.sol";
import "../../../lib/DealsRepo.sol";
import "../../../lib/InterfacesHub.sol";

import "../../common/components/ISigPage.sol";

/// @title IInvestmentAgreement
/// @notice Investment agreement interface for deal lifecycle and swaps.
interface IInvestmentAgreement is ISigPage {

    //##################
    //##    Event     ##
    //##################

    /// @notice Emitted when a deal is registered.
    /// @param seqOfDeal Deal sequence.
    event RegDeal(uint indexed seqOfDeal);

    /// @notice Emitted when deal conditions precedent are cleared.
    /// @param seq Deal sequence.
    /// @param hashLock Hash lock for closing.
    /// @param closingDeadline Closing deadline timestamp.
    event ClearDealCP(
        uint256 indexed seq,
        bytes32 indexed hashLock,
        uint indexed closingDeadline
    );

    /// @notice Emitted when a deal is closed.
    /// @param seq Deal sequence.
    /// @param hashKey Hash key for closing.
    event CloseDeal(uint256 indexed seq, string indexed hashKey);

    /// @notice Emitted when a deal is terminated.
    /// @param seq Deal sequence.
    event TerminateDeal(uint256 indexed seq);
    
    /// @notice Emitted when a swap is created for a deal.
    /// @param seqOfDeal Deal sequence.
    /// @param snOfSwap Swap serial number.
    event CreateSwap(uint seqOfDeal, bytes32 snOfSwap);

    /// @notice Emitted when a swap is paid off.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfSwap Swap sequence.
    event PayOffSwap(uint seqOfDeal, uint seqOfSwap);

    /// @notice Emitted when a swap is terminated.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfSwap Swap sequence.
    event TerminateSwap(uint seqOfDeal, uint seqOfSwap);

    /// @notice Emitted when an approved deal is paid off.
    /// @param seqOfDeal Deal sequence.
    /// @param msgValue Payment value.
    event PayOffApprovedDeal(uint seqOfDeal, uint msgValue);

    //##################
    //##  Write I/O  ##
    //##################

    // ======== InvestmentAgreement ========

    /// @notice Add a deal from packed head and params.
    /// @param sn Packed deal head.
    /// @param buyer Buyer user number.
    /// @param groupOfBuyer Buyer group number.
    /// @param paid Paid amount.
    /// @param par Par amount.
    /// @param distrWeight Distribution weight.
    function addDeal(
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par,
        uint distrWeight
    ) external;

    /// @notice Register a deal record.
    /// @param deal Deal record.
    /// @return seqOfDeal Deal sequence.
    function regDeal(DealsRepo.Deal memory deal) external returns(uint16 seqOfDeal);

    /// @notice Delete a deal by sequence.
    /// @param seq Deal sequence.
    function delDeal(uint256 seq) external;

    /// @notice Lock a deal subject.
    /// @param seq Deal sequence.
    /// @return flag True if locked.
    function lockDealSubject(uint256 seq) external returns (bool flag);

    /// @notice Release a deal subject.
    /// @param seq Deal sequence.
    /// @return flag True if released.
    function releaseDealSubject(uint256 seq) external returns (bool flag);

    /// @notice Clear a deal with hash lock and deadline.
    /// @param seq Deal sequence.
    /// @param hashLock Hash lock key.
    /// @param closingDeadline Closing deadline timestamp.
    function clearDealCP( uint256 seq, bytes32 hashLock, uint closingDeadline) external;

    /// @notice Close a deal using hash preimage.
    /// @param seq Deal sequence.
    /// @param hashKey Preimage string.
    /// @return flag True if closed.
    function closeDeal(uint256 seq, string memory hashKey)
        external returns (bool flag);

    /// @notice Close a locked deal directly.
    /// @param seq Deal sequence.
    /// @return flag True if closed.
    function directCloseDeal(uint256 seq) external returns (bool flag);

    /// @notice Terminate a deal.
    /// @param seqOfDeal Deal sequence.
    /// @return True if terminated.
    function terminateDeal(uint256 seqOfDeal) external returns(bool);

    /// @notice Accept a free-gift deal.
    /// @param seq Deal sequence.
    /// @return True if accepted.
    function takeGift(uint256 seq) external returns(bool);

    /// @notice Finalize the investment agreement.
    function finalizeIA() external;

    // ==== Swap ====

    /// @notice Create a swap for terminated deal.
    /// @param seqOfMotion Motion sequence.
    /// @param seqOfDeal Deal sequence.
    /// @param paidOfTarget Paid target amount.
    /// @param seqOfPledge Pledge share sequence.
    /// @param caller Caller user number.
    /// @return swap Swap record.
    function createSwap (
        uint seqOfMotion,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller
    ) external returns(SwapsRepo.Swap memory swap);

    /// @notice Pay off a swap.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfSwap Swap sequence.
    /// @return swap Swap record.
    function payOffSwap(
        uint seqOfDeal,
        uint seqOfSwap
    ) external returns(SwapsRepo.Swap memory swap);

    /// @notice Terminate a swap after exec period.
    /// @param seqOfMotion Motion sequence.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfSwap Swap sequence.
    /// @return swap Swap record.
    function terminateSwap(
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap
    ) external returns (SwapsRepo.Swap memory swap);

    /// @notice Pay off an approved deal.
    /// @param seqOfDeal Deal sequence.
    /// @param msgValue Paid value.
    /// @param caller Buyer user number.
    /// @return flag True if closed.
    function payOffApprovedDeal(
        uint seqOfDeal,
        uint msgValue,
        uint caller
    ) external returns (bool flag);

    /// @notice Request price difference for a share.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfShare Share sequence.
    function requestPriceDiff(
        uint seqOfDeal,
        uint seqOfShare
    ) external;

    //  #####################
    //  ##     Read I/O    ##
    //  #####################

    // ======== InvestmentAgreement ========
    /// @notice Get composite IA type.
    /// @return Type code.
    function getTypeOfIA() external view returns (uint8);

    /// @notice Get deal by sequence.
    /// @param seq Deal sequence.
    /// @return Deal record.
    function getDeal(uint256 seq) external view returns (DealsRepo.Deal memory);

    /// @notice Get deal sequence list.
    /// @return Deal ids.
    function getSeqList() external view returns (uint[] memory);

    // ==== Swap ====

    /// @notice Get swap by sequence.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfSwap Swap sequence.
    /// @return Swap record.
    function getSwap(uint seqOfDeal, uint256 seqOfSwap)
        external view returns (SwapsRepo.Swap memory);

    /// @notice Get all swaps for a deal.
    /// @param seqOfDeal Deal sequence.
    /// @return Swap list.
    function getAllSwaps(uint seqOfDeal)
        external view returns (SwapsRepo.Swap[] memory);

    /// @notice Check whether all swaps are closed.
    /// @param seqOfDeal Deal sequence.
    /// @return True if all closed.
    function allSwapsClosed(uint seqOfDeal)
        external view returns (bool);

}
