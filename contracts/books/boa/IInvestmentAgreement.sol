// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/ISigPage.sol";

interface IInvestmentAgreement is ISigPage {
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

    event SetTypeOfIA(uint8 t);

    event DelDeal(bytes32 indexed sn);

    event LockDealSubject(bytes32 indexed sn);

    event ReleaseDealSubject(bytes32 indexed sn);

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

    function takeGift(uint16 seq) external;

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
        returns (
            bytes32 sn,
            uint64 paid,
            uint64 par,
            uint8 state, // 0-pending 1-cleared 2-closed 3-terminated
            bytes32 hashLock
        );

    function closingDateOfDeal(uint16 seq) external view returns (uint48);

    function dealsList() external view returns (bytes32[] memory);
}
