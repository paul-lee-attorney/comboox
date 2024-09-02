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

import "../../../lib/OrdersRepo_2.sol";
import "../../../lib/GoldChain_2.sol";
import "../../../lib/InvestorsRepo.sol";
import "../../../lib/EnumerableSet.sol";

interface IListOfOrders_2 {

    //################
    //##   Events   ##
    //################

    event RegInvestor(uint indexed investor, uint indexed groupRep, bytes32 indexed idHash);

    event ApproveInvestor(uint indexed investor, uint indexed verifier);

    event RevokeInvestor(uint indexed investor, uint indexed verifier);

    event OrderPlaced(bytes32 indexed order, bool indexed isOffer);

    event OrderWithdrawn(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer);

    event DealClosed(bytes32 indexed deal, uint indexed consideration);

    event OrderExpired(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer);

    //#################
    //##  Write I/O  ##
    //#################

    function regInvestor(
        uint acct,
        uint groupRep,
        bytes32 idHash
    ) external;

    function approveInvestor(
        uint userNo,
        uint verifier
    ) external;

    function revokeInvestor(
        uint userNo,
        uint verifier
    ) external;

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
    ) external returns(
        OrdersRepo_2.Deal[] memory deals, 
        GoldChain_2.Order[] memory expired,
        OrdersRepo_2.Deal memory offer
    );

    function placeBuyOrder(
        uint classOfShare,
        uint caller,
        uint groupRep,
        uint paid,
        uint price,
        uint execHours,
        uint centPriceInWei,
        uint msgValue
    ) external returns (
        OrdersRepo_2.Deal[] memory deals, 
        GoldChain_2.Order[] memory expired,
        OrdersRepo_2.Deal memory bid
    );

    function withdrawOrder(
        uint classOfShare,
        uint seqOfOrder,
        bool isOffer
    ) external returns(GoldChain_2.Order memory order);

    //################
    //##  Read I/O ##
    //################

    // ==== Investor ====

    function isInvestor(
        uint userNo
    ) external view returns(bool);

    function getInvestor(
        uint userNo
    ) external view returns(InvestorsRepo.Investor memory);

    function getQtyOfInvestors() 
        external view returns(uint);

    function investorList() 
        external view returns(uint[] memory);

    function investorInfoList() 
        external view returns(InvestorsRepo.Investor[] memory);

    // ==== Deals ====

    function counterOfOrders(
        uint classOfShare, bool isOffer
    ) external view returns (uint32);

    function headOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint32);

    function tailOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint32);

    function lengthOfList(
        uint classOfShare, bool isOffer
    ) external view returns (uint);

    function getSeqList(
        uint classOfShare, bool isOffer
    ) external view returns (uint[] memory);

    // ==== Order ====

    function isOrder(
        uint classOfShare, uint seqOfOrder, bool isOffer
    ) external view returns (bool);
    
    function getOrder(
        uint classOfShare, uint seqOfOrder, bool isOffer
    ) external view returns (GoldChain_2.Order memory);

    function getOrders(
        uint classOfShare, bool isOffer
    ) external view returns (GoldChain_2.Order[] memory);

    // ==== Class ====
    function isClass(uint classOfShare) external view returns(bool);

    function getClassesList() external view returns(uint[] memory);
}
