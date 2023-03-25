// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/SharesRepo.sol";

interface IBookOfShares {

    //##################
    //##    Event     ##
    //##################

    event IssueShare(uint256 indexed seqOfShare, uint64 paid, uint64 par);

    event PayInCapital(uint256 indexed seqOfShare, uint64 amount);

    event SubAmountFromShare(uint256 indexed seqOfShare, uint64 paid, uint64 par);

    event DeregisterShare(uint256 indexed seqOfShare);

    event UpdateStateOfShare(uint256 indexed seqOfShare, uint8 state);

    event UpdatePaidInDeadline(uint256 indexed seqOfShare, uint48 paidInDeadline);

    event DecreaseCleanPaid(uint256 indexed seqOfShare, uint64 paid);

    event IncreaseCleanPaid(uint256 indexed seqOfShare, uint64 paid);

    event SetPayInAmt(bytes32 indexed sn, uint64 amount);

    event WithdrawPayInAmt(bytes32 indexed sn);

    //##################
    //##    写接口    ##
    //##################

    function issueShare(uint256 shareNumber, uint48 payInDeadline, uint64 paid,uint64 par) external;

    function regShare(SharesRepo.Share memory share) external returns(SharesRepo.Share memory newShare);

    function setPayInAmt(bytes32 hashLock, uint64 amount) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey, uint256 caller) external;

    function withdrawPayInAmt(bytes32 hashLock) external;

    function transferShare(
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint40 to,
        uint32 price
    ) external;

    function decreaseCapital(uint256 seqOfShare, uint64 paid, uint64 par) external;

    // ==== CleanPaid ====

    function decreaseCleanPaid(uint256 seqOfShare, uint64 paid) external;

    function increaseCleanPaid(uint256 seqOfShare, uint64 paid) external;

    // ==== State & PaidInDeadline ====

    function updateStateOfShare(uint256 seqOfShare, uint8 state) external;

    function updatePaidInDeadline(uint256 seqOfShare, uint48 paidInDeadline) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    // ==== BookOfShares ====

    function counterOfShares() external view returns (uint32);

    function counterOfClasses() external view returns (uint16);

    function isShare(uint256 seqOfShare) external view returns (bool);

    function getHeadOfShare(uint256 seqOfShare) external view 
        returns (SharesRepo.Head memory head);

    function getBodyOfShare(uint256 seqOfShare) external view 
        returns (SharesRepo.Body memory body);

    function getShare(uint256 seqOfShare) external view
        returns (SharesRepo.Share memory share);

    function getLocker(bytes32 sn) external view returns (uint64 amount);

    function getSharesOfClass(uint16 class) external view
        returns (uint256[] memory seqList);
}
