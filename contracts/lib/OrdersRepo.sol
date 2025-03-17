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

import "./GoldChain.sol";

library OrdersRepo {
    using GoldChain for GoldChain.Chain;

    struct Brief {
        uint16 classOfShare;
        uint32 seqOfShare;
        uint40 buyer;
        uint40 seller; 
        uint64 paid;
        uint32 price;
        uint16 votingWeight;
        uint16 distrWeight;
    }

    struct Deal {
        address from;
        uint40 buyer;
        uint40 groupRep;
        uint16 classOfShare;
        address to;
        uint40 seller; 
        uint32 seqOfShare;
        uint8 state;
        bool inEth;
        bool isOffer;
        uint64 paid;
        uint32 price;
        uint16 votingWeight;
        uint16 distrWeight;
        uint128 consideration;
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

    function parseBrief(bytes32 sn) public pure returns(
        Brief memory brief
    ) {
        uint _sn = uint(sn);

        brief.classOfShare = uint16(_sn >> 240);
        brief.seqOfShare = uint32(_sn >> 208);
        brief.buyer = uint40(_sn >> 168);
        brief.seller = uint40(_sn >> 128);
        brief.paid = uint64(_sn >> 64);
        brief.price = uint32(_sn >> 32);
        brief.votingWeight = uint16(_sn >> 16);
        brief.distrWeight = uint16(_sn);
    }

    function codifyBrief(
        Deal memory deal
    ) public pure returns(bytes32 sn) {
        bytes memory _sn = 
            abi.encodePacked(
                deal.classOfShare,
                deal.seqOfShare,
                deal.buyer,
                deal.seller,
                deal.paid,
                deal.price,
                deal.votingWeight,
                deal.distrWeight
            );

        assembly {
            sn := mload(add(_sn, 0x20))
        }                        
    }

    function parseDeal(
        bytes32 fromSn, bytes32 toSn, bytes32 qtySn
    ) public pure returns(
        Deal memory deal
    ) {
        uint _fromSn = uint(fromSn);

        deal.from = address(uint160(_fromSn >> 96));
        deal.buyer = uint40(_fromSn >> 56);
        deal.groupRep = uint40(_fromSn >> 16);
        deal.classOfShare = uint16(_fromSn);

        uint _toSn = uint(toSn);

        deal.to = address(uint160(_toSn >> 96));
        deal.seller = uint40(_toSn >> 56);
        deal.seqOfShare = uint32(_toSn >> 24);
        deal.state = uint8(_toSn >> 16);
        deal.inEth = uint8(_toSn >> 8) == 1;
        deal.isOffer = uint8(_toSn) == 1;

        uint _qtySn = uint(qtySn);

        deal.paid = uint64(_qtySn >> 192);
        deal.price = uint32(_qtySn >> 160);
        deal.votingWeight = uint16(_qtySn >> 144);
        deal.distrWeight = uint16(_qtySn >> 128);
        deal.consideration = uint128(_qtySn);
    }

    function codifyDeal(Deal memory deal) public pure returns(
        bytes32 fromSn, bytes32 toSn, bytes32 qtySn
    ) {
        bytes memory _fromSn = 
            abi.encodePacked(
                deal.from,
                deal.buyer,
                deal.groupRep,
                deal.classOfShare
            );

        assembly {
            fromSn := mload(add(_fromSn, 0x20))
        }

        bytes memory _toSn = 
            abi.encodePacked(
                deal.to,
                deal.seller,
                deal.seqOfShare,
                deal.state,
                deal.inEth,
                deal.isOffer
            );

        assembly {
            toSn := mload(add(_toSn, 0x20))
        }

        bytes memory _qtySn = 
            abi.encodePacked(
                deal.paid,
                deal.price,
                deal.votingWeight,
                deal.distrWeight,
                deal.consideration
            );

        assembly {
            qtySn := mload(add(_qtySn, 0x20))
        }
    }

    // ==== Order ====

    function dealToData(Deal memory deal) public view 
        returns (GoldChain.Data memory data) {
        return GoldChain.Data({
            classOfShare : deal.classOfShare,
            seqOfShare : deal.seqOfShare,
            groupRep: deal.groupRep,
            votingWeight : deal.votingWeight,
            distrWeight : deal.distrWeight,
            margin: deal.consideration,
            inEth : deal.inEth,                
            pubKey : deal.isOffer ? deal.to : deal.from,
            date: 0,
            issueDate : uint48(block.timestamp)            
        });
    }

    function placeSellOrder(
        Repo storage repo,
        Deal memory input,
        uint execHours,
        uint centPriceInWei
    ) public returns (
        Deal[] memory deals,
        GoldChain.Order[] memory expired,
        Deal memory offer
    ) {

        offer = input;

        _matchOrders(repo, offer, centPriceInWei);

        if (offer.paid > 0 && offer.price > 0) {

            GoldChain.Data memory data = dealToData(offer);

            repo.offers.createNode(
                offer.seller,
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

    function getDealValue(
        uint paid, uint price, uint centPrice
    ) public pure returns (uint128) {
        return uint128(paid * price * centPrice / 10 ** 6);
    }

    function placeBuyOrder(
        Repo storage repo,
        Deal memory input,
        uint execHours,
        uint centPriceInWei
    ) public returns (
        Deal[] memory deals,
        GoldChain.Order[] memory expired,
        Deal memory bid
    ) {

        bid = input;

        if (bid.inEth) {
            require(getDealValue(bid.paid, bid.price, centPriceInWei) <=
                bid.consideration, "OR.placeBuyOrder: insufficient msgValue");
        }

        _matchOrders(repo, bid, centPriceInWei);

        if (bid.paid > 0 && bid.price > 0) {

            GoldChain.Data memory data = dealToData(bid);

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

    function _matchOrders(
        Repo storage repo, Deal memory order, uint centPriceInWei
    ) private {
        // bool isOffer = order.buyer == 0;

        GoldChain.Chain storage chain = 
            order.isOffer ? repo.bids : repo.offers;

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
                    (order.isOffer ? n.node.price >= order.price : n.node.price <= order.price)) {

                Deal memory deal;

                deal.price = order.isOffer 
                    ?   order.price == 0 ? n.node.price : order.price
                    :   n.node.price; 

                if (order.paid >= n.node.paid) {
                    deal.paid = n.node.paid;
                    n.data.date = 1;
                } else {
                    deal.paid = order.paid;
                }

                deal.inEth = order.inEth;

                if (deal.inEth) {
                    deal.consideration = 
                        getDealValue(deal.paid, deal.price, centPriceInWei);
                } else {
                    deal.consideration = deal.paid * deal.price;
                }

                if (order.isOffer) {

                    if (deal.consideration >= n.data.margin) {
                        deal.consideration = n.data.margin;
                        deal.paid = deal.inEth
                            ? uint64(uint(deal.consideration) * 10 ** 6 / centPriceInWei / deal.price)
                            : uint64(uint(deal.consideration) / deal.price);
                        
                        n.data.margin = 0;
                        n.node.paid = 0;
                        n.data.date = 1;
                    } else {
                        n.data.margin -= deal.consideration;
                        n.node.paid -= deal.paid;
                    }

                    deal.from = n.data.pubKey;
                    deal.to = order.to;
                    deal.seller = order.seller;

                    deal.classOfShare = order.classOfShare;
                    deal.seqOfShare = order.seqOfShare;
                    deal.buyer = n.node.issuer;
                    deal.groupRep = n.data.groupRep;
                    deal.votingWeight = order.votingWeight;
                    deal.distrWeight = order.distrWeight;

                } else {
                    
                    if (deal.consideration >= order.consideration) {
                        deal.consideration = order.consideration;
                        deal.paid = deal.inEth
                            ? uint64(uint(deal.consideration) * 10 ** 6 / centPriceInWei / deal.price)
                            : uint64(uint(deal.consideration) / deal.price);

                        order.paid = deal.paid;

                        if (n.data.date == 1) {
                            n.data.date = 0;
                        }
                    }

                    n.node.paid -= deal.paid;

                    order.consideration -= deal.consideration;

                    deal.from = order.from;
                    deal.to = n.data.pubKey;
                    deal.seller = n.node.issuer;

                    deal.classOfShare = n.data.classOfShare;
                    deal.seqOfShare = n.data.seqOfShare;
                    deal.buyer = order.buyer;
                    deal.groupRep = order.groupRep;
                    deal.votingWeight = n.data.votingWeight;
                    deal.distrWeight = n.data.distrWeight;

                }

                order.paid -= deal.paid;

                if (n.data.date == 1) {
                    GoldChain.Order memory delistedOrder = chain.offChain(seqOfNode);
                    seqOfNode = delistedOrder.node.next;
                    if (order.isOffer) {
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