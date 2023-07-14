// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/lib/DealsRepo.sol";

interface IInvestmentAgreement {

    //##################
    //##    Event     ##
    //##################

    event AddDeal(uint indexed seqOfDeal);

    event ClearDealCP(
        uint256 indexed seq,
        bytes32 indexed hashLock,
        uint indexed closingDeadline
    );

    event CloseDeal(uint256 indexed seq, string indexed hashKey);

    // event RevokeDeal(uint256 indexed seq, string indexed hashKey);

    event TerminateDeal(uint256 indexed seq);

    //##################
    //##    写接口    ##
    //##################

    // ======== InvestmentAgreement ========

    function addDeal(
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par
    ) external;

    function regDeal(DealsRepo.Deal memory deal) external returns(uint16 seqOfDeal);

    function delDeal(uint256 seq) external;

    function lockDealSubject(uint256 seq) external returns (bool flag);

    function releaseDealSubject(uint256 seq) external returns (bool flag);

    function clearDealCP( uint256 seq, bytes32 hashLock, uint closingDeadline) external;

    function closeDeal(uint256 seq, string memory hashKey)
        external returns (bool flag);

    function directCloseDeal(uint256 seq) external returns (bool flag);

    // function revokeDeal(uint256 seq, string memory hashKey)
    //     external returns (bool);

    function terminateDeal(uint256 seqOfDeal) external returns(bool);

    function takeGift(uint256 seq) external returns(bool);

    function setTypeOfIA(uint t) external;

    //  #####################
    //  ##     查询接口     ##
    //  #####################

    // ======== InvestmentAgreement ========
    function getTypeOfIA() external view returns (uint8);

    function counterOfDeal() external view returns (uint16);

    function counterOfClosedDeal() external view returns (uint16);

    function isDeal(uint256 seq) external view returns (bool);

    function getHeadOfDeal(uint256 seq) external view returns (DealsRepo.Head memory);

    function getBodyOfDeal(uint256 seq) external view returns (DealsRepo.Body memory);

    function getHashLockOfDeal(uint256 seq) external view returns (bytes32);

    function getDeal(uint256 seq) external view returns (DealsRepo.Deal memory);

    function getSeqList() external view returns (uint[] memory);
}
