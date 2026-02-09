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

import "../../../lib/SharesRepo.sol";
import "../../../lib/LockersRepo.sol";
import "../../../lib/DealsRepo.sol";
import "../../../lib/InterfacesHub.sol";

import "../rom/IRegisterOfMembers.sol";
import "../roc/IShareholdersAgreement.sol";
import "../roc/terms/ILockUp.sol";

interface IRegisterOfShares {

    //##################
    //##    Event     ##
    //##################

    /// @notice Emitted when a share is issued.
    /// @param shareNumber Share serial number.
    /// @param paid Paid amount.
    /// @param par Par amount.
    event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par);

    /// @notice Emitted when a share is transferred.
    /// @param shareNumber Original share serial number.
    /// @param newShareNumber New share serial number.
    /// @param paid Paid amount transferred.
    /// @param par Par amount transferred.
    event TransferShare(bytes32 indexed shareNumber, bytes32 indexed newShareNumber, uint indexed paid, uint par);

    /// @notice Emitted when capital is paid in for a share.
    /// @param seqOfShare Share sequence.
    /// @param amount Paid-in amount.
    event PayInCapital(uint256 indexed seqOfShare, uint indexed amount);

    /// @notice Emitted when paid/par amounts are reduced for a share.
    /// @param seqOfShare Share sequence.
    /// @param paid Paid amount reduced.
    /// @param par Par amount reduced.
    event SubAmountFromShare(uint256 indexed seqOfShare, uint indexed paid, uint indexed par);

    /// @notice Emitted when a share is deregistered.
    /// @param seqOfShare Share sequence.
    event DeregisterShare(uint256 indexed seqOfShare);

    /// @notice Emitted when price of paid amount is updated.
    /// @param seqOfShare Share sequence.
    /// @param newPrice New price.
    event UpdatePriceOfPaid(uint indexed seqOfShare, uint indexed newPrice);

    /// @notice Emitted when paid-in deadline is updated.
    /// @param seqOfShare Share sequence.
    /// @param paidInDeadline New deadline timestamp.
    event UpdatePaidInDeadline(uint256 indexed seqOfShare, uint indexed paidInDeadline);

    /// @notice Emitted when clean paid amount is decreased.
    /// @param seqOfShare Share sequence.
    /// @param paid Amount decreased.
    event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

    /// @notice Emitted when clean paid amount is increased.
    /// @param seqOfShare Share sequence.
    /// @param paid Amount increased.
    event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

    /// @notice Emitted when a pay-in amount is set with hash lock.
    /// @param headSn Share head serial number.
    /// @param hashLock Hash lock.
    event SetPayInAmt(bytes32 indexed headSn, bytes32 indexed hashLock);

    /// @notice Emitted when a pay-in amount is withdrawn.
    /// @param seqOfShare Share sequence.
    /// @param amount Amount withdrawn.
    event WithdrawPayInAmt(uint indexed seqOfShare, uint indexed amount);

    /// @notice Emitted when equity of a class is adjusted.
    /// @param isIncrease True if increase, false if decrease.
    /// @param class Share class id.
    /// @param amt Amount changed.
    event IncreaseEquityOfClass(bool indexed isIncrease, uint indexed class, uint indexed amt);

    //##################
    //##  Write I/O   ##
    //##################

    function issueShare(
        bytes32 shareNumber, 
        uint payInDeadline, 
        uint paid, 
        uint par, 
        uint distrWeight
    ) external;

    function addShare(SharesRepo.Share memory share) external;

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;

    function payInCapital(uint seqOfShare, uint amt) external;

    function transferShare(
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint to,
        uint priceOfPaid,
        uint priceOfPar
    ) external;

    function decreaseCapital(uint256 seqOfShare, uint paid, uint par) external;

    // ==== CleanPaid ====

    function decreaseCleanPaid(uint256 seqOfShare, uint paid) external;

    function increaseCleanPaid(uint256 seqOfShare, uint paid) external;

    // ==== State & PaidInDeadline ====

    function updatePriceOfPaid(uint seqOfShare, uint newPrice) external;

    function updatePaidInDeadline(uint256 seqOfShare, uint paidInDeadline) external;

    // ==== EquityOfClass ====

    function increaseEquityOfClass(
        bool isIncrease,
        uint classOfShare,
        uint deltaPaid,
        uint deltaPar,
        uint deltaCleanPaid
    ) external;

    function restoreShares(SharesRepo.Share[] memory shares, SharesRepo.Share[] memory classes) external;

    // ##################
    // ##   Read I/O   ##
    // ##################

    function counterOfShares() external view returns (uint32);

    function counterOfClasses() external view returns (uint16);

    // ==== SharesRepo ====

    function isShare(
        uint256 seqOfShare
    ) external view returns (bool);

    function getShare(
        uint256 seqOfShare
    ) external view returns (
        SharesRepo.Share memory
    );

    function getQtyOfShares() external view returns (uint);

    function getSeqListOfShares() external view returns (uint[] memory);

    function getSharesList() external view returns (SharesRepo.Share[] memory);

    function getShareZero() external view returns (SharesRepo.Share memory);

    // ---- Class ----    

    function getQtyOfSharesInClass(
        uint classOfShare
    ) external view returns (uint);

    function getSeqListOfClass(
        uint classOfShare
    ) external view returns (uint[] memory);

    function getInfoOfClass(
        uint classOfShare
    ) external view returns (SharesRepo.Share memory);

    function getSharesOfClass(
        uint classOfShare
    ) external view returns (SharesRepo.Share[] memory);

    function getPremium() external view returns (uint);

    // ==== PayInCapital ====

    function getLocker(
        bytes32 hashLock
    ) external view returns (LockersRepo.Locker memory);

    function getLocksList() external view returns (bytes32[] memory);

    // ==== NotLocked ====
    
    function notLocked(
        uint seqOfShare,
        uint closingDate
    ) external view returns(bool);
    
 }
