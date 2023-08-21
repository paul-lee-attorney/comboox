// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../lib/SharesRepo.sol";
import "../../../lib/LockersRepo.sol";

import "../rom/IRegisterOfMembers.sol";

interface IRegisterOfShares {

    //##################
    //##    Event     ##
    //##################

    event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par);

    event PayInCapital(uint256 indexed seqOfShare, uint indexed amount);

    event SubAmountFromShare(uint256 indexed seqOfShare, uint indexed paid, uint indexed par);

    event DeregisterShare(uint256 indexed seqOfShare);

    event UpdateStateOfShare(uint256 indexed seqOfShare, uint indexed state);

    // event UpdatePaidInDeadline(uint256 indexed seqOfShare, uint indexed paidInDeadline);

    event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

    event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

    event SetPayInAmt(bytes32 indexed headSn, bytes32 indexed hashLock);

    event WithdrawPayInAmt(uint indexed seqOfShare, uint indexed amount);

    //##################
    //##  Write I/O  ##
    //##################

    function issueShare(bytes32 shareNumber, uint payInDeadline, uint paid, uint par) external;

    function addShare(SharesRepo.Share memory share) external;

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;

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

    function updateStateOfShare(uint256 seqOfShare, uint state) external;

    // function updatePaidInDeadline(uint256 seqOfShare, uint paidInDeadline) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    // ==== RegisterOfShares ====

    function counterOfShares() external view returns (uint32);

    function counterOfClasses() external view returns (uint16);

    function isShare(uint256 seqOfShare) external view returns (bool);

    function getHeadOfShare(uint256 seqOfShare) external view 
        returns (SharesRepo.Head memory head);

    function getBodyOfShare(uint256 seqOfShare) external view 
        returns (SharesRepo.Body memory body);

    function getShare(uint256 seqOfShare) external view
        returns (SharesRepo.Share memory share);

    function getLocker(bytes32 hashLock) external view returns (LockersRepo.Locker memory locker);

    function getLocksList() external view returns (bytes32[] memory);

    function getSharesOfClass(uint class) external view
        returns (uint256[] memory seqList);
}
