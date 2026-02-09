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

import "./GoldChain.sol";

/// @title UsdOrdersRepo
/// @notice Order book utilities for USD-settled offers and bids.
library UsdOrdersRepo {
    using GoldChain for GoldChain.Chain;

    /// @notice Compact brief for on-chain encoding.
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

    /// @notice Order/deal model used by matching engine.
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

    /// @notice Two-sided order book storage.
    struct Repo {
        GoldChain.Chain offers;
        GoldChain.Chain bids;
    }

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Codify & Parse ====

    /// @notice Parse brief from packed bytes32.
    /// @param sn Packed brief.
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

    /// @notice Pack deal fields into brief.
    /// @param deal Deal data.
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

    /// @notice Parse a deal from packed segments.
    /// @param fromSn Packed from-part.
    /// @param toSn Packed to-part.
    /// @param qtySn Packed qty-part.
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

    /// @notice Pack a deal into 3 words.
    /// @param deal Deal data.
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

    /// @notice Convert deal to GoldChain order data.
    /// @param deal Deal data.
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

    /// @notice Match and/or place a sell offer.
    /// @param repo Storage repo.
    /// @param input Offer data.
    /// @param execHours Expiration in hours.
    function placeSellOrder(
        Repo storage repo,
        Deal memory input,
        uint execHours
    ) public returns (
        Deal[] memory deals,
        uint lenOfDeals,
        GoldChain.Order[] memory expired,
        uint lenOfExpired,
        Deal memory offer
    ) {

        offer = input;

        GoldChain.Chain storage bids = repo.bids;
        uint len = bids.length();
        
        deals = new Deal[](len);
        expired = new GoldChain.Order[](len);

        if (offer.price > 0) {
            (lenOfDeals, lenOfExpired) = _matchOfferToBid(bids, offer, deals, expired);
        } else {
            (lenOfDeals, lenOfExpired) = _matchMarketToBid(bids, offer, deals, expired);
        }

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
    }

    /// @notice Match and/or place a buy bid.
    /// @param repo Storage repo.
    /// @param input Bid data.
    /// @param execHours Expiration in hours.
    function placeBuyOrder(
        Repo storage repo,
        Deal memory input,
        uint execHours
    ) public returns (
        Deal[] memory deals,
        uint lenOfDeals,
        GoldChain.Order[] memory expired,
        uint lenOfExpired,
        Deal memory bid
    ) {

        bid = input;

        GoldChain.Chain storage offers = repo.offers;
        uint len = offers.length();
    
        deals = new Deal[](len);
        expired = new GoldChain.Order[](len);

        if (bid.price > 0) {
            (lenOfDeals, lenOfExpired) = _matchBidToOffer(offers, bid, deals, expired);
        } else {
            (lenOfDeals, lenOfExpired) = _matchMarketToOffer(offers, bid, deals, expired);
        }

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

    }

    /// @notice Withdraw an order by sequence.
    /// @param repo Storage repo.
    /// @param seqOfOrder Order sequence number.
    /// @param isOffer True for offer book, false for bid book.
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

    function _matchOfferToBid(
        GoldChain.Chain storage bids, Deal memory offer, Deal[] memory deals, GoldChain.Order[] memory expired
    ) private returns(uint lenOfDeals, uint lenOfExpired){

        uint32 seqOfNode = bids.head();

        while(seqOfNode > 0 && offer.paid > 0) {

            (seqOfNode, lenOfExpired) = _checkExpired(bids, seqOfNode, expired, lenOfExpired);
            if (seqOfNode == 0) break;

            GoldChain.Order storage n = bids.orders[seqOfNode];
            
            if (n.node.price >= offer.price) {

                Deal memory deal = _createDeal(offer, offer.price, n.node.paid);

                n.data.margin -= deal.consideration;
                n.node.paid -= deal.paid;
                offer.paid -= deal.paid;

                _fillInOfferDeal(deal, offer, n);

                if (deal.state == 1) {
                    GoldChain.Order memory delistedOrder = bids.offChain(seqOfNode);
                    seqOfNode = delistedOrder.node.next;
                    expired[lenOfExpired] = delistedOrder;
                    lenOfExpired++;
                }

                deals[lenOfDeals] = deal;
                lenOfDeals++;

            } else break;
        }
    }

    function _matchBidToOffer(
        GoldChain.Chain storage offers, Deal memory bid, Deal[] memory deals, GoldChain.Order[] memory expired
    ) private returns(uint lenOfDeals, uint lenOfExpired){

        uint32 seqOfNode = offers.head();

        while(seqOfNode > 0 && bid.paid > 0) {
            
            (seqOfNode, lenOfExpired) = _checkExpired(offers, seqOfNode, expired, lenOfExpired);
            if (seqOfNode == 0) break;

            GoldChain.Order storage n = offers.orders[seqOfNode];
            
            if (n.node.price <= bid.price) {

                Deal memory deal = 
                    _createDeal(bid, n.node.price, n.node.paid);

                n.node.paid -= deal.paid;
                bid.consideration -= deal.consideration;
                bid.paid -= deal.paid;

                _fillInBidDeal(deal, bid, n);

                if (deal.state == 1) {
                    GoldChain.Order memory delistedOrder = offers.offChain(seqOfNode);
                    seqOfNode = delistedOrder.node.next;
                }

                deals[lenOfDeals] = deal;
                lenOfDeals++;

            } else break;
        }
    }

    function _matchMarketToBid(
        GoldChain.Chain storage bids, Deal memory offer, Deal[] memory deals, GoldChain.Order[] memory expired
    ) private returns(uint lenOfDeals, uint lenOfExpired){

        uint32 seqOfNode = bids.head();

        while(seqOfNode > 0 && offer.paid > 0) {

            (seqOfNode, lenOfExpired) = _checkExpired(bids, seqOfNode, expired, lenOfExpired);
            if (seqOfNode == 0) break;

            GoldChain.Order storage n = bids.orders[seqOfNode];

            Deal memory deal = _createDeal(offer, n.node.price, n.node.paid);

            n.data.margin -= deal.consideration;
            n.node.paid -= deal.paid;
            offer.paid -= deal.paid;

            _fillInOfferDeal(deal, offer, n);

            if (deal.state == 1) {
                GoldChain.Order memory delistedOrder = bids.offChain(seqOfNode);
                seqOfNode = delistedOrder.node.next;
            }

            deals[lenOfDeals] = deal;
            lenOfDeals++;
        }
    }

    function _matchMarketToOffer(
        GoldChain.Chain storage offers, Deal memory bid, Deal[] memory deals, GoldChain.Order[] memory expired
    ) private returns(uint lenOfDeals, uint lenOfExpired){

        uint32 seqOfNode = offers.head();

        while(seqOfNode > 0 && bid.paid > 0) {

            (seqOfNode, lenOfExpired) = _checkExpired(offers, seqOfNode, expired, lenOfExpired);
            if (seqOfNode == 0) break;

            GoldChain.Order storage n = offers.orders[seqOfNode];
            
            Deal memory deal = _createDeal(bid, n.node.price, n.node.paid);

            if (deal.consideration >= bid.consideration) {
                deal.consideration = bid.consideration;
                deal.paid = uint64(uint(deal.consideration) / deal.price);

                bid.paid = deal.paid;

                if (deal.state == 1) {
                    deal.state = 0;
                }
            }

            n.node.paid -= deal.paid;
            bid.consideration -= deal.consideration;
            bid.paid -= deal.paid;

            _fillInBidDeal(deal, bid, n);

            if (deal.state == 1) {
                GoldChain.Order memory delistedOrder = offers.offChain(seqOfNode);
                seqOfNode = delistedOrder.node.next;
            }

            deals[lenOfDeals] = deal;
            lenOfDeals++;
        }
    }

    function _checkExpired(
        GoldChain.Chain storage chain, uint32 seqOfNode, GoldChain.Order[] memory expired, uint lenOfExpired
    ) private returns(uint32, uint) {
    
        while (seqOfNode > 0) {
            if (chain.orders[seqOfNode].node.expireDate <= block.timestamp) {
                GoldChain.Order memory removedNode = chain.offChain(seqOfNode); 
                expired[lenOfExpired] = (removedNode);
                lenOfExpired++;
                seqOfNode = removedNode.node.next;
            } else break;
        }
    
        return (seqOfNode, lenOfExpired);
    }

    function _createDeal(
        Deal memory order, uint offerPrice, uint nodePaid
    ) private pure returns (Deal memory deal) {
        deal.price = uint32(offerPrice);

        if (order.paid >= nodePaid) {
            deal.paid = uint64(nodePaid);
            deal.state = 1;
        } else {
            deal.paid = order.paid;
        }

        deal.consideration = deal.paid * deal.price;
    }

    function _fillInBidDeal(
        Deal memory deal, Deal memory bid, GoldChain.Order memory n
    ) private pure {
        deal.from = bid.from;
        deal.to = n.data.pubKey;
        deal.seller = n.node.issuer;

        deal.classOfShare = n.data.classOfShare;
        deal.seqOfShare = n.data.seqOfShare;
        deal.buyer = bid.buyer;
        deal.groupRep = bid.groupRep;
        deal.votingWeight = n.data.votingWeight;
        deal.distrWeight = n.data.distrWeight;
    }

    function _fillInOfferDeal(
        Deal memory deal, Deal memory offer, GoldChain.Order memory n
    ) private pure {
        deal.from = n.data.pubKey;
        deal.to = offer.to;
        deal.seller = offer.seller;

        deal.classOfShare = offer.classOfShare;
        deal.seqOfShare = offer.seqOfShare;
        deal.buyer = n.node.issuer;
        deal.groupRep = n.data.groupRep;
        deal.votingWeight = offer.votingWeight;
        deal.distrWeight = offer.distrWeight;
    }

    //################
    //##  Read I/O  ##
    //################

    /// @notice Get order counter.
    /// @param repo Storage repo.
    /// @param isOffer True for offer book, false for bid book.
    function counterOfOrders(
        Repo storage repo, bool isOffer
    ) public view returns (uint32) {
        return isOffer
            ? repo.offers.counter()
            : repo.bids.counter();
    }

    /// @notice Get head node id.
    /// @param repo Storage repo.
    /// @param isOffer True for offer book, false for bid book.
    function headOfList(
        Repo storage repo, bool isOffer
    ) public view returns (uint32) {
        return isOffer
            ? repo.offers.head()
            : repo.bids.head();
    }

    /// @notice Get tail node id.
    /// @param repo Storage repo.
    /// @param isOffer True for offer book, false for bid book.
    function tailOfList(
        Repo storage repo, bool isOffer
    ) public view returns (uint32) {
        return isOffer
            ? repo.offers.tail()
            : repo.bids.tail();
    }

    /// @notice Get list length.
    /// @param repo Storage repo.
    /// @param isOffer True for offer book, false for bid book.
    function lengthOfList(
        Repo storage repo, bool isOffer
    ) public view returns (uint32) {
        return isOffer
            ? repo.offers.length()
            : repo.bids.length();
    }

    // ==== Order ====

    /// @notice Check whether an order exists.
    /// @param repo Storage repo.
    /// @param isOffer True for offer book, false for bid book.
    /// @param seqOfOrder Order sequence number.
    function isOrder(
        Repo storage repo,
        bool isOffer,
        uint seqOfOrder
    ) public view returns (bool) {
        return isOffer
            ? repo.offers.isNode(seqOfOrder)
            : repo.bids.isNode(seqOfOrder);
    }

    /// @notice Get order by sequence.
    /// @param repo Storage repo.
    /// @param isOffer True for offer book, false for bid book.
    /// @param seqOfOrder Order sequence number.
    function getOrder(
        Repo storage repo,
        bool isOffer,
        uint seqOfOrder
    ) public view returns (GoldChain.Order memory order) {
        order = isOffer
            ? repo.offers.getOrder(seqOfOrder)
            : repo.bids.getOrder(seqOfOrder);
    }

    /// @notice Get order sequence list.
    /// @param repo Storage repo.
    /// @param isOffer True for offer book, false for bid book.
    function getSeqList(
        Repo storage repo,
        bool isOffer
    ) public view returns (uint[] memory orders) {
        orders = isOffer
            ? repo.offers.getSeqList()
            : repo.bids.getSeqList();
    }

    /// @notice Get full order chain.
    /// @param repo Storage repo.
    /// @param isOffer True for offer book, false for bid book.
    function getOrders(
        Repo storage repo,
        bool isOffer
    ) public view returns (GoldChain.Order[] memory orders) {
        orders = isOffer
            ? repo.offers.getChain()
            : repo.bids.getChain();
    }
}