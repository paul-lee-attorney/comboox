// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "./IListOfOrders_2.sol";
import "../../common/access/AccessControl.sol";

contract ListOfOrders_2 is IListOfOrders_2, AccessControl {
    using OrdersRepo_2 for OrdersRepo_2.Repo;
    using OrdersRepo_2 for OrdersRepo_2.Deal;
    using GoldChain_2 for GoldChain_2.Chain;
    using GoldChain_2 for GoldChain_2.Node;
    using GoldChain_2 for GoldChain_2.Data;
    using EnumerableSet for EnumerableSet.UintSet;
    using InvestorsRepo for InvestorsRepo.Repo;

    InvestorsRepo.Repo private _investors;

    mapping (uint => OrdersRepo_2.Repo) private _ordersOfClass;
    EnumerableSet.UintSet private _classesList;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Investor ====

    function regInvestor(
        uint userNo,
        uint groupRep,
        bytes32 idHash
    ) external onlyDK {
        _investors.regInvestor(userNo, groupRep, idHash);
        emit RegInvestor(userNo, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        uint verifier
    ) external onlyDK {
        _investors.approveInvestor(userNo, verifier);
        emit ApproveInvestor(userNo, verifier);
    }        

    function revokeInvestor(
        uint userNo,
        uint verifier
    ) external onlyDK {
        _investors.revokeInvestor(userNo, verifier);
        emit RevokeInvestor(userNo, verifier);
    }

    // ==== Order ====

    function placeSellOrder(
        uint caller,
        uint classOfShare,
        uint seqOfShare,
        uint votingWeight,
        uint distrWeight,
        uint paid,
        uint price,
        uint execHours,
        uint centPriceInWei
    ) external onlyDK returns(
        OrdersRepo_2.Deal[] memory deals, 
        GoldChain_2.Order[] memory expired,
        OrdersRepo_2.Deal memory offer
    ) {
        _classesList.add(classOfShare);

        (deals, expired, offer) = _ordersOfClass[classOfShare].placeSellOrder(
            caller,
            classOfShare,
            seqOfShare,
            votingWeight,
            distrWeight,
            paid, 
            price,
            execHours,
            centPriceInWei
        );

        if (deals.length > 0) _logDeals(deals);
        if (expired.length > 0) _logExpired(expired, false);
        if (offer.price > 0) _logOrder(offer, true);
    }

    function _logOrder(OrdersRepo_2.Deal memory order, bool isOffer) private {
        emit OrderPlaced(order.codifyDeal(), isOffer);
    }

    function _logDeals(OrdersRepo_2.Deal[] memory deals) private {
        uint len = deals.length;
        while (len > 0) {
            emit DealClosed(deals[len - 1].codifyDeal(), deals[len - 1].consideration);
            len--;
        }
    }

    function _logExpired(GoldChain_2.Order[] memory expired, bool isOffer) private {
        uint len = expired.length;
        while (len > 0) {
            emit OrderExpired(expired[len - 1].node.codifyNode(),
                expired[len - 1].data.codifyData(),isOffer);
            len--;
        }
    }

    function placeBuyOrder(
        uint classOfShare,
        uint caller,
        uint groupRep,
        uint paid,
        uint price,
        uint execHours,
        uint centPriceInWei,
        uint msgValue
    ) external onlyDK returns (
        OrdersRepo_2.Deal[] memory deals, 
        GoldChain_2.Order[] memory expired,
        OrdersRepo_2.Deal memory bid
    ) {

        _classesList.add(classOfShare);

        (deals, expired, bid) = _ordersOfClass[classOfShare].placeBuyOrder(
            classOfShare,
            caller,
            groupRep,
            paid, 
            price,
            execHours,
            centPriceInWei,
            msgValue
        );

        if (deals.length > 0) _logDeals(deals);
        if (expired.length > 0) _logExpired(expired, true);
        if (bid.price > 0) _logOrder(bid, false);
    }

    function withdrawOrder(
        uint classOfShare,
        uint seqOfOrder,
        bool isOffer
    ) external onlyDK returns(GoldChain_2.Order memory order) {

        if (!_classesList.contains(classOfShare)) return order;

        order = _ordersOfClass[classOfShare].withdrawOrder(
            seqOfOrder, isOffer
        );

        if (order.node.paid > 0) emit OrderWithdrawn(
            order.node.codifyNode(), order.data.codifyData(), isOffer
        );
    }

    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        uint userNo
    ) external view returns(bool) {
        return _investors.isInvestor(userNo);
    }

    function getInvestor(
        uint userNo
    ) external view returns(InvestorsRepo.Investor memory) {
        return _investors.getInvestor(userNo);
    }

    function getQtyOfInvestors() 
        external view returns(uint) 
    {
        return _investors.getQtyOfInvestors();
    }

    function investorList() 
        external view returns(uint[] memory) 
    {
        return _investors.investorList();
    }

    function investorInfoList() 
        external view returns(InvestorsRepo.Investor[] memory) 
    {
        return _investors.investorInfoList();
    }

    // ==== Chain ====

    function counterOfOrders(
        uint classOfShare, bool isOffer
    ) external view returns (uint32) {
        if (!_classesList.contains(classOfShare)) return 0;
        return _ordersOfClass[classOfShare].counterOfOrders(isOffer);
    }

    function headOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint32) {
        if (!_classesList.contains(classOfShare)) return 0;
        return _ordersOfClass[classOfShare].headOfList(isOffer);
    }

    function tailOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint32) {
        if (!_classesList.contains(classOfShare)) return 0;
        return _ordersOfClass[classOfShare].tailOfList(isOffer);
    }

    function lengthOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint) {
        if (!_classesList.contains(classOfShare)) return 0;
        return _ordersOfClass[classOfShare].lengthOfList(isOffer);
    }

    function getSeqList(
        uint classOfShare, bool isOffer
    ) external view returns (uint[] memory list) {
        if (!_classesList.contains(classOfShare)) return list;
        list = _ordersOfClass[classOfShare].getSeqList(isOffer);
    }

    // ==== Order ====

    function isOrder(
        uint classOfShare, uint seqOfOrder, bool isOffer
    ) external view returns (bool) {
        if (!_classesList.contains(classOfShare)) return false;
        return _ordersOfClass[classOfShare].isOrder(isOffer, seqOfOrder);
    }
    
    function getOrder(
        uint classOfShare, uint seqOfOrder, bool isOffer
    ) external view returns (GoldChain_2.Order memory order) {
        if (!_classesList.contains(classOfShare)) return order;
        order = _ordersOfClass[classOfShare].getOrder(isOffer, seqOfOrder);
    }

    function getOrders(
        uint classOfShare, bool isOffer
    ) external view returns (GoldChain_2.Order[] memory list) {
        if (!_classesList.contains(classOfShare)) return list;
        list = _ordersOfClass[classOfShare].getOrders(isOffer);
    }

    // ==== Class ====
    function isClass(uint classOfShare) external view returns(bool) {
        return _classesList.contains(classOfShare);
    }

    function getClassesList() external view returns(uint[] memory) {
        return _classesList.values();
    }

}
