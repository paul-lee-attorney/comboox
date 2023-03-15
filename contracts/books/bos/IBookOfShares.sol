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

    event IssueShare(
        uint256 indexed seq,
        uint64 paid,
        uint64 par
    );

    event PayInCapital(
        uint256 indexed seq,
        uint64 amount
    );

    event SubAmountFromShare(
        uint256 indexed seq,
        uint64 paid,
        uint64 par
    );

    event DeregisterShare(uint256 indexed seq);

    event UpdateStateOfShare(uint256 indexed seq, uint8 state);

    event UpdatePaidInDeadline(
        uint256 indexed seq,
        uint48 paidInDeadline
    );

    event DecreaseCleanAmt(uint256 indexed seq, uint64 paid, uint64 par);

    event IncreaseCleanAmt(uint256 indexed seq, uint64 paid, uint64 par);

    event SetPayInAmt(bytes32 indexed sn, uint64 amount);

    event WithdrawPayInAmt(bytes32 indexed sn);

    //##################
    //##    写接口    ##
    //##################

    function issueShare(
        uint256 shareNumber,
        uint64 paid,
        uint64 par
    ) external;

    function regShare(
        SharesRepo.Head memory head,
        uint64 paid,
        uint64 par
    ) external;

    function setPayInAmt(bytes32 hashLock, uint64 amount) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    function withdrawPayInAmt(bytes32 hashLock) external;

    function transferShare(
        uint256 seq,
        uint64 paid,
        uint64 par,
        uint40 to,
        uint32 price
    ) external;

    function decreaseCapital(
        uint256 seq,
        uint64 paid,
        uint64 par
    ) external;

    // ==== CleanPaid ====

    function decreaseCleanAmt(uint256 seq, uint64 paid, uint64 par) external;

    function increaseCleanAmt(uint256 seq, uint64 paid, uint64 par) external;

    // ==== State & PaidInDeadline ====

    function updateStateOfShare(uint256 seq, uint8 state) external;

    function updatePaidInDeadline(uint256 seq, uint48 paidInDeadline) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    // ==== BookOfShares ====

    function counterOfShares() external view returns (uint32);

    function counterOfClasses() external view returns (uint16);

    function isShare(uint256 seq) external view returns (bool);

    function getHeadOfShare(uint256 seq)
        external
        view
        returns (SharesRepo.Head memory head);

    function getBodyOfShare(uint256 seq)
        external
        view
        returns (SharesRepo.Body memory body);

    function getShare(uint256 seq)
        external
        view
        returns (SharesRepo.Share memory share);


    function getLocker(bytes32 sn) external view returns (uint64 amount);

    function getAttrOfClass(uint16 class) external view
        returns (uint256[] memory seqList, uint256[] memory members);
}
