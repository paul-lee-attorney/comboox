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

import "../books/RulesParser.sol";
import "../InterfacesHub.sol";
import "../utils/RoyaltyCharge.sol";


library FundLOOKeeper {
    using RulesParser for bytes32;
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // uint32(uint(keccak256("FundLOOKeeper")));
    uint constant public TYPE_OF_DOC = 0x6ab7d4a6;
    uint constant public VERSION = 1;

    //##########################
    //##  Error & Modifiers   ##
    //##########################

    error FundLOOK_WrongState(bytes32 reason);

    error FundLOOK_WrongParty(bytes32 reason);

    error FundLOOK_Overflow(bytes32 reason);

    error FundLOOK_ZeroValue(bytes32 reason);



    modifier whenNotPaused() {
        if(address(this).getROI().isPaused()) {
            revert FundLOOK_WrongState(bytes32("FundLOOK_LooPaused"));
        }
        _;
    }

    modifier onlyDK() {
        if (msg.sender != IAccessControl(address(this)).getDK()) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotDK"));
        }
        _;
    }

    // ==== Offers ====

    function placeInitialOffer(
        uint classOfShare, uint execHours, 
        uint paid, uint price, uint seqOfLR
    ) external onlyDK whenNotPaused {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        IRegisterOfShares _ros = _gk.getROS();
        
        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        if(!_gk.getROM().isClassMember(caller, 1)) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotGP"));
        }

        if(_gk.getCashier().getGulfInfo(classOfShare).principal != 0) {
            revert FundLOOK_WrongState(bytes32("FundLOOK_ClassEstablished"));
        }

        if(lr.classOfShare != classOfShare) {
            revert FundLOOK_WrongState(bytes32("FundLOOK_WrongClass"));
        }
        
        if(uint32(price) < lr.floorPrice) {
            revert FundLOOK_Overflow(bytes32("FundLOOK_PriceLowerFloor"));
        }

        if(lr.ceilingPrice != 0 && uint32(price) > lr.ceilingPrice) {
            revert FundLOOK_Overflow(bytes32("FundLOOK_PriceHigherCeiling"));
        }

        if (_ros.getInfoOfClass(classOfShare).body.cleanPaid +
            paid > uint64(lr.maxTotalPar) * 10000) {
            revert FundLOOK_Overflow(bytes32("FundLOOK_PaidOverflow"));
        }

        _ros.increaseEquityOfClass(true, classOfShare, 0, 0, paid);

        UsdOrdersRepo.Deal memory input;
        
        input.classOfShare = uint16(classOfShare);
        input.votingWeight = lr.votingWeight;
        input.distrWeight = lr.distrWeight;
        input.paid = uint64(paid);
        input.price = uint32(price);
        input.seller = uint40(caller);
        input.isOffer = true;

        _placeSellOrder(_gk, input, execHours);
    }    

    function withdrawInitialOffer(
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external onlyDK  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        IListOfOrders _loo = _gk.getLOO();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, true);

        if(order.data.seqOfShare != 0) {
            revert FundLOOK_WrongState(bytes32("FundLOOK_NotInitOrder"));
        }

        if(!_gk.getROM().isClassMember(caller, 1)) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotGP"));
        }

        RulesParser.ListingRule memory lr =
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();
        
        if(!_gk.getROD().hasTitle(caller, lr.titleOfIssuer)) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotIssuer"));
        }

        order = _loo.withdrawOrder(classOfShare, seqOfOrder, true);

        _restoreOrder(_gk, order);
    }

    function placeSellOrder(
        uint seqOfClass, uint execHours,
        uint paid, uint price, uint seqOfLR
    ) external onlyDK whenNotPaused  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        if(_gk.getROI().getInvestor(caller).state != 
            uint8(InvestorsRepo.StateOfInvestor.Approved)) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotQualifiedInvestor"));
        }

        IRegisterOfShares _ros = _gk.getROS();

        RulesParser.ListingRule memory lr = 
            _gk.getSHA().getRule(seqOfLR).listingRuleParser();

        if(seqOfClass != lr.classOfShare) {
            revert FundLOOK_WrongState(bytes32("FundLOOK_WrongClass"));
        }

        if(uint32(price) < lr.offPrice) {
            revert FundLOOK_Overflow(bytes32("FundLOOK_PriceLowerOff"));
        }

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
                        _placeSellOrder(_gk,input, execHours);
                    } else {
                        input.paid = uint64(paid);
                        _ros.decreaseCleanPaid(share.head.seqOfShare, input.paid);
                        _placeSellOrder(_gk,input, execHours);
                        break;
                    }

                } 
            }
        }
    }

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 88000);

        IListOfOrders _loo = _gk.getLOO();
        IRegisterOfShares _ros = _gk.getROS();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, true);

        if(order.data.seqOfShare == 0) {
            revert FundLOOK_ZeroValue(bytes32("FundLOOK_ZeroSeqOfShare"));
        }

        SharesRepo.Share memory share =
            _ros.getShare(order.data.seqOfShare);
        
        if(share.head.shareholder != caller) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotShareholder"));
        }
        
        order = _loo.withdrawOrder(classOfShare, seqOfOrder, true);

        _restoreOrder(_gk, order);
    }

    // ==== Bid ====

    function placeBuyOrder(
        ICashier.TransferAuth memory auth, 
        uint classOfShare, uint paid, uint price, uint execHours
    ) external onlyDK whenNotPaused  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 88000);

        InvestorsRepo.Investor memory investor = 
            _gk.getROI().getInvestor(caller);

        if(investor.state != uint8(InvestorsRepo.StateOfInvestor.Approved)) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotQualifiedInvestor"));
        }
        
        if(price == 0) {
            revert FundLOOK_ZeroValue(bytes32("FundLOOK_ZeroPrice"));
        }

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
        _placeBuyOrder(_gk, auth, input, execHours);
    }

    function placeMarketBuyOrder(
        ICashier.TransferAuth memory auth, 
        uint classOfShare, uint paid, uint execHours
    ) external onlyDK whenNotPaused  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 88000);

        InvestorsRepo.Investor memory investor = 
            _gk.getROI().getInvestor(caller);

        if(investor.state != uint8(InvestorsRepo.StateOfInvestor.Approved)) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotQualifiedInvestor"));
        }

        if(auth.value == 0) {
            revert FundLOOK_ZeroValue(bytes32("FundLOOK_ZeroMargin"));
        }

        UsdOrdersRepo.Deal memory input;

        input.from = msg.sender;
        input.buyer = uint40(caller);
        input.groupRep = investor.groupRep;
        input.classOfShare = uint16(classOfShare);
        input.paid = uint64(paid);
        input.consideration = uint128(auth.value * 100);

        auth.from = input.from;
        _placeBuyOrder(_gk, auth, input, execHours);
    }

    function withdrawBuyOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external onlyDK  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 88000);

        IListOfOrders _loo = _gk.getLOO();

        GoldChain.Order memory order = 
            _loo.getOrder(classOfShare, seqOfOrder, false);
        
        if(order.node.issuer != caller) {
            revert FundLOOK_WrongParty(bytes32("FundLOOK_NotBuyer"));
        }
        
        order = _loo.withdrawOrder(classOfShare, seqOfOrder, false);

        _restoreOrder(_gk, order);
    }

    // ==== Settlement ====

    function _placeSellOrder(
        address _gk,
        UsdOrdersRepo.Deal memory input,
        uint execHours
    ) private {
        (
            UsdOrdersRepo.Deal[] memory deals,
            uint lenOfDeals,
            GoldChain.Order[] memory expired,
            uint lenOfExpired,
            UsdOrdersRepo.Deal memory offer
        ) = _gk.getLOO().placeSellOrder(input, execHours);

        if (lenOfDeals > 0) {
            _closeDeals(_gk, deals, lenOfDeals, true);
        }
        if (lenOfExpired > 0) {
            _restoreExpiredOrders(_gk, expired, lenOfExpired);
        }
        if (offer.price == 0 && offer.paid > 0) {
            GoldChain.Order memory balance;
            balance.data.classOfShare = offer.classOfShare;
            balance.data.seqOfShare = offer.seqOfShare;
            balance.data.pubKey = offer.to;
            balance.node.paid = offer.paid;
            _restoreOrder(_gk, balance);
        }
    }

    function _placeBuyOrder(
        address _gk,
        ICashier.TransferAuth memory auth,
        UsdOrdersRepo.Deal memory input,
        uint execHours
    ) private {
        ICashier _cashier = _gk.getCashier();

        _cashier.custodyUsd(
            auth,
            bytes32("CustodyValueOfBid")
        );

        (
            UsdOrdersRepo.Deal[] memory deals,
            uint lenOfDeals,
            GoldChain.Order[] memory expired,
            uint lenOfExpired,
            UsdOrdersRepo.Deal memory bid
        ) = _gk.getLOO().placeBuyOrder(input, execHours);

        if (lenOfDeals > 0) {
            _closeDeals(_gk, deals, lenOfDeals, false);
        }
        if (lenOfExpired > 0) {
            _restoreExpiredOrders(_gk, expired, lenOfExpired);
        }
        if (bid.paid == 0 && bid.consideration > 0) {
            _cashier.releaseUsd(
                bid.from,
                bid.from,
                _eightToSix(bid.consideration),
                bytes32("RefundBalanceOfBidOrder")
            );
        }
    }

    function _restoreOrder(
        address _gk,
        GoldChain.Order memory order
    ) private {
        if (order.node.isOffer) {
            IRegisterOfShares _ros = _gk.getROS();
            if (order.data.seqOfShare > 0) {
                _ros.increaseCleanPaid(order.data.seqOfShare, order.node.paid);
            } else {
                _ros.increaseEquityOfClass(false, order.data.classOfShare, 0, 0, order.node.paid);
            }
        } else {
            _gk.getCashier().releaseUsd(
                order.data.pubKey,
                order.data.pubKey,
                _eightToSix(order.data.margin),
                bytes32("RefundValueOfBidOrder")
            );
        }
    }

    function _restoreExpiredOrders(
        address _gk,
        GoldChain.Order[] memory orders,
        uint len
    ) private {
        while (len > 0) {
            _restoreOrder(_gk, orders[len - 1]);
            len--;
        }
    }

    function _closeDeals(
        address _gk,
        UsdOrdersRepo.Deal[] memory deals,
        uint len,
        bool isOffer
    ) private {
        ICashier _cashier = _gk.getCashier();
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
                    _cashier.releaseUsd(
                        deal.from,
                        deal.to,
                        _eightToSix(deal.consideration),
                        bytes32("CloseOfferAgainstBid")
                    );
                } else {
                    _cashier.releaseUsd(
                        deal.from,
                        deal.to,
                        _eightToSix(deal.consideration),
                        bytes32("CloseBidAgainstOffer")
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
                    _cashier.releaseUsd(
                        deal.from,
                        address(_cashier),
                        _eightToSix(deal.consideration),
                        bytes32("CloseInitOfferAgainstBid")
                    );
                } else {
                    _cashier.releaseUsd(
                        deal.from,
                        address(_cashier),
                        _eightToSix(deal.consideration),
                        bytes32("CloseBidAgainstInitOffer")
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

    function _eightToSix(uint amt) private pure returns(uint) {
        return amt / 100;
    }

}
