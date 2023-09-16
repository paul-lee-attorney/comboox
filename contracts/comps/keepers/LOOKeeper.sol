// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/access/AccessControl.sol";

import "./ILOOKeeper.sol";

contract LOOKeeper is ILOOKeeper, AccessControl {
    using RulesParser for bytes32;

    //##################
    //##   Modifier   ##
    //##################

    //###############
    //##   Write   ##
    //###############

    function regInvestor(
        uint caller,
        uint groupRep,
        bytes32 idHash,
        uint seqOfLR
    ) external onlyDK {
        
        IListOfOrders _loo = _gk.getLOO();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(lr.maxQtyOfInvestors == 0 || 
            _loo.getQtyOfInvestors() < lr.maxQtyOfInvestors,
            "LOOK.regInv: qty overflow");

        require(groupRep == 0 || _gk.getROM().isMember(groupRep),
            "LOOK.regInv: groupRep not member");

        _loo.regInvestor(caller, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        uint caller,
        uint seqOfLR
    ) external onlyDK {
        

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfVerifier),
            "LOOK.approveInv: wrong titl");

        _gk.getLOO().approveInvestor(userNo, caller);
    }

    function placeInitialOffer(
        uint caller,
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external onlyDK {
        
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        require(_gk.getROD().hasTitle(caller, lr.titleOfIssuer),
            "LOOK.placeIO: not entitled");

        require(lr.classOfShare == classOfShare,
            "LOOK.placeIO: wrong class");
        
        require(uint32(price) >= lr.floorPrice,
            "LOOK.placeIO: lower than floor");

        require(uint32(price) <= lr.ceilingPrice,
            "LOOK.placeIO: higher than ceiling");

        require (_gk.getROS().getInfoOfClass(classOfShare).body.par +
            paid <= lr.maxTotalPar, "LOOK.placeIO: paid overflow");

        _gk.getLOO().placePutOrder(
            caller,
            classOfShare,
            0,
            execHours,
            paid,
            price
        );
    }

    function placePutOrder(
        uint caller,
        uint seqOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        SharesRepo.Share memory share = _ros.getShare(seqOfShare);

        require(lr.classOfShare == share.head.class,
            "LOOK.placePut: wrong classOfShare");

        require(share.head.shareholder == caller,
            "LOOK.placePut: not shareholder");
        
        require(price >= lr.offPrice,
            "LOOK.placePut: lower than offPrice");

        require(lr.lockupDays == 0 ||
            share.head.issueDate + uint48(lr.lockupDays) * 86400 < block.timestamp,
            "LOOK.placePut: still in lockup");

        _ros.decreaseCleanPaid(seqOfShare, paid);

        _gk.getLOO().placePutOrder(
            caller,
            share.head.class,
            seqOfShare,
            execHours,
            paid,
            price
        );
    }

    function placeCallOrder(
        uint caller,
        uint classOfShare,
        uint paid,
        uint price,
        uint msgValue
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();
        uint centPrice = _gk.getCentPrice();


        require(paid * price * centPrice / 100 <= msgValue,
            "LOOK.placeCall: insufficient value");
        
        (OrdersRepo.Deal[] memory deals, GoldChain.Order memory call) = 
            _gk.getLOO().placeCallOrder(
                caller,
                classOfShare,
                paid,
                price
            );

        uint len = deals.length;
        while (len > 0) {
            OrdersRepo.Deal memory deal = deals[len - 1];

            uint valueOfDeal = deal.paid * deal.price * centPrice / 100;

            msgValue -= valueOfDeal;

            if (deal.seqOfShare > 0) {
                SharesRepo.Share memory share = _ros.getShare(deal.seqOfShare);
                _gk.saveToCoffer(share.head.shareholder, valueOfDeal);
                _ros.increaseCleanPaid(deal.seqOfShare, deal.paid);
                _ros.transferShare(
                    deal.seqOfShare,
                    deal.paid,
                    deal.paid,
                    deal.buyer,
                    deal.price,
                    deal.price
                );
            } else {
                SharesRepo.Share memory share;
                
                share.head = SharesRepo.Head({
                    class: uint16(classOfShare),
                    seqOfShare: 0,
                    preSeq: 0,
                    issueDate: 0,
                    shareholder: deal.buyer,
                    priceOfPaid: deal.price,
                    priceOfPar: deal.price,
                    votingWeight: 100,
                    argu: 0
                });

                share.body = SharesRepo.Body({
                    payInDeadline: uint48(block.timestamp + 86400),
                    paid: deal.paid,
                    par: deal.paid,
                    cleanPaid: deal.paid,
                    state: 0,
                    para: 0
                });

                _ros.addShare(share);
            }

            if (deal.groupRep != deal.buyer && 
                deal.groupRep != _rom.groupRep(deal.buyer))
                    _rom.addMemberToGroup(deal.buyer, deal.groupRep);
        }

        if (msgValue > 0) 
            _gk.saveToCoffer(call.offeror, msgValue);

    }

}
