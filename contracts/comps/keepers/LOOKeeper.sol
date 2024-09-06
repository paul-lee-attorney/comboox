// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "../common/access/RoyaltyCharge.sol";

import "./ILOOKeeper.sol";

contract LOOKeeper is ILOOKeeper, RoyaltyCharge {
    using RulesParser for bytes32;

    //###############
    //##   Write   ##
    //###############

    // ==== Investor ====

    function regInvestor(
        address msgSender,
        uint groupRep,
        bytes32 idHash
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);
        _gk.getLOO().regInvestor(caller, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        address msgSender,
        uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        IListOfOrders _loo = _gk.getLOO();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfVerifier),
            "LOOK.apprInv: no rights");

        require(lr.maxQtyOfInvestors == 0 ||
            _loo.getQtyOfInvestors() < lr.maxQtyOfInvestors,
            "LOOK.apprInv: no quota");

        _loo.approveInvestor(userNo, caller);
    }

    function revokeInvestor(
        uint userNo,
        address msgSender,
        uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfVerifier),
            "LOOK.revokeInv: wrong titl");

        _gk.getLOO().revokeInvestor(userNo, caller);
    }

    // ==== Offers ====

    function placeInitialOffer(
        address msgSender,
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        IRegisterOfShares _ros = _gk.getROS();
        
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfIssuer),
            "LOOK.placeIO: not entitled");

        require(lr.classOfShare == classOfShare,
            "LOOK.placeIO: wrong class");
        
        require(uint32(price) >= lr.floorPrice,
            "LOOK.placeIO: lower than floor");

        require(lr.ceilingPrice == 0 ||
            uint32(price) <= lr.ceilingPrice,
            "LOOK.placeIO: higher than ceiling");

        require (_ros.getInfoOfClass(classOfShare).body.cleanPaid +
            paid <= uint64(lr.maxTotalPar) * 10000, "LOOK.placeIO: paid overflow");

        _ros.increaseEquityOfClass(true, classOfShare, 0, 0, paid);

        _placeSellOrder(
            caller,
            classOfShare, 
            0,
            lr.votingWeight, 
            lr.distrWeight,
            paid,
            price,
            execHours,
            _gk.getCentPrice()
        );
    }

    function _placeSellOrder(
        uint caller,
        uint classOfShare,
        uint seqOfShare,
        uint votingWeight,
        uint distrWeight,
        uint paid,
        uint price,
        uint execHours,
        uint centPrice        
    ) private {
        (OrdersRepo.Deal[] memory deals, GoldChain.Order[] memory expired, OrdersRepo.Deal memory offer) = 
            _gk.getLOO().placeSellOrder(
                caller,
                classOfShare, 
                seqOfShare, 
                votingWeight, 
                distrWeight,
                paid, 
                price, 
                execHours, 
                centPrice
            );
        if (deals.length > 0) _closeDeals(deals);
        if (expired.length > 0) _restoreExpiredOrders(expired);
        if (offer.price == 0 && offer.paid > 0) {
            GoldChain.Order memory balance;
            balance.data.classOfShare = offer.classOfShare;
            balance.data.seqOfShare = offer.seqOfShare;
            balance.node.paid = offer.paid;
            _restoreOrder(balance);
        }
    }

    function _closeDeals(OrdersRepo.Deal[] memory deals) private {

        IRegisterOfShares _ros = _gk.getROS(); 
        IRegisterOfMembers _rom = _gk.getROM();

        uint len = deals.length;
        while (len > 0) {

            OrdersRepo.Deal memory deal = deals[len - 1];
            len--;

            if (deal.seqOfShare > 0) {

                if (!_ros.notLocked(deal.seqOfShare, block.timestamp)) {
                    continue;
                }

                SharesRepo.Share memory share = _ros.getShare(deal.seqOfShare);
                _gk.saveToCoffer(share.head.shareholder, deal.consideration);
                _ros.increaseCleanPaid(deal.seqOfShare, deal.paid);
                _ros.transferShare(
                    deal.seqOfShare,
                    deal.paid,
                    deal.paid,
                    deal.buyer,
                    deal.price,
                    0
                );

                emit ReleaseSTConsideration(share.head.shareholder, deal.consideration);

            } else {
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
                deal.groupRep != _rom.groupRep(deal.buyer))
                    _rom.addMemberToGroup(deal.buyer, deal.groupRep);
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
            uint amt = uint(order.node.paid) * order.node.price / 10000 * order.data.centPriceInWei / 100;
            _gk.saveToCoffer(order.data.buyer, amt);
            emit RefundBidDeposit(order.data.buyer, amt);
        }
    }

    function _restoreExpiredOrders(GoldChain.Order[] memory orders) private {
        uint len = orders.length;
        while (len > 0) {
            _restoreOrder(orders[len-1]);
            len--;
        }
    }    

    function withdrawInitialOffer(
        address msgSender,
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        IListOfOrders _loo = _gk.getLOO();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, true);

        require(order.data.seqOfShare == 0,
            "LOOK.withdrawInitOrder: not initOrder");

        RulesParser.ListingRule memory lr =
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();
        
        require(_gk.getROD().hasTitle(caller, lr.titleOfIssuer),
            "LOOK.withdrawInitOrder: has no title");

        order = _loo.withdrawOrder(classOfShare, seqOfOrder, true);

        _restoreOrder(order);
    }

    function placeSellOrder(
        address msgSender,
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);

        require (_gk.getLOO().getInvestor(caller).state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved),
                "LOOK.placeSellOrder: wrong stateOfInvestor");

        IRegisterOfShares _ros = _gk.getROS();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(seqOfClass == lr.classOfShare,
            "LOOK.placePut: wrong class");

        require(uint32(price) >= lr.offPrice,
            "LOOK.placePut: lower than offPrice");

        uint centPrice = _gk.getCentPrice();

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

            if(lr.lockupDays == 0 ||
                share.head.issueDate + 
                uint48(lr.lockupDays) * 86400 < block.timestamp) 
            {
                if (share.body.cleanPaid > 0) {
                    if (paid >= share.body.cleanPaid) {
                        _createSellOrder(
                            share, 
                            share.body.cleanPaid, 
                            price, 
                            execHours,
                            centPrice,
                            _ros
                        );
                        paid -=share.body.cleanPaid;
                    } else {
                        _createSellOrder(
                            share, 
                            paid, 
                            price, 
                            execHours,
                            centPrice, 
                            _ros
                        );
                        break;
                    }
                } 
            }
        }
    }

    function _createSellOrder(
        SharesRepo.Share memory share, 
        uint paid,
        uint price,
        uint execHours,
        uint centPrice,
        IRegisterOfShares _ros
    ) private {
        _ros.decreaseCleanPaid(share.head.seqOfShare, paid);

        _placeSellOrder(
            share.head.shareholder,
            share.head.class,
            share.head.seqOfShare,
            share.head.votingWeight,
            share.body.distrWeight,
            paid,
            price,
            execHours,
            centPrice
        );
    }

    function withdrawSellOrder(
        address msgSender,
        uint classOfShare,
        uint seqOfOrder
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        IListOfOrders _loo = _gk.getLOO();
        IRegisterOfShares _ros = _gk.getROS();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, true);

        require(order.data.seqOfShare > 0,
            "LOOK.withdrawSellOrder: zero seqOfShare");

        SharesRepo.Share memory share =
            _ros.getShare(order.data.seqOfShare);
        
        require(share.head.shareholder == caller,
            "LOOK.withdrawSellOrder: not shareholder");
        
        order = _loo.withdrawOrder(classOfShare, seqOfOrder, true);

        _restoreOrder(order);
    }

    // ==== Bid ====

    function placeBuyOrder(
        address msgSender,
        uint classOfShare,
        uint paid,
        uint price,
        uint execHours,
        uint msgValue
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);
        uint centPrice = _gk.getCentPrice();

        InvestorsRepo.Investor memory investor = 
            _gk.getLOO().getInvestor(caller);

        require (investor.state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved),
                "LOOK.placeBuyOrder: wrong stateOfInvestor");

        _placeBuyOrder(classOfShare, caller, investor.groupRep, paid, price, execHours, centPrice, msgValue);
    }

    function _placeBuyOrder(
        uint classOfShare,
        uint buyer,
        uint groupRep,
        uint paid,
        uint price,
        uint execHours,
        uint centPrice,
        uint msgValue
    ) private {
        (OrdersRepo.Deal[] memory deals, GoldChain.Order[] memory expired, OrdersRepo.Deal memory bid) = 
            _gk.getLOO().placeBuyOrder(
                classOfShare,
                buyer,
                groupRep,
                paid,
                price,
                execHours,
                centPrice,
                msgValue
            );

        if (deals.length > 0) _closeDeals(deals);
        if (expired.length > 0) _restoreExpiredOrders(expired);
        if (bid.price == 0 && bid.paid > 0) {
            _gk.saveToCoffer(bid.buyer, bid.consideration);
            emit RefundBidDeposit(bid.buyer, bid.consideration);
        }
    }

    function withdrawBuyOrder(
        address msgSender,
        uint classOfShare,
        uint seqOfOrder
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        IListOfOrders _loo = _gk.getLOO();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, false);
        
        require(order.data.buyer == caller,
            "LOOK.withdrawBuyOrder: not buyer");
        
        order = _loo.withdrawOrder(classOfShare, seqOfOrder, false);

        _restoreOrder(order);
    }
}
