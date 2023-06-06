// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/SharesRepo.sol";
import "../../common/lib/LockersRepo.sol";

interface IBookOfShares {

    //##################
    //##    Event     ##
    //##################

    event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par);

    event PayInCapital(uint256 indexed seqOfShare, uint indexed amount);

    event SubAmountFromShare(uint256 indexed seqOfShare, uint indexed paid, uint indexed par);

    event DeregisterShare(uint256 indexed seqOfShare);

    event UpdateStateOfShare(uint256 indexed seqOfShare, uint indexed state);

    event UpdatePaidInDeadline(uint256 indexed seqOfShare, uint indexed paidInDeadline);

    event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

    event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

    event SetPayInAmt(bytes32 indexed snOfLocker, uint indexed amount);

    event WithdrawPayInAmt(bytes32 indexed snOfLocker);

    //##################
    //##    写接口    ##
    //##################

    function issueShare(bytes32 shareNumber, uint payInDeadline, uint paid, uint par) external;

    function regShare(SharesRepo.Share memory share) external returns(SharesRepo.Share memory newShare);

    function setPayInAmt(bytes32 snOfLocker, uint amount) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey, uint256 caller) external;

    function withdrawPayInAmt(bytes32 hashLock) external;

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

    function updatePaidInDeadline(uint256 seqOfShare, uint paidInDeadline) external;

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

    function getLocker(bytes32 snOfLocker) external view returns (uint64 amount);

    function getSharesOfClass(uint class) external view
        returns (uint256[] memory seqList);
}
