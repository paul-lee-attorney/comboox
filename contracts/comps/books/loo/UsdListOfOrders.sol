// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2025 LI LI @ JINGTIAN & GONGCHENG.
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

import "./IUsdListOfOrders.sol";
import "../../common/access/AccessControl.sol";

contract UsdListOfOrders is IUsdListOfOrders, AccessControl {
    using OrdersRepo for OrdersRepo.Repo;
    using OrdersRepo for OrdersRepo.Deal;
    using GoldChain for GoldChain.Chain;
    using GoldChain for GoldChain.Node;
    using GoldChain for GoldChain.Data;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping (uint => OrdersRepo.Repo) private _ordersOfClass;
    EnumerableSet.UintSet private _classesList;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Order ====

    function placeSellOrder(
        OrdersRepo.Deal memory input, uint execHours
    ) external onlyDK returns(
        OrdersRepo.Deal[] memory deals, 
        GoldChain.Order[] memory expired,
        OrdersRepo.Deal memory offer
    ) {
        _classesList.add(input.classOfShare);

        (deals, expired, offer) = _ordersOfClass[input.classOfShare].placeSellOrder(
            input,
            execHours,
            0
        );

        if (deals.length > 0) _logDeals(deals);
        if (expired.length > 0) _logExpired(expired, false);
        if (offer.price > 0) _logOrder(offer, true);
    }

    function _bpToDt(uint amt) private pure returns(uint) {
        return amt * 10 ** 10;
    }

    function _logOrder(OrdersRepo.Deal memory order, bool isOffer) private {
        (bytes32 fromSn, bytes32 toSn, bytes32 qtySn) = order.codifyDeal();
        emit OrderPlaced(fromSn, toSn, qtySn, isOffer);
    }

    function _logDeals(OrdersRepo.Deal[] memory deals) private {
        uint len = deals.length;
        while (len > 0) {
            (bytes32 fromSn, bytes32 toSn, bytes32 qtySn) = 
                deals[len - 1].codifyDeal();
            emit DealClosed(fromSn, toSn, qtySn, _bpToDt(deals[len - 1].consideration));
            len--;
        }
    }

    function _logExpired(GoldChain.Order[] memory expired, bool isOffer) private {
        uint len = expired.length;
        while (len > 0) {
            emit OrderExpired(expired[len - 1].node.codifyNode(),
                expired[len - 1].data.codifyData(), isOffer);
            len--;
        }
    }

    function placeBuyOrder(
        OrdersRepo.Deal memory input,
        uint execHours
    ) external onlyDK returns (
        OrdersRepo.Deal[] memory deals, 
        GoldChain.Order[] memory expired,
        OrdersRepo.Deal memory bid
    ) {

        _classesList.add(input.classOfShare);

        (deals, expired, bid) = _ordersOfClass[input.classOfShare].placeBuyOrder(
            input,
            execHours,
            0
        );

        if (deals.length > 0) _logDeals(deals);
        if (expired.length > 0) _logExpired(expired, true);
        if (bid.price > 0) _logOrder(bid, false);
    }

    function withdrawOrder(
        uint classOfShare, uint seqOfOrder, bool isOffer
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
