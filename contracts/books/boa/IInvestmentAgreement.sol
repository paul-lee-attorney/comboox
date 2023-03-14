// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../../common/components/ISigPage.sol";

interface IInvestmentAgreement {

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        PreEmptive,
        TagAlong,
        DragAlong,
        FirstRefusal,
        FreeGift
    }

    enum TypeOfIA {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STint,
        SText_STint,
        CI_SText_STint,
        CI_SText
    }

    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }

    struct Head {
        uint8 typeOfDeal;
        uint16 seq;
        uint16 preSeq;
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 seller;
        uint32 priceOfPaid;
        uint32 priceOfPar;
        uint48 closingDate;
        uint8 state;
    }

    struct Body {
        uint40 buyer;
        uint40 groupOfBuyer;
        uint64 paid;
        uint64 par;
    }

    struct Deal {
        Head head;
        Body body;
        bytes32 hashLock;
    }

    //##################
    //##    Event     ##
    //##################

    // ======== normalDeal ========

    event ClearDealCP(
        uint256 indexed seq,
        uint8 state,
        bytes32 hashLock,
        uint48 closingDate
    );

    event CloseDeal(uint256 indexed seq, string hashKey);

    event RevokeDeal(uint256 indexed seq, string hashKey);

    event TerminateDeal(uint256 indexed seq);

    //##################
    //##    写接口    ##
    //##################

    // ======== InvestmentAgreement ========

    function createDeal(
        bytes32 sn,
        uint40 buyer,
        uint40 groupOfBuyer,
        uint64 paid,
        uint64 par
    ) external;

    function regDeal(Deal memory deal) external returns(uint32 seqOfDeal);

    function delDeal(uint256 seq) external;

    function lockDealSubject(uint256 seq) external returns (bool flag);

    function releaseDealSubject(uint256 seq) external returns (bool flag);

    function clearDealCP(
        uint256 seq,
        bytes32 hashLock,
        uint48 closingDate
    ) external;

    function closeDeal(uint256 seq, string memory hashKey)
        external
        returns (bool);

    function revokeDeal(uint256 seq, string memory hashKey)
        external
        returns (bool);

    function terminateDeal(uint256 seqOfDeal) external;


    function takeGift(uint256 seq) external returns(bool);

    function setTypeOfIA(uint8 t) external;

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    // ======== InvestmentAgreement ========
    function getTypeOfIA() external view returns (uint8);

    function counterOfDeal() external view returns (uint32);

    function counterOfClosedDeal() external view returns (uint32);

    function isDeal(uint256 seq) external view returns (bool);

    function getHeadOfDeal(uint256 seq) external view returns (Head memory);

    function getBodyOfDeal(uint256 seq) external view returns (Body memory);

    function hashLockOfDeal(uint256 seq) external view returns (bytes32);

    function getDeal(uint256 seq) external view returns (Deal memory);

    function seqList() external view returns (uint256[] memory);
}
