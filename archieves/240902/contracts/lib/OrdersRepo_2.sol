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

import "./GoldChain_2.sol";

library OrdersRepo_2 {
    using GoldChain_2 for GoldChain_2.Chain;
    using GoldChain_2 for GoldChain_2.Node;
    using GoldChain_2 for GoldChain_2.Data;

    struct Deal {
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 buyer;
        uint40 groupRep; 
        uint64 paid; 
        uint32 price;
        uint16 votingWeight;
        uint16 distrWeight;
        uint consideration;
    }

    struct Repo {
        GoldChain_2.Chain offers;
        GoldChain_2.Chain bids;
        // ---- tempArry ----
        GoldChain_2.Order[] expired;
        Deal[] deals;
    }

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Codify & Parse ====

    function parseDeal(bytes32 sn) public pure returns(
        Deal memory deal
    ) {
        uint _sn = uint(sn);

        deal.classOfShare = uint16(_sn >> 240);
        deal.seqOfShare = uint32(_sn >> 208);
        deal.buyer = uint40(_sn >> 168);
        deal.groupRep = uint40(_sn >> 128);
        deal.paid = uint64(_sn >> 64);
        deal.price = uint32(_sn >> 32);
        deal.votingWeight = uint16(_sn >> 16);
        deal.distrWeight = uint16(_sn);
    }

    function codifyDeal(
        Deal memory deal
    ) public pure returns(bytes32 sn) {
        bytes memory _sn = 
            abi.encodePacked(
                deal.classOfShare,
                deal.seqOfShare,
                deal.buyer,
                deal.groupRep,
                deal.paid,
                deal.price,
                deal.votingWeight,
                deal.distrWeight
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }                        
    }

    // ==== Order ====

    function placeSellOrder(
        Repo storage repo,
        uint issuer,
        uint classOfShare,
        uint seqOfShare,
        uint votingWeight,
        uint distrWeight,
        uint paid,
        uint price,
        uint execHours,
        uint centPriceInWei
    ) public returns (
        Deal[] memory deals,
        GoldChain_2.Order[] memory expired,
        Deal memory offer
    ) {
        offer = Deal({
            classOfShare: uint16(classOfShare),
            seqOfShare: uint32(seqOfShare),
            buyer: 0,
            groupRep: 0,
            paid: uint64(paid),
            price: uint32(price),
            votingWeight: uint16(votingWeight),
            distrWeight: uint16(distrWeight),
            consideration: 0
        });

        _matchOrders(repo, offer, centPriceInWei);

        if (offer.paid > 0 && offer.price > 0) {

            GoldChain_2.Data memory data = GoldChain_2.Data({
                classOfShare: offer.classOfShare,
                seqOfShare: offer.seqOfShare,
                groupRep: 0,
                votingWeight: offer.votingWeight,
                distrWeight: offer.distrWeight,
                centPriceInWei: uint64(centPriceInWei),
                buyer: 0,
                seq: 0
            }); 

            repo.offers.createNode(
                issuer,
                offer.paid,
                offer.price,
                execHours, 
                true,
                data
            );
        }

        deals = repo.deals;
        delete repo.deals;

        expired = repo.expired;
        delete repo.expired;
    }

    function placeBuyOrder(
        Repo storage repo,
        uint classOfShare,
        uint buyer,
        uint groupRep,
        uint paid,
        uint price,
        uint execHours,
        uint centPriceInWei,
        uint consideration
    ) public returns (
        Deal[] memory deals,
        GoldChain_2.Order[] memory expired,
        Deal memory bid
    ) {

        bid = Deal({
            classOfShare: uint16(classOfShare),
            seqOfShare: 0,
            buyer: uint40(buyer),
            groupRep: uint40(groupRep), 
            paid: uint64(paid),
            price: uint32(price),
            votingWeight: 0,
            distrWeight: 0,
            consideration: consideration
        });

        require(consideration >= 
            bid.paid * bid.price / 10000 * centPriceInWei / 100,
            "OR.placeBuyOrder: insufficient msgValue");

        _matchOrders(repo, bid, centPriceInWei);

        if (bid.paid > 0 && bid.price > 0) {

            GoldChain_2.Data memory data = GoldChain_2.Data({
                classOfShare: bid.classOfShare,
                seqOfShare: 0,
                groupRep: bid.groupRep,
                votingWeight: 0,
                distrWeight: 0,
                centPriceInWei: uint64(centPriceInWei),
                buyer: bid.buyer,
                seq: 0
            }); 

            repo.bids.createNode(
                bid.buyer,
                bid.paid,
                bid.price,
                execHours, 
                false,
                data
            );
        }

        deals = repo.deals;
        delete repo.deals;

        expired = repo.expired;
        delete repo.expired;
    }

    function withdrawOrder(
        Repo storage repo,
        uint seqOfOrder,
        bool isOffer
    ) public returns (GoldChain_2.Order memory removed)
    {
        removed = isOffer 
            ? repo.offers.offChain(seqOfOrder)
            : repo.bids.offChain(seqOfOrder);
    }

    function _updateBid(
        GoldChain_2.Order storage n,
        uint centPriceInWei
    ) private {
        n.node.paid = uint64(uint(n.node.paid) * n.data.centPriceInWei / centPriceInWei);
        n.data.centPriceInWei = uint64(centPriceInWei);
    }

    function _matchOrders(
        Repo storage repo,
        Deal memory order,
        uint centPriceInWei
    ) private {

        bool isOffer = order.buyer == 0;

        GoldChain_2.Chain storage chain = 
            isOffer ? repo.bids : repo.offers;

        uint32 seqOfNode = chain.head();

        while(seqOfNode > 0 && order.paid > 0) {

            GoldChain_2.Order storage n = chain.orders[seqOfNode];

            if (n.node.expireDate <= block.timestamp) {
                GoldChain_2.Order memory removedNode = chain.offChain(seqOfNode); 
                repo.expired.push(removedNode);
                seqOfNode = removedNode.node.next;
                continue;
            }
            
            if (order.price == 0 || 
                    (isOffer ? n.node.price >= order.price : n.node.price <= order.price)) {

                if (isOffer) _updateBid(n, centPriceInWei);

                bool paidAsList = (order.price > 0 || isOffer) 
                    ? n.node.paid <= order.paid 
                    : order.consideration >= n.node.price * n.node.paid / 10000 * centPriceInWei / 100; 

                Deal memory deal = isOffer
                    ? Deal({
                        classOfShare: order.classOfShare,
                        seqOfShare: order.seqOfShare,
                        buyer: n.data.buyer,
                        groupRep: n.data.groupRep,
                        paid: paidAsList ? n.node.paid : order.paid,
                        price: order.price > 0 ? order.price : n.node.price,
                        votingWeight: order.votingWeight,
                        distrWeight: order.distrWeight,
                        consideration: 0
                    })
                    : Deal({
                        classOfShare: n.data.classOfShare,
                        seqOfShare: n.data.seqOfShare,
                        buyer: order.buyer,
                        groupRep: order.groupRep,
                        paid: paidAsList ? n.node.paid : order.paid,
                        price: n.node.price,
                        votingWeight: n.data.votingWeight,
                        distrWeight: n.data.distrWeight,
                        consideration: 0
                    });

                deal.consideration = deal.paid * deal.price / 10000 * centPriceInWei / 100;
                repo.deals.push(deal);

                if (paidAsList) {
                    seqOfNode = chain.offChain(seqOfNode).node.next;
                } else {
                    n.node.paid -= deal.paid;
                }

                order.paid -= deal.paid;

                if (!isOffer) {
                    if (order.paid > 0) {
                        order.consideration -= deal.consideration;
                    } else {
                        order.consideration = 0;
                    }
                }

            } else break;
        }
    }

    //################
    //##  Read I/O  ##
    //################

    function counterOfOrders(
        Repo storage repo, bool isOffer
    ) public view returns (uint32) {
        return isOffer
            ? repo.offers.counter()
            : repo.bids.counter();
    }

    function headOfList(
        Repo storage repo, bool isOffer
    ) public view returns (uint32) {
        return isOffer
            ? repo.offers.head()
            : repo.bids.head();
    }

    function tailOfList(
        Repo storage repo, bool isOffer
    ) public view returns (uint32) {
        return isOffer
            ? repo.offers.tail()
            : repo.bids.tail();
    }

    function lengthOfList(
        Repo storage repo, bool isOffer
    ) public view returns (uint32) {
        return isOffer
            ? repo.offers.length()
            : repo.bids.length();
    }

    // ==== Order ====

    function isOrder(
        Repo storage repo,
        bool isOffer,
        uint seqOfOrder
    ) public view returns (bool) {
        return isOffer
            ? repo.offers.isNode(seqOfOrder)
            : repo.bids.isNode(seqOfOrder);
    }

    function getOrder(
        Repo storage repo,
        bool isOffer,
        uint seqOfOrder
    ) public view returns (GoldChain_2.Order memory order) {
        order = isOffer
            ? repo.offers.getOrder(seqOfOrder)
            : repo.bids.getOrder(seqOfOrder);
    }

    function getSeqList(
        Repo storage repo,
        bool isOffer
    ) public view returns (uint[] memory orders) {
        orders = isOffer
            ? repo.offers.getSeqList()
            : repo.bids.getSeqList();
    }

    function getOrders(
        Repo storage repo,
        bool isOffer
    ) public view returns (GoldChain_2.Order[] memory orders) {
        orders = isOffer
            ? repo.offers.getChain()
            : repo.bids.getChain();
    }
}