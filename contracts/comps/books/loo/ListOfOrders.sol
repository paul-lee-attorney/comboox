// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
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
    using UsdOrdersRepo for UsdOrdersRepo.Repo;
    using UsdOrdersRepo for UsdOrdersRepo.Deal;
    using GoldChain for GoldChain.Chain;
    using GoldChain for GoldChain.Node;
    using GoldChain for GoldChain.Data;
    using EnumerableSet for EnumerableSet.UintSet;

    // class of share => order book for the class
    mapping (uint => UsdOrdersRepo.Repo) private _ordersOfClass;
    // List of classes traded in this order book.
    EnumerableSet.UintSet private _classesList;

    // ==== UUPSUpgradable ====
    uint256[50] private __gap;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Order ====

    function placeSellOrder(
        UsdOrdersRepo.Deal memory input, uint execHours
    ) external onlyDK returns(
        UsdOrdersRepo.Deal[] memory deals, 
        uint lenOfDeals,
        GoldChain.Order[] memory expired,
        uint lenOfExpired,
        UsdOrdersRepo.Deal memory offer
    ) {
        _classesList.add(input.classOfShare);

        (deals, lenOfDeals, expired, lenOfExpired, offer) = 
            _ordersOfClass[input.classOfShare].placeSellOrder(
                input,
                execHours
            );

        if (lenOfDeals > 0) _logDeals(deals, lenOfDeals);
        if (lenOfExpired > 0) _logExpired(expired, false, lenOfExpired);
        if (offer.price > 0) _logOrder(offer, true);
    }

    function _bpToDt(uint amt) private pure returns(uint) {
        return amt * 10 ** 10;
    }

    function _logOrder(UsdOrdersRepo.Deal memory order, bool isOffer) private {
        (bytes32 fromSn, bytes32 toSn, bytes32 qtySn) = order.codifyDeal();
        emit OrderPlaced(fromSn, toSn, qtySn, isOffer);
    }

    function _logDeals(UsdOrdersRepo.Deal[] memory deals, uint len) private {
        while (len > 0) {
            (bytes32 fromSn, bytes32 toSn, bytes32 qtySn) = 
                deals[len - 1].codifyDeal();
            emit DealClosed(fromSn, toSn, qtySn, _bpToDt(deals[len - 1].consideration));
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
        UsdOrdersRepo.Deal memory input,
        uint execHours
    ) external onlyDK returns (
        UsdOrdersRepo.Deal[] memory deals,
        uint lenOfDeals, 
        GoldChain.Order[] memory expired,
        uint lenOfExpired,
        UsdOrdersRepo.Deal memory bid
    ) {

        _classesList.add(input.classOfShare);

        (deals, lenOfDeals, expired, lenOfExpired, bid) = 
            _ordersOfClass[input.classOfShare].placeBuyOrder(
                input,
                execHours
            );

        if (lenOfDeals > 0) _logDeals(deals, lenOfDeals);
        if (lenOfExpired > 0) _logExpired(expired, true, lenOfExpired);
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
