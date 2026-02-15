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

pragma solidity ^0.8.24;

import "../../../lib/books/UsdOrdersRepo.sol";
import "../../../lib/books/GoldChain.sol";
import "../../../lib/books/InvestorsRepo.sol";
import "../../../openzeppelin/utils/structs/EnumerableSet.sol";

/// @title IListOfOrders
/// @notice Order book interface for USD orders and matching results.
interface IListOfOrders {

    //################
    //##   Events   ##
    //################

    /// @notice Emitted when a new order is placed.
    /// @param fromSn From-order serial number.
    /// @param toSn To-order serial number.
    /// @param qtySn Quantity serial number.
    /// @param isOffer True for offer, false for bid.
    event OrderPlaced(bytes32 indexed fromSn, bytes32 indexed toSn, bytes32 indexed qtySn, bool isOffer);

    /// @notice Emitted when an order is withdrawn.
    /// @param head Order head serial number.
    /// @param body Order body serial number.
    /// @param isOffer True for offer, false for bid.
    event OrderWithdrawn(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer);

    /// @notice Emitted when a deal is closed from matching orders.
    /// @param fromSn From-order serial number.
    /// @param toSn To-order serial number.
    /// @param qtySn Quantity serial number.
    /// @param consideration Deal consideration.
    event DealClosed(bytes32 indexed fromSn, bytes32 indexed toSn, bytes32 qtySn, uint indexed consideration);

    /// @notice Emitted when an order expires.
    /// @param head Order head serial number.
    /// @param body Order body serial number.
    /// @param isOffer True for offer, false for bid.
    event OrderExpired(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer);

    //#################
    //##  Write I/O  ##
    //#################

    /// @notice Match and/or place a sell offer.
    /// @param input Offer data.
    /// @param execHours Expiration in hours.
    /// @return deals Matched deals.
    /// @return lenOfDeals Number of valid deals.
    /// @return expired Expired orders.
    /// @return lenOfExpired Number of expired orders.
    /// @return offer Remaining offer.
    function placeSellOrder(
        UsdOrdersRepo.Deal memory input,
        uint execHours
    ) external returns(
        UsdOrdersRepo.Deal[] memory deals, 
        uint lenOfDeals,
        GoldChain.Order[] memory expired,
        uint lenOfExpired,
        UsdOrdersRepo.Deal memory offer
    );

    /// @notice Match and/or place a buy bid.
    /// @param input Bid data.
    /// @param execHours Expiration in hours.
    /// @return deals Matched deals.
    /// @return lenOfDeals Number of valid deals.
    /// @return expired Expired orders.
    /// @return lenOfExpired Number of expired orders.
    /// @return bid Remaining bid.
    function placeBuyOrder(
        UsdOrdersRepo.Deal memory input,
        uint execHours
    ) external returns (
        UsdOrdersRepo.Deal[] memory deals, 
        uint lenOfDeals,
        GoldChain.Order[] memory expired,
        uint lenOfExpired,
        UsdOrdersRepo.Deal memory bid
    );

    /// @notice Withdraw an order.
    /// @param classOfShare Share class id.
    /// @param seqOfOrder Order sequence.
    /// @param isOffer True for offer book.
    /// @return order Removed order.
    function withdrawOrder(
        uint classOfShare,
        uint seqOfOrder,
        bool isOffer
    ) external returns(GoldChain.Order memory order);

    //################
    //##  Read I/O ##
    //################

    // ==== Deals ====

    /// @notice Get order counter.
    /// @param classOfShare Share class id.
    /// @param isOffer True for offer book.
    /// @return Counter value.
    function counterOfOrders(
        uint classOfShare, bool isOffer
    ) external view returns (uint32);

    /// @notice Get head order id.
    /// @param classOfShare Share class id.
    /// @param isOffer True for offer book.
    /// @return Order id.
    function headOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint32);

    /// @notice Get tail order id.
    /// @param classOfShare Share class id.
    /// @param isOffer True for offer book.
    /// @return Order id.
    function tailOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint32);

    /// @notice Get order list length.
    /// @param classOfShare Share class id.
    /// @param isOffer True for offer book.
    /// @return Length.
    function lengthOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint);

    /// @notice Get order sequence list.
    /// @param classOfShare Share class id.
    /// @param isOffer True for offer book.
    /// @return Order ids.
    function getSeqList(
        uint classOfShare, bool isOffer
    ) external view returns (uint[] memory);

    // ==== Order ====

    /// @notice Check whether an order exists.
    /// @param classOfShare Share class id.
    /// @param seqOfOrder Order sequence.
    /// @param isOffer True for offer book.
    /// @return True if exists.
    function isOrder(
        uint classOfShare, uint seqOfOrder, bool isOffer
    ) external view returns (bool);
    
    /// @notice Get order by sequence.
    /// @param classOfShare Share class id.
    /// @param seqOfOrder Order sequence.
    /// @param isOffer True for offer book.
    /// @return Order record.
    function getOrder(
        uint classOfShare, uint seqOfOrder, bool isOffer
    ) external view returns (GoldChain.Order memory);

    /// @notice Get all orders in a book.
    /// @param classOfShare Share class id.
    /// @param isOffer True for offer book.
    /// @return Order list.
    function getOrders(
        uint classOfShare, bool isOffer
    ) external view returns (GoldChain.Order[] memory);

    // ==== Class ====

    /// @notice Check whether a class exists in LOO.
    /// @param classOfShare Share class id.
    /// @return True if listed.
    function isClass(uint classOfShare) external view returns(bool);

    /// @notice Get list of listed classes.
    /// @return Class ids.
    function getClassesList() external view returns(uint[] memory);
}
