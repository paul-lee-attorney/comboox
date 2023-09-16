// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../comps/books/rom/IRegisterOfMembers.sol";
import "../comps/books/roc/IShareholdersAgreement.sol";

import "./GoldChain.sol";
import "./RulesParser.sol";

library OrdersRepo {
    using GoldChain for GoldChain.Chain;
    using RulesParser for bytes32;

    enum StateOfInvestor {
        Pending,
        Approved,
        Revoked
    }

    struct Investor {
        uint40 userNo;
        uint40 groupRep;
        uint48 regDate;
        uint40 verifier;
        uint48 approveDate;
        uint32 data;
        uint8 state;
        bytes32 idHash;
    }

    struct Deal {
        uint32 seqOfDeal;
        uint32 seqOfShare;
        uint40 buyer;
        uint40 groupRep;
        uint64 paid;
        uint32 price;
        uint8 state;
    }

    struct Orders {
        GoldChain.Chain putOrders;
        GoldChain.Chain callOrders;
        mapping(uint256 => Deal) deals;
    }

    struct Repo {
        mapping(uint256 => Orders) ordersOfClass;
        mapping(uint256 => Investor) investors;
        uint[] invList;
    }

    //#################
    //##  Write I/O  ##
    //#################

    function regInvestor(
        Repo storage repo,
        uint userNo,
        uint groupRep,
        bytes32 idHash
    ) public {
        require(idHash != bytes32(0), 
            "OR.regInvestor: zero idHash");
        
        uint40 user = uint40(userNo);

        require(user > 0,
            "OR.regInvestor: zero userNo");

        Investor memory investor = Investor({
            userNo: user,
            groupRep: uint40(groupRep),
            regDate: uint48(block.timestamp),
            verifier: 0,
            approveDate: 0,
            data: 0,
            state: uint8(StateOfInvestor.Pending),
            idHash: idHash
        });

        repo.investors[user] = investor;

        if (!isInvestor(repo, userNo))
            repo.invList.push(user);
    }

    function approveInvestor(
        Repo storage repo,
        uint userNo,
        uint verifier
    ) public {        
        uint40 user = uint40(userNo);
        uint40 authority = uint40(verifier);

        Investor storage investor = repo.investors[user];

        require(investor.regDate > 0,
            "OR,approveInvestor: investor not registered");

        require(investor.state == 0,
            "OR,approveInvestor: wrong state");

        investor.verifier = authority;
        investor.approveDate = uint48(block.timestamp);
        investor.state = uint8(StateOfInvestor.Approved);
    }

    function placePutOrder(
        Repo storage repo,
        uint offeror,
        uint classOfShare,
        uint seqOfShare,
        uint execHours,
        uint paid,
        uint price
    ) public returns (GoldChain.Order memory order) {
        // require (_rom.isMember(offeror), 'OR.placePut: not member');

        GoldChain.Chain storage chain = 
            repo.ordersOfClass[classOfShare].putOrders;

        uint32 seqOfOrder = chain.createOrder(
            seqOfShare,
            classOfShare,
            offeror,
            execHours,
            paid,
            price
        );

        order = chain.upList(true, seqOfOrder);
    }

    function placeCallOrder(
        Repo storage repo,
        uint offeror,
        uint classOfShare,
        uint paid,
        uint price
    ) public returns (Deal[] memory deals, GoldChain.Order memory call) {

        require(uint16(classOfShare) > 0, "OR.placeCall: zero class");
        require(isInvestor(repo, offeror),"OR.placeCall: investor not registered");

        GoldChain.Chain storage chain = 
            repo.ordersOfClass[uint16(classOfShare)].callOrders;

        uint32 seqOfCall = chain.createOrder(
            0,
            classOfShare,
            offeror,
            0,
            paid,
            price
        );

        uint numOfDeals = 
            _checkPutList(repo, uint16(classOfShare), seqOfCall);
        
        deals = getDealsList(repo, classOfShare, getCounterOfDeals(repo, classOfShare), numOfDeals);
        call = chain.getOrder(seqOfCall);
    }

    function _checkPutList(
        Repo storage repo,
        uint classOfShare,
        uint seqOfCall
    ) private returns (uint numOfDeals) {

        GoldChain.Order storage call = 
            repo.ordersOfClass[classOfShare].callOrders.orders[seqOfCall];

        Investor memory investor = getInvestor(repo, call.offeror);

        require (investor.state == uint8(StateOfInvestor.Approved),
            "OR.createDeal: wrong stateOfInvestor");

        GoldChain.Chain storage chain = 
            repo.ordersOfClass[classOfShare].putOrders;

        uint32 seqOfPut = chain.getHeadSeqOfList();

        while(seqOfPut > 0 && call.paid > 0) {

            GoldChain.Order storage put 
                = chain.orders[seqOfPut];

            if (put.expireDate <= block.timestamp) {
                put.state = uint8(GoldChain.StateOfOrder.Terminated);
                seqOfPut = chain.offList(seqOfPut);
                continue;
            }
            
            if (put.price <= call.price) {

                bool paidAsPut = put.paid <= call.paid;

                Deal memory deal = Deal({
                    seqOfDeal: _increaseCounterOfDeals(repo, classOfShare),
                    seqOfShare: put.seqOfShare,
                    buyer: investor.userNo,
                    groupRep: investor.groupRep,
                    paid: paidAsPut ? put.paid : call.paid,
                    price: put.price,
                    state: 0
                });

                repo.ordersOfClass[classOfShare].deals[deal.seqOfDeal] = deal;

                if (paidAsPut) {
                    put.seqOfDeal = deal.seqOfDeal;
                    put.state = uint8(GoldChain.StateOfOrder.Closed);

                    chain.offList(seqOfPut);
                } else {
                    put.paid -= deal.paid;

                    uint32 splitPut = chain.createOrder(
                        put.seqOfShare,
                        put.classOfShare,
                        put.offeror,
                        0,
                        deal.paid,
                        put.price
                    );
                    chain.orders[splitPut].seqOfDeal = deal.seqOfDeal;
                    chain.orders[splitPut].state = uint8(GoldChain.StateOfOrder.Closed);
                }

                call.paid -= deal.paid;

                numOfDeals++;

                seqOfPut = put.next;

            } else break;
        }
    }

    function _increaseCounterOfDeals(
        Repo storage repo,
        uint classOfShare
    ) private returns (uint32) {
        repo.ordersOfClass[classOfShare].deals[0].seqOfDeal++;
        return repo.ordersOfClass[classOfShare].deals[0].seqOfDeal;
    }

    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        Repo storage repo,
        uint userNo
    ) public view returns(bool) {
        return repo.investors[userNo].regDate > 0;
    }

    function getInvestor(
        Repo storage repo,
        uint userNo
    ) public view returns(Investor memory) {
        return repo.investors[userNo];
    }

    function getQtyOfInvestors(
        Repo storage repo
    ) public view returns(uint) {
        return repo.invList.length;
    }

    function getInvList(
        Repo storage repo
    ) public view returns(uint[] memory) {
        return repo.invList;
    }

    function getInvestorsList(
        Repo storage repo
    ) public view returns(Investor[] memory) {
        uint[] memory invList = repo.invList;
        uint len = invList.length;
        Investor[] memory list = new Investor[](len);

        while (len > 0) {
            list[len - 1] = repo.investors[invList[len - 1]];
            len--;
        }

        return list;
    }

    // ==== Deals ====

    function getCounterOfDeals(
        Repo storage repo,
        uint classOfShare  
    ) public view returns(uint32) {   
        return repo.ordersOfClass[classOfShare].deals[0].seqOfDeal;
    }

    function getDeal(
        Repo storage repo,
        uint classOfShare,
        uint seqOfDeal
    ) public view returns(Deal memory ) {   
        return repo.ordersOfClass[classOfShare].deals[seqOfDeal];
    }

    function getDealsList(
        Repo storage repo,
        uint classOfShare,
        uint lastDealSeq,
        uint len
    ) public view returns(Deal[] memory ) {
        Deal[] memory list = new Deal[](len);

        while (len > 0) {
            list[len - 1] = getDeal(repo, classOfShare, lastDealSeq + 1 - len);
            len--;
        }

        return list;
    }

}