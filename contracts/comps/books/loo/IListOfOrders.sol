// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../lib/OrdersRepo.sol";
import "../../../lib/GoldChain.sol";

interface IListOfOrders {

    //################
    //##   Events   ##
    //################

    event RegInvestor(uint indexed investor, uint indexed groupRep, bytes32 indexed idHash);

    event ApproveInvestor(uint indexed investor, uint indexed verifier);

    event PlacePutOrder(bytes32 indexed order, uint indexed expireDate);

    event PlaceCallOrder(bytes32 indexed order, uint indexed balanceOfPaid);

    //##################
    //##  Write I/O  ##
    //##################

    function regInvestor(
        uint acct,
        uint groupRep,
        bytes32 idHash
    ) external;

    function approveInvestor(
        uint userNo,
        uint verifier
    ) external;

    function placePutOrder(
        uint offeror,
        uint classOfShare,
        uint seqOfShare,
        uint execHours,
        uint paid,
        uint price
    ) external;

    function placeCallOrder(
        uint offeror,
        uint classOfShare,
        uint paid,
        uint price
    ) external returns (
        OrdersRepo.Deal[] memory deals,
        GoldChain.Order memory call
    );

    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        uint userNo
    ) external view returns(bool);

    function getInvestor(
        uint userNo
    ) external view returns(OrdersRepo.Investor memory);

    function getQtyOfInvestors() 
        external view returns(uint);

    function getInvList() 
        external view returns(uint[] memory);

    function getInvestorsList() 
        external view returns(OrdersRepo.Investor[] memory);

    // ==== Deals ====

    function getCounterOfDeals(
        uint classOfShare  
    ) external view returns(uint32);

    function getDeal(
        uint classOfShare,
        uint seqOfDeal
    ) external view returns(OrdersRepo.Deal memory);

    function getDealsList(
        uint classOfShare,
        uint lastDealSeq,
        uint len
    ) external view returns(OrdersRepo.Deal[] memory);

    // ==== List ====

    function getHeadSeqOfList(
        uint classOfShare,
        bool isPut
    ) external view returns (uint32);

    function getTailSeqOfList(
        uint classOfShare,
        bool isPut
    ) external view returns (uint32);

    function getLengthOfList(
        uint classOfShare,
        bool isPut
    ) external view returns (uint);

    function getList(
        uint classOfShare,
        bool isPut
    ) external view returns (GoldChain.Order[] memory);

    // ==== Order ====

    function getCounterOfOrders(
        uint classOfShare,
        bool isPut
    ) external view returns (uint32);
    
    function getOrder(
        uint classOfShare,
        bool isPut,
        uint seqOfOrder
    ) external view returns (GoldChain.Order memory);

    function getChain(
        uint classOfShare,
        bool isPut
    ) external view returns (GoldChain.Order[] memory);

}
