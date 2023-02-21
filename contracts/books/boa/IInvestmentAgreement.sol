// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../../common/components/ISigPage.sol";

interface IInvestmentAgreement {

    struct Deal {
        bytes32 sn;
        uint64 paid;
        uint64 par;
        uint48 closingDate;
        uint8 state;
        bytes32 hashLock;
    }

    enum TypeOfDeal {
        ZeroPoint,
        CapitalIncrease,
        ShareTransferExt,
        ShareTransferInt,
        CI_STint,
        SText_STint,
        CI_SText_STint,
        CI_SText,
        PreEmptive,
        TagAlong,
        DragAlong,
        FirstRefusal,
        FreeGift
    }

    enum StateOfDeal {
        Drafting,
        Locked,
        Cleared,
        Closed,
        Terminated
    }


    //##################
    //##    Event     ##
    //##################

    // ======== normalDeal ========

    event CreateDeal(
        bytes32 indexed sn,
        uint64 paid,
        uint64 par,
        uint48 closingDate
    );

    event UpdateDeal(
        bytes32 indexed sn,
        uint64 paid,
        uint64 par,
        uint48 closingDate
    );

    event ClearDealCP(
        bytes32 indexed sn,
        uint8 state,
        bytes32 hashLock,
        uint48 closingDate
    );

    event CloseDeal(bytes32 indexed sn, string hashKey);

    event RevokeDeal(bytes32 indexed sn, string hashKey);

    //##################
    //##    写接口    ##
    //##################

    // ======== InvestmentAgreement ========

    function createDeal(
        bytes32 sn,
        uint64 paid,
        uint64 par,
        uint48 closingDate
    ) external;

    function updateDeal(
        uint16 seq,
        uint64 paid,
        uint64 par,
        uint48 closingDate
    ) external;

    function setTypeOfIA(uint8 t) external;

    function delDeal(uint16 seq) external;

    function lockDealSubject(uint16 seq) external returns (bool flag);

    function releaseDealSubject(uint16 seq) external returns (bool flag);

    function clearDealCP(
        uint16 seq,
        bytes32 hashLock,
        uint48 closingDate
    ) external;

    function closeDeal(uint16 seq, string memory hashKey)
        external
        returns (bool);

    function revokeDeal(uint16 seq, string memory hashKey)
        external
        returns (bool);

    function takeGift(uint16 seq) external returns(bool);

    //  ######################
    //  ##     查询接口     ##
    //  ######################

    // ======== InvestmentAgreement ========
    function typeOfIA() external view returns (uint8);

    function isDeal(uint16 seq) external view returns (bool);

    function counterOfDeals() external view returns (uint16);

    function getDeal(uint16 seq)
        external
        view
        returns (Deal memory deal);

    // function closingDateOfDeal(uint16 seq) external view returns (uint48);

    function dealsList() external view returns (bytes32[] memory);
}
