// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBookOfShares {

    struct Head {
        uint16 class; // Class of shares as per the evaluation of company for corresponding investment;
        uint32 seq; // sequence number of shares;
        uint32 preSeq;
        uint48 issueDate;
        uint48 paidInDeadline; //出资期限（时间戳）
        uint40 shareholder;
        uint32 price;
        uint8 state; //股票状态 （0:正常，1:查封）        
    }

    struct Body {
        uint64 paid; //实缴出资
        uint64 par; //票面金额（注册资本面值）
        uint64 cleanPaid; //清洁金额（扣除出质、远期票面金额）
        uint64 cleanPar;
    }

    //Share 股票
    struct Share {
        Head head; //出资证明书编号（股票编号）
        Body body;
    }

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
        uint64 amount,
        uint48 paidInDate
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
        bytes32 shareNumber,
        uint64 paid,
        uint64 par
    ) external;

    function regShare(
        Head memory head,
        uint64 paid,
        uint64 par
    ) external;

    function setPayInAmt(bytes32 sn, uint64 amount) external;

    function requestPaidInCapital(bytes32 sn, string memory hashKey) external;

    function withdrawPayInAmt(bytes32 sn) external;

    function transferShare(
        uint256 seq,
        uint64 paid,
        uint64 par,
        uint40 to,
        uint32 unitPrice
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
        returns (Head memory head);

    function getBodyOfShare(uint256 seq)
        external
        view
        returns (Body memory body);

    function getShare(uint256 seq)
        external
        view
        returns (Share memory share);


    function getLocker(bytes32 sn) external view returns (uint64 amount);
}
