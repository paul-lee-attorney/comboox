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

import "../common/access/RoyaltyCharge.sol";

import "./ILOOKeeper.sol";
import "../../lib/LibOfLOOK.sol";

contract LOOKeeper is ILOOKeeper, RoyaltyCharge {
    using RulesParser for bytes32;
    using InterfacesHub for address;

    modifier whenNotPaused() {
        if (gk.getROI().isPaused())
            revert LOOK_IsPaused();
        _;
    }

    //###############
    //##   Write   ##
    //###############

    // ==== Offers ====

    function placeInitialOffer(
        uint classOfShare, uint execHours, 
        uint paid, uint price, uint seqOfLR
    ) external whenNotPaused onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);

        IRegisterOfShares _ros = gk.getROS();
        
        RulesParser.ListingRule memory lr = 
            gk.getSHA().getRule(seqOfLR).listingRuleParser();

        if (!gk.getROD().hasTitle(caller, lr.titleOfIssuer))
            revert LOOK_NotEntitled(caller);

        if (lr.classOfShare != classOfShare)
            revert LOOK_WrongClass(lr.classOfShare, classOfShare);

        if (uint32(price) < lr.floorPrice)
            revert LOOK_LowerThanFloor(lr.floorPrice, uint32(price));

        if (lr.ceilingPrice > 0 && uint32(price) > lr.ceilingPrice)
            revert LOOK_HigherThanCeiling(lr.ceilingPrice, uint32(price));

        if (_ros.getInfoOfClass(classOfShare).body.cleanPaid + paid > 
            uint64(lr.maxTotalPar) * 10000
        ) revert LOOK_PaidOverflow(uint64(lr.maxTotalPar) * 10000, 
                _ros.getInfoOfClass(classOfShare).body.cleanPaid + paid);

        _ros.increaseEquityOfClass(true, classOfShare, 0, 0, paid);

        UsdOrdersRepo.Deal memory input;
        
        input.classOfShare = uint16(classOfShare);
        input.votingWeight = lr.votingWeight;
        input.distrWeight = lr.distrWeight;
        input.paid = uint64(paid);
        input.price = uint32(price);
        input.seller = uint40(caller);
        input.isOffer = true;

        LibOfLOOK.placeSellOrder(input, execHours);
    }    

    function withdrawInitialOffer(
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);

        IListOfOrders _loo = gk.getLOO();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, true);

        if (order.data.seqOfShare > 0)
            revert LOOK_NotInitOrder(order.data.seqOfShare);

        RulesParser.ListingRule memory lr =
            gk.getSHA().getRule(seqOfLR).listingRuleParser();

        if (!gk.getROD().hasTitle(caller, lr.titleOfIssuer))
            revert LOOK_NotEntitled(caller);

        order = _loo.withdrawOrder(classOfShare, seqOfOrder, true);

        LibOfLOOK.restoreOrder(order);
    }

    function placeSellOrder(
        uint seqOfClass, uint execHours,
        uint paid, uint price, uint seqOfLR
    ) external whenNotPaused onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);

        if(gk.getROI().getInvestor(caller).state != 
            uint8(InvestorsRepo.StateOfInvestor.Approved))
            revert LOOK_NotQualifiedInvestor(caller);

        IRegisterOfShares _ros = gk.getROS();

        RulesParser.ListingRule memory lr = 
            gk.getSHA().getRule(seqOfLR).listingRuleParser();

        if (seqOfClass != lr.classOfShare)
            revert LOOK_WrongClass(lr.classOfShare, seqOfClass);

        if (uint32(price) < lr.offPrice)
            revert LOOK_LowerThanFloor(lr.offPrice, uint32(price));

        uint[] memory sharesInhand = 
            gk.getROM().sharesInClass(caller, lr.classOfShare);

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

                    input.to = msg.sender;
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
                        LibOfLOOK.placeSellOrder(input, execHours);
                    } else {
                        input.paid = uint64(paid);
                        _ros.decreaseCleanPaid(share.head.seqOfShare, input.paid);
                        LibOfLOOK.placeSellOrder(input, execHours);
                        break;
                    }

                }
            }
        }
    }

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 88000);

        IListOfOrders _loo = gk.getLOO();
        IRegisterOfShares _ros = gk.getROS();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, true);

        require(order.data.seqOfShare > 0,
            "LOOK.withdrawSellOrder: zero seqOfShare");

        SharesRepo.Share memory share =
            _ros.getShare(order.data.seqOfShare);
        
        require(share.head.shareholder == caller,
            "LOOK.withdrawSellOrder: not shareholder");
        
        order = _loo.withdrawOrder(classOfShare, seqOfOrder, true);

        LibOfLOOK.restoreOrder(order);
    }

    // ==== Bid ====

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, 
        uint classOfShare, uint paid, uint price, uint execHours
    ) external whenNotPaused onlyGKProxy {
        uint caller = _msgSender(msg.sender, 88000);

        InvestorsRepo.Investor memory investor = 
            gk.getROI().getInvestor(caller);

        require (investor.state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved),
                "LOOK.placeBuyOrder: wrong stateOfInvestor");
        
        require(price > 0, "ULOOK.placeBuyOrder: zero price");

        require(gk.getSHA().isSigner(caller),
            "LOOK: buyer not signer of SHA");

        UsdOrdersRepo.Deal memory input;

        input.from = msg.sender;
        input.buyer = uint40(caller);
        input.groupRep = investor.groupRep;
        input.classOfShare = uint16(classOfShare);
        input.paid = uint64(paid);
        input.price = uint32(price);
        input.consideration = uint128(paid * price);

        auth.from = input.from;
        auth.value = input.consideration / 100;
        LibOfLOOK.placeBuyOrder(auth, input, execHours);
    }

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, 
        uint classOfShare, uint paid, uint execHours
    ) external whenNotPaused onlyGKProxy {
        uint caller = _msgSender(msg.sender, 88000);

        InvestorsRepo.Investor memory investor = 
            gk.getROI().getInvestor(caller);

        require (investor.state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved),
                "LOOK.placeMarketBuyOrder: wrong stateOfInvestor");

        require(auth.value > 0, "LOOK.placeMarketBuyOrder: zero margin");

        require(gk.getSHA().isSigner(caller),
            "LOOK: buyer not signer of SHA");

        UsdOrdersRepo.Deal memory input;

        input.from = msg.sender;
        input.buyer = uint40(caller);
        input.groupRep = investor.groupRep;
        input.classOfShare = uint16(classOfShare);
        input.paid = uint64(paid);
        input.consideration = uint128(auth.value * 100);

        auth.from = input.from;
        LibOfLOOK.placeBuyOrder(auth, input, execHours);
    }

    function withdrawBuyOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external onlyGKProxy {
        uint caller = _msgSender(msg.sender, 88000);

        IListOfOrders _loo = gk.getLOO();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, false);
        
        require(order.node.issuer == caller,
            "LOOK.withdrawBuyOrder: not buyer");
        
        order = _loo.withdrawOrder(classOfShare, seqOfOrder, false);

        LibOfLOOK.restoreOrder(order);
    }
}
