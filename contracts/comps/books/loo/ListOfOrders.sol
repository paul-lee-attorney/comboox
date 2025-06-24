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

import "./IListOfOrders.sol";
import "../../common/access/AccessControl.sol";

contract ListOfOrders is IListOfOrders, AccessControl {
    using OrdersRepo for OrdersRepo.Repo;
    using OrdersRepo for OrdersRepo.Deal;
    using GoldChain for GoldChain.Chain;
    using GoldChain for GoldChain.Node;
    using GoldChain for GoldChain.Data;
    using EnumerableSet for EnumerableSet.UintSet;
    using InvestorsRepo for InvestorsRepo.Repo;

    InvestorsRepo.Repo private _investors;

    mapping (uint => OrdersRepo.Repo) private _ordersOfClass;
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

    function restoreInvestorsRepo(
        InvestorsRepo.Investor[] memory list, uint qtyOfInvestors
    ) external onlyDK {
        _investors.restoreRepo(list, qtyOfInvestors);
    }

    // ==== Order ====

    function placeSellOrder(
        OrdersRepo.Deal memory input,
        uint execHours,
        uint centPriceInWei
    ) external onlyDK returns(
        OrdersRepo.Deal[] memory deals,
        uint lenOfDeals,
        GoldChain.Order[] memory expired,
        uint lenOfExpired,
        OrdersRepo.Deal memory offer
    ) {
        _classesList.add(input.classOfShare);

        (deals, lenOfDeals, expired, lenOfExpired, offer) = _ordersOfClass[input.classOfShare].placeSellOrder(
            input,
            execHours,
            centPriceInWei
        );

        if (lenOfDeals > 0) _logDeals(deals, lenOfDeals);
        if (lenOfExpired > 0) _logExpired(expired, false, lenOfExpired);
        if (offer.price > 0) _logOrder(offer, true);
    }

    function _logOrder(OrdersRepo.Deal memory order, bool isOffer) private {
        emit OrderPlaced(order.codifyBrief(), isOffer);
    }

    function _logDeals(OrdersRepo.Deal[] memory deals, uint len) private {
        while (len > 0) {
            emit DealClosed(deals[len - 1].codifyBrief(), deals[len - 1].consideration);
            len--;
        }
    }

    function _logExpired(GoldChain.Order[] memory expired, bool isOffer, uint len) private {
        while (len > 0) {
            emit OrderExpired(expired[len - 1].node.codifyNode(),
                expired[len - 1].data.codifyData(), isOffer);
            len--;
        }
    }

    function placeBuyOrder(
        OrdersRepo.Deal memory input,
        uint execHours,
        uint centPriceInWei
    ) external onlyDK returns (
        OrdersRepo.Deal[] memory deals, 
        uint lenOfDeals, 
        GoldChain.Order[] memory expired,
        uint lenOfExpired,
        OrdersRepo.Deal memory bid
    ) {

        _classesList.add(input.classOfShare);

        (deals, lenOfDeals, expired, lenOfExpired, bid) = _ordersOfClass[input.classOfShare].placeBuyOrder(
            input,
            execHours,
            centPriceInWei
        );

        if (lenOfDeals > 0) _logDeals(deals, lenOfDeals);
        if (lenOfExpired > 0) _logExpired(expired, true, lenOfExpired);
        if (bid.price > 0) _logOrder(bid, false);
    }

    function withdrawOrder(
        uint classOfShare,
        uint seqOfOrder,
        bool isOffer
    ) external onlyDK returns(GoldChain.Order memory order) {

        if (!_classesList.contains(classOfShare)) return order;

        order = _ordersOfClass[classOfShare].withdrawOrder(
            seqOfOrder, isOffer
        );

        emit OrderWithdrawn(
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
    ) external view returns (GoldChain.Order memory order) {
        if (!_classesList.contains(classOfShare)) return order;
        order = _ordersOfClass[classOfShare].getOrder(isOffer, seqOfOrder);
    }

    function getOrders(
        uint classOfShare, bool isOffer
    ) external view returns (GoldChain.Order[] memory list) {
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
