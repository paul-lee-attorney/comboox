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

import "./GoldChain.sol";

library OrdersRepo {
    using GoldChain for GoldChain.Chain;
    using GoldChain for GoldChain.Node;
    using GoldChain for GoldChain.Data;

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
        GoldChain.Chain offers;
        GoldChain.Chain bids;
        // ---- tempArry ----
        GoldChain.Order[] expired;
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
        GoldChain.Order[] memory expired,
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

            GoldChain.Data memory data = GoldChain.Data({
                classOfShare: offer.classOfShare,
                seqOfShare: offer.seqOfShare,
                groupRep: 0,
                votingWeight: offer.votingWeight,
                distrWeight: offer.distrWeight,
                margin: 0,
                state: 0
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
        GoldChain.Order[] memory expired,
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

        require(consideration >= getDealValue(bid.paid, bid.price, centPriceInWei),
            "OR.placeBuyOrder: insufficient msgValue");

        _matchOrders(repo, bid, centPriceInWei);

        if (bid.paid > 0 && bid.price > 0) {

            GoldChain.Data memory data = GoldChain.Data({
                classOfShare: bid.classOfShare,
                seqOfShare: 0,
                groupRep: bid.groupRep,
                votingWeight: 0,
                distrWeight: 0,
                margin: uint128(bid.consideration),
                state: 0
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
    ) public returns (GoldChain.Order memory removed)
    {
        removed = isOffer 
            ? repo.offers.offChain(seqOfOrder)
            : repo.bids.offChain(seqOfOrder);
    }

    function getDealValue(
        uint paid, uint price, uint centPrice
    ) public pure returns (uint64) {
        return uint64(paid * price * centPrice / 10 ** 6);
    } 

    function _matchOrders(
        Repo storage repo,
        Deal memory order,
        uint centPriceInWei
    ) private {

        bool isOffer = order.buyer == 0;

        GoldChain.Chain storage chain = 
            isOffer ? repo.bids : repo.offers;

        uint32 seqOfNode = chain.head();

        while(seqOfNode > 0 && order.paid > 0) {

            GoldChain.Order storage n = chain.orders[seqOfNode];

            if (n.node.expireDate <= block.timestamp) {
                GoldChain.Order memory removedNode = chain.offChain(seqOfNode); 
                repo.expired.push(removedNode);
                seqOfNode = removedNode.node.next;
                continue;
            }
            
            if (order.price == 0 || 
                    (isOffer ? n.node.price >= order.price : n.node.price <= order.price)) {

                Deal memory deal;

                deal.price = isOffer 
                    ?   order.price == 0 ? n.node.price : order.price
                    :   n.node.price; 

                if (order.paid >= n.node.paid) {
                    deal.paid = n.node.paid;
                    n.data.state = 1;
                } else {
                    deal.paid = order.paid;
                }

                deal.consideration = getDealValue(deal.paid, deal.price, centPriceInWei);

                if (isOffer) {

                    if (deal.consideration >= n.data.margin) {
                        deal.consideration = n.data.margin;
                        deal.paid = uint64(uint(deal.consideration) * 10 ** 6 / centPriceInWei / deal.price);
                        
                        n.data.margin = 0;
                        n.node.paid = 0;
                        n.data.state = 1;
                    } else {
                        n.data.margin -= uint128(deal.consideration);
                        n.node.paid -= deal.paid;
                    }

                    deal.classOfShare = order.classOfShare;
                    deal.seqOfShare = order.seqOfShare;
                    deal.buyer = n.node.issuer;
                    deal.groupRep = n.data.groupRep;
                    deal.votingWeight = order.votingWeight;
                    deal.distrWeight = order.distrWeight;

                } else {
                    
                    if (deal.consideration >= order.consideration) {
                        deal.consideration = order.consideration;
                        deal.paid = uint64(uint(deal.consideration) * 10 ** 6 / centPriceInWei / deal.price);

                        order.paid = deal.paid;

                        if (n.data.state == 1) {
                            n.data.state = 0;
                        }
                    }

                    n.node.paid -= deal.paid;

                    order.consideration -= deal.consideration;

                    deal.classOfShare = n.data.classOfShare;
                    deal.seqOfShare = n.data.seqOfShare;
                    deal.buyer = order.buyer;
                    deal.groupRep = order.groupRep;
                    deal.votingWeight = n.data.votingWeight;
                    deal.distrWeight = n.data.distrWeight;

                }

                order.paid -= deal.paid;

                if (n.data.state == 1) {
                    GoldChain.Order memory delistedOrder = chain.offChain(seqOfNode);
                    seqOfNode = delistedOrder.node.next;
                    if (isOffer) {
                        repo.expired.push(delistedOrder);
                    }
                }

                repo.deals.push(deal);

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
    ) public view returns (GoldChain.Order memory order) {
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
    ) public view returns (GoldChain.Order[] memory orders) {
        orders = isOffer
            ? repo.offers.getChain()
            : repo.bids.getChain();
    }
}