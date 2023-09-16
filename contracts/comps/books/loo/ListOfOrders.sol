// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IListOfOrders.sol";
import "../../common/access/AccessControl.sol";

contract ListOfOrders is IListOfOrders, AccessControl {
    using OrdersRepo for OrdersRepo.Repo;
    using GoldChain for GoldChain.Chain;

    OrdersRepo.Repo private _repo;

    //#################
    //##  Write I/O  ##
    //#################

    function regInvestor(
        uint userNo,
        uint groupRep,
        bytes32 idHash
    ) external onlyDK {
        _repo.regInvestor(userNo, groupRep, idHash);
        emit RegInvestor(userNo, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        uint verifier
    ) external onlyDK {
        _repo.approveInvestor(userNo, verifier);
        emit ApproveInvestor(userNo, verifier);
    }        

    function placePutOrder(
        uint offeror,
        uint classOfShare,
        uint seqOfShare,
        uint execHours,
        uint paid,
        uint price
    ) external onlyDK {
        GoldChain.Order memory order = 
            _repo.placePutOrder(
                offeror, 
                classOfShare, 
                seqOfShare, 
                execHours, 
                paid, 
                price
            );

        emit PlacePutOrder(GoldChain.codifyOrder(order), order.expireDate);
    }    

    function placeCallOrder(
        uint offeror,
        uint classOfShare,
        uint paid,
        uint price
    ) external onlyDK returns (
        OrdersRepo.Deal[] memory deals, 
        GoldChain.Order memory call
    ) {
        (deals, call) = _repo.placeCallOrder(
            offeror,
            classOfShare,
            paid,
            price
        );

        emit PlaceCallOrder(GoldChain.codifyOrder(call), call.paid);
    }

    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        uint userNo
    ) external view returns(bool) {
        return _repo.isInvestor(userNo);
    }

    function getInvestor(
        uint userNo
    ) external view returns(OrdersRepo.Investor memory) {
        return _repo.getInvestor(userNo);
    }

    function getQtyOfInvestors() 
        external view returns(uint) 
    {
        return _repo.getQtyOfInvestors();
    }

    function getInvList() 
        external view returns(uint[] memory) 
    {
        return _repo.getInvList();
    }

    function getInvestorsList() 
        external view returns(OrdersRepo.Investor[] memory) 
    {
        return _repo.getInvestorsList();
    }

    // ==== Deals ====

    function getCounterOfDeals(
        uint classOfShare  
    ) external view returns(uint32) {   
        return _repo.getCounterOfDeals(classOfShare);
    }

    function getDeal(
        uint classOfShare,
        uint seqOfDeal
    ) external view returns(OrdersRepo.Deal memory ) {   
        return _repo.getDeal(classOfShare, seqOfDeal);
    }

    function getDealsList(
        uint classOfShare,
        uint lastDealSeq,
        uint len
    ) external view returns(OrdersRepo.Deal[] memory ) {
        return _repo.getDealsList(classOfShare, lastDealSeq, len);
    }

    // ==== List ====

    function getHeadSeqOfList(
        uint classOfShare,
        bool isPut
    ) external view returns (uint32) {
        
        GoldChain.Chain storage chain = isPut
            ? _repo.ordersOfClass[classOfShare].putOrders
            : _repo.ordersOfClass[classOfShare].callOrders;

        return chain.getHeadSeqOfList();
    }

    function getTailSeqOfList(
        uint classOfShare,
        bool isPut
    ) external view returns (uint32) {

        GoldChain.Chain storage chain = isPut
            ? _repo.ordersOfClass[classOfShare].putOrders
            : _repo.ordersOfClass[classOfShare].callOrders;

        return chain.getTailSeqOfList();
    }

    function getLengthOfList(
        uint classOfShare,
        bool isPut
    ) external view returns (uint) {

        GoldChain.Chain storage chain = isPut
            ? _repo.ordersOfClass[classOfShare].putOrders
            : _repo.ordersOfClass[classOfShare].callOrders;

        return chain.getLengthOfList();
    }

    function getList(
        uint classOfShare,
        bool isPut
    ) external view returns (GoldChain.Order[] memory) {

        GoldChain.Chain storage chain = isPut
            ? _repo.ordersOfClass[classOfShare].putOrders
            : _repo.ordersOfClass[classOfShare].callOrders;

        return chain.getList();
    }

    // ==== Order ====

    function getCounterOfOrders(
        uint classOfShare,
        bool isPut
    ) external view returns (uint32) {

        GoldChain.Chain storage chain = isPut
            ? _repo.ordersOfClass[classOfShare].putOrders
            : _repo.ordersOfClass[classOfShare].callOrders;

        return chain.getCounterOfOrders();
    }
    
    function getOrder(
        uint classOfShare,
        bool isPut,
        uint seqOfOrder
    ) external view returns (GoldChain.Order memory ) {
        
        GoldChain.Chain storage chain = isPut
            ? _repo.ordersOfClass[classOfShare].putOrders
            : _repo.ordersOfClass[classOfShare].callOrders;

        return chain.getOrder(seqOfOrder);
    }

    function getChain(
        uint classOfShare,
        bool isPut
    ) external view returns (GoldChain.Order[] memory) {

        GoldChain.Chain storage chain = isPut
            ? _repo.ordersOfClass[classOfShare].putOrders
            : _repo.ordersOfClass[classOfShare].callOrders;

        return chain.getChain();        
    }

}
