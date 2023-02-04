// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBookOfShares {
    //##################
    //##    Event     ##
    //##################

    event IssueShare(
        bytes32 indexed shareNumber,
        uint64 paid,
        uint64 par,
        uint48 paidInDeadline
    );

    event PayInCapital(
        bytes32 indexed shareNumber,
        uint64 amount,
        uint48 paidInDate
    );

    event SubAmountFromShare(
        bytes32 indexed shareNumber,
        uint64 paid,
        uint64 par
    );

    event DeregisterShare(bytes32 indexed shareNumber);

    event UpdateStateOfShare(bytes32 indexed shareNumber, uint8 state);

    event UpdatePaidInDeadline(
        bytes32 indexed shareNumber,
        uint48 paidInDeadline
    );

    event DecreaseCleanPar(bytes32 indexed shareNumber, uint64 paid);

    event IncreaseCleanPar(bytes32 indexed shareNumber, uint64 paid);

    event SetPayInAmount(bytes32 indexed sn, uint64 amount);

    event WithdrawPayInAmount(bytes32 indexed sn);

    //##################
    //##    写接口    ##
    //##################

    function issueShare(
        bytes32 shareNumber,
        uint64 paid,
        uint64 par,
        uint48 paidInDeadline
    ) external;

    function setPayInAmount(bytes32 sn, uint64 amount) external;

    function requestPaidInCapital(bytes32 sn, string memory hashKey) external;

    function withdrawPayInAmount(bytes32 sn) external;

    function transferShare(
        uint32 ssn,
        uint64 paid,
        uint64 par,
        uint40 to,
        uint32 unitPrice
    ) external;

    function createShareNumber(
        uint16 class,
        uint32 ssn,
        uint48 issueDate,
        uint40 shareholder,
        uint32 unitPrice,
        uint32 preSSN
    ) external pure returns (bytes32 sn);

    function decreaseCapital(
        uint32 ssn,
        uint64 paid,
        uint64 par
    ) external;

    // ==== CleanPar ====

    function decreaseCleanPar(uint32 ssn, uint64 paid) external;

    function increaseCleanPar(uint32 ssn, uint64 paid) external;

    // ==== State & PaidInDeadline ====

    function updateStateOfShare(uint32 ssn, uint8 state) external;

    function updatePaidInDeadline(uint32 ssn, uint48 paidInDeadline) external;

    // ##################
    // ##   查询接口   ##
    // ##################

    // ==== BookOfShares ====

    function counterOfShares() external view returns (uint32);

    function counterOfClasses() external view returns (uint16);

    function isShare(uint32 ssn) external view returns (bool);

    function cleanPar(uint32 ssn) external view returns (uint64);

    function getShare(uint32 ssn)
        external
        view
        returns (
            bytes32 shareNumber,
            uint64 paid,
            uint64 par,
            uint48 paidInDeadline,
            uint8 state
        );

    function getLocker(bytes32 sn) external view returns (uint64 amount);
}
