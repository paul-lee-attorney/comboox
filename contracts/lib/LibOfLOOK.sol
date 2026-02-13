// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
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

import "./InterfacesHub.sol";
import "./GoldChain.sol";
import "./UsdOrdersRepo.sol";
import "./SharesRepo.sol";

import "../comps/books/cashier/ICashier.sol";
import "../comps/books/loo/IListOfOrders.sol";
import "../comps/books/rom/IRegisterOfMembers.sol";
import "../comps/books/ros/IRegisterOfShares.sol";

library LibOfLOOK {
    using InterfacesHub for address;

    function placeSellOrder(
        UsdOrdersRepo.Deal memory input,
        uint execHours
    ) external {
        address gk = address(this);
        (
            UsdOrdersRepo.Deal[] memory deals,
            uint lenOfDeals,
            GoldChain.Order[] memory expired,
            uint lenOfExpired,
            UsdOrdersRepo.Deal memory offer
        ) = gk.getLOO().placeSellOrder(input, execHours);

        if (lenOfDeals > 0) {
            _closeDeals(deals, lenOfDeals, true);
        }
        if (lenOfExpired > 0) {
            restoreExpiredOrders(expired, lenOfExpired);
        }
        if (offer.price == 0 && offer.paid > 0) {
            GoldChain.Order memory balance;
            balance.data.classOfShare = offer.classOfShare;
            balance.data.seqOfShare = offer.seqOfShare;
            balance.data.pubKey = offer.to;
            balance.node.paid = offer.paid;
            restoreOrder(balance);
        }
    }

    function placeBuyOrder(
        ICashier.TransferAuth memory auth,
        UsdOrdersRepo.Deal memory input,
        uint execHours
    ) external {
        address gk = address(this);

        ICashier _cashier = gk.getCashier();

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
        ) = gk.getLOO().placeBuyOrder(input, execHours);

        if (lenOfDeals > 0) {
            _closeDeals(deals, lenOfDeals, false);
        }
        if (lenOfExpired > 0) {
            restoreExpiredOrders(expired, lenOfExpired);
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

    function restoreOrder(
        GoldChain.Order memory order
    ) public {
        address gk = address(this);
        if (order.node.isOffer) {
            IRegisterOfShares _ros = gk.getROS();
            if (order.data.seqOfShare > 0) {
                _ros.increaseCleanPaid(order.data.seqOfShare, order.node.paid);
            } else {
                _ros.increaseEquityOfClass(false, order.data.classOfShare, 0, 0, order.node.paid);
            }
        } else {
            gk.getCashier().releaseUsd(
                order.data.pubKey,
                order.data.pubKey,
                _eightToSix(order.data.margin),
                bytes32("RefundValueOfBidOrder")
            );
        }
    }

    function restoreExpiredOrders(
        GoldChain.Order[] memory orders,
        uint len
    ) public {
        while (len > 0) {
            restoreOrder(orders[len - 1]);
            len--;
        }
    }

    function _closeDeals(
        UsdOrdersRepo.Deal[] memory deals,
        uint len,
        bool isOffer
    ) private {
        address gk = address(this);
        ICashier _cashier = gk.getCashier();
        IRegisterOfShares _ros = gk.getROS();
        IRegisterOfMembers _rom = gk.getROM();

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
