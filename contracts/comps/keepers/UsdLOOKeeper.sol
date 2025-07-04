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

import "../common/access/RoyaltyCharge.sol";

import "./IUsdLOOKeeper.sol";

contract UsdLOOKeeper is IUsdLOOKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    
    //###############
    //##   Write   ##
    //###############

    function _cashier() private view returns(ICashier) {
        return ICashier(_gk.getBook(11));
    }

    function _looInUSD() private view returns(IUsdListOfOrders) {
        return IUsdListOfOrders(_gk.getBook(13));
    }

    // ==== Offers ====

    function placeInitialOffer(
        address msgSender, uint classOfShare, uint execHours, 
        uint paid, uint price, uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        IRegisterOfShares _ros = _gk.getROS();
        
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfIssuer),
            "LOOKUSD.placeIO: not entitled");

        require(lr.classOfShare == classOfShare,
            "LOOKUSD.placeIO: wrong class");
        
        require(uint32(price) >= lr.floorPrice,
            "LOOKUSD.placeIO: lower than floor");

        require(lr.ceilingPrice == 0 ||
            uint32(price) <= lr.ceilingPrice,
            "LOOKUSD.placeIO: higher than ceiling");

        require (_ros.getInfoOfClass(classOfShare).body.cleanPaid +
            paid <= uint64(lr.maxTotalPar) * 10000, "LOOKUSD.placeIO: paid overflow");

        _ros.increaseEquityOfClass(true, classOfShare, 0, 0, paid);

        UsdOrdersRepo.Deal memory input;
        
        input.classOfShare = uint16(classOfShare);
        input.votingWeight = lr.votingWeight;
        input.distrWeight = lr.distrWeight;
        input.paid = uint64(paid);
        input.price = uint32(price);
        input.seller = uint40(caller);
        input.isOffer = true;

        _placeSellOrder(input,execHours);
    }

    function _placeSellOrder(
        UsdOrdersRepo.Deal memory input, uint execHours
    ) private {

        (UsdOrdersRepo.Deal[] memory deals,
         uint lenOfDeals, 
         GoldChain.Order[] memory expired, 
         uint lenOfExpired,
         UsdOrdersRepo.Deal memory offer) = 
            _looInUSD().placeSellOrder(input, execHours);

        if (lenOfDeals > 0) _closeDeals(deals, lenOfDeals, true);
        if (lenOfExpired > 0) _restoreExpiredOrders(expired, lenOfExpired);
        if (offer.price == 0 && offer.paid > 0) {
            GoldChain.Order memory balance;
            balance.data.classOfShare = offer.classOfShare;
            balance.data.seqOfShare = offer.seqOfShare;
            balance.data.pubKey = offer.to;
            balance.node.paid = offer.paid;
            _restoreOrder(balance);
        }
    }

    function _eightToSix(uint amt) private pure returns(uint) {
        return amt / 100;
    }

    function _closeDeals(UsdOrdersRepo.Deal[] memory deals, uint len, bool isOffer) private {

        IRegisterOfShares _ros = _gk.getROS(); 
        IRegisterOfMembers _rom = _gk.getROM();

        while (len > 0) {

            UsdOrdersRepo.Deal memory deal = deals[len - 1];
            len--;

            if (deal.seqOfShare > 0) {

                if (!_ros.notLocked(deal.seqOfShare, block.timestamp)) {
                    continue;
                }

                if (isOffer) {
                    // CloseOfferAgainstBid
                    _cashier().releaseUsd(
                        deal.from, deal.to, 
                        _eightToSix(deal.consideration), 
                        bytes32(0x436c6f73654f66666572416761696e7374426964000000000000000000000000)
                    );

                } else {                    
                    // CloseBidAgainstOffer
                    _cashier().releaseUsd(
                        deal.from, deal.to, 
                        _eightToSix(deal.consideration), 
                        bytes32(0x436c6f7365426964416761696e73744f66666572000000000000000000000000)
                    );

                }

                _ros.increaseCleanPaid(deal.seqOfShare, deal.paid);
                _ros.transferShare(
                    deal.seqOfShare,
                    deal.paid,
                    deal.paid,
                    deal.buyer,
                    deal.price,
                    0
                );

            } else {

                if (isOffer) {
                    // remark: CloseInitOfferAgainstBid
                    _cashier().releaseUsd(
                        deal.from, 
                        _gk.getBook(11),
                        _eightToSix(deal.consideration),
                        bytes32(0x436c6f7365496e69744f66666572416761696e73744269640000000000000000)
                    );

                } else {
                    // remark: CloseBidAgainstInitOffer
                    _cashier().releaseUsd(
                        deal.from, 
                        _gk.getBook(11),
                        _eightToSix(deal.consideration),
                        bytes32(0x436c6f7365426964416761696e7374496e69744f666665720000000000000000)
                    );

                }

                SharesRepo.Share memory share;
                
                share.head = SharesRepo.Head({
                    class: deal.classOfShare,
                    seqOfShare: 0,
                    preSeq: 0,
                    issueDate: 0,
                    shareholder: deal.buyer,
                    priceOfPaid: deal.price,
                    priceOfPar: 0,
                    votingWeight: deal.votingWeight,
                    argu: 0
                });

                share.body = SharesRepo.Body({
                    payInDeadline: uint48(block.timestamp + 86400),
                    paid: deal.paid,
                    par: deal.paid,
                    cleanPaid: deal.paid,
                    distrWeight: deal.distrWeight
                });

                _ros.addShare(share);
            }

            if (deal.groupRep != deal.buyer && 
                deal.groupRep != _rom.groupRep(deal.buyer)) {
                    _rom.addMemberToGroup(deal.buyer, deal.groupRep);
            }
        }

    }

    function _restoreOrder(GoldChain.Order memory order) private {

        if (order.node.isOffer) {
            IRegisterOfShares _ros = _gk.getROS();
            if (order.data.seqOfShare > 0) {
                _ros.increaseCleanPaid(order.data.seqOfShare, order.node.paid);
            } else {
                _ros.increaseEquityOfClass(false, order.data.classOfShare, 0, 0, order.node.paid);
            }
        } else {
            // remark: RefundValueOfBidOrder
            _cashier().releaseUsd(
                order.data.pubKey,
                order.data.pubKey, 
                _eightToSix(order.data.margin),
                bytes32(0x526566756e6456616c75654f664269644f726465720000000000000000000000)
            );
        }
    }

    function _restoreExpiredOrders(GoldChain.Order[] memory orders, uint len) private {
        // uint len = orders.length;
        while (len > 0) {
            _restoreOrder(orders[len-1]);
            len--;
        }
    }    

    function withdrawInitialOffer(
        address msgSender, uint classOfShare, uint seqOfOrder, uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        IUsdListOfOrders _loo = _looInUSD();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, true);

        require(order.data.seqOfShare == 0,
            "LOOKUSD.withdrawInitOrder: not initOrder");

        RulesParser.ListingRule memory lr =
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();
        
        require(_gk.getROD().hasTitle(caller, lr.titleOfIssuer),
            "LOOKUSD.withdrawInitOrder: has no title");

        order = _loo.withdrawOrder(classOfShare, seqOfOrder, true);

        _restoreOrder(order);
    }

    function placeSellOrder(
        address msgSender, uint seqOfClass, uint execHours,
        uint paid, uint price, uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);

        require (_gk.getLOO().getInvestor(caller).state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved),
                "LOOKUSD.placeSellOrder: wrong stateOfInvestor");

        IRegisterOfShares _ros = _gk.getROS();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(seqOfClass == lr.classOfShare,
            "LOOKUSD.placePut: wrong class");

        require(uint32(price) >= lr.offPrice,
            "LOOKUSD.placePut: lower than offPrice");

        uint[] memory sharesInhand = 
            _gk.getROM().sharesInClass(caller, lr.classOfShare);

        uint len = sharesInhand.length;

        while (len > 0 && paid > 0) {

            SharesRepo.Share memory share = 
                _ros.getShare(sharesInhand[len - 1]);
            len--;

            if (!_ros.notLocked(share.head.seqOfShare, block.timestamp)) {
                continue;
            }

            if (lr.lockupDays == 0 ||
                share.head.issueDate + 
                uint48(lr.lockupDays) * 86400 < block.timestamp) 
            {
                if (share.body.cleanPaid > 0) {
                    
                    UsdOrdersRepo.Deal memory input;

                    input.to = msgSender;
                    input.seller = share.head.shareholder;
                    input.classOfShare = share.head.class;
                    input.seqOfShare = share.head.seqOfShare;
                    input.price = uint32(price);
                    input.votingWeight = share.head.votingWeight;
                    input.distrWeight = share.body.distrWeight;
                    input.isOffer = true;

                    if (paid >= share.body.cleanPaid) {
                        input.paid = uint64(share.body.cleanPaid);
                        paid -=input.paid;
                        _ros.decreaseCleanPaid(share.head.seqOfShare, input.paid);
                        _placeSellOrder(input, execHours);
                    } else {
                        input.paid = uint64(paid);
                        _ros.decreaseCleanPaid(share.head.seqOfShare, input.paid);
                        _placeSellOrder(input, execHours);
                        break;
                    }

                } 
            }
        }
    }

    function withdrawSellOrder(
        address msgSender, uint classOfShare,uint seqOfOrder
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        IUsdListOfOrders _loo = _looInUSD();
        IRegisterOfShares _ros = _gk.getROS();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, true);

        require(order.data.seqOfShare > 0,
            "LOOKUSD.withdrawSellOrder: zero seqOfShare");

        SharesRepo.Share memory share =
            _ros.getShare(order.data.seqOfShare);
        
        require(share.head.shareholder == caller,
            "LOOKUSD.withdrawSellOrder: not shareholder");
        
        order = _loo.withdrawOrder(classOfShare, seqOfOrder, true);

        _restoreOrder(order);
    }

    // ==== Bid ====

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, address msgSender, 
        uint classOfShare, uint paid, uint price, uint execHours
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        InvestorsRepo.Investor memory investor = 
            _gk.getLOO().getInvestor(caller);

        require (investor.state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved),
                "LOOKUSD.placeBuyOrder: wrong stateOfInvestor");
        
        require(price > 0, "ULOOK.placeBuyOrder: zero price");

        UsdOrdersRepo.Deal memory input;

        input.from = msgSender;
        input.buyer = uint40(caller);
        input.groupRep = investor.groupRep;
        input.classOfShare = uint16(classOfShare);
        input.paid = uint64(paid);
        input.price = uint32(price);
        input.consideration = uint128(paid * price);

        auth.from = input.from;
        auth.value = input.consideration / 100;
        _placeBuyOrder(auth, input, execHours);
    }

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, address msgSender, 
        uint classOfShare, uint paid, uint execHours
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        InvestorsRepo.Investor memory investor = 
            _gk.getLOO().getInvestor(caller);

        require (investor.state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved),
                "LOOKUSD.placeMarketBuyOrder: wrong stateOfInvestor");

        require(auth.value > 0, "ULOOK.placeMarketBuyOrder: zero margin");

        UsdOrdersRepo.Deal memory input;

        input.from = msgSender;
        input.buyer = uint40(caller);
        input.groupRep = investor.groupRep;
        input.classOfShare = uint16(classOfShare);
        input.paid = uint64(paid);
        input.consideration = uint128(auth.value * 100);

        auth.from = input.from;
        _placeBuyOrder(auth, input, execHours);
    }

    function _placeBuyOrder(
        ICashier.TransferAuth memory auth, UsdOrdersRepo.Deal memory input, uint execHours
    ) private {

        // remark: CustodyValueOfBid
        _cashier().custodyUsd(
            auth, 
            bytes32(0x437573746f647956616c75654f66426964000000000000000000000000000000)
        );

        (UsdOrdersRepo.Deal[] memory deals,
         uint lenOfDeals,
         GoldChain.Order[] memory expired,
         uint lenOfExpired,
         UsdOrdersRepo.Deal memory bid) = 
            _looInUSD().placeBuyOrder(input, execHours);

        if (lenOfDeals > 0) _closeDeals(deals, lenOfDeals, false);
        if (lenOfExpired > 0) _restoreExpiredOrders(expired, lenOfExpired);
        if (bid.paid == 0 && bid.consideration > 0) {
            // remark: RefundBalanceOfBidOrder
            _cashier().releaseUsd(
                bid.from, 
                bid.from, 
                _eightToSix(bid.consideration), 
                bytes32(0x526566756e6442616c616e63654f664269644f72646572000000000000000000)
            );
        }
    }

    function withdrawBuyOrder(
        address msgSender, uint classOfShare, uint seqOfOrder
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        IUsdListOfOrders _loo = _looInUSD();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, false);
        
        require(order.node.issuer == caller,
            "LOOKUSD.withdrawBuyOrder: not buyer");
        
        order = _loo.withdrawOrder(classOfShare, seqOfOrder, false);

        _restoreOrder(order);
    }
}
