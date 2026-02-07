// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "../../comps/common/access/RoyaltyCharge.sol";

import "../../comps/keepers/IAccountant.sol";

contract FundAccountant is IAccountant, RoyaltyCharge {
    using RulesParser for bytes32;
    using BooksRepo for IBaseKeeper;

    function initClass(uint class) external onlyDK {
        uint sum = gk.getROS().getInfoOfClass(class).body.paid;
        gk.getCashier().initClass(class, sum);
    }

    function distrProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);

        require(gk.getROM().isClassMember(caller, 1), 
            "Accountant: not GP");

        gk.getGMM().distributeUsd(
            amt,
            expireDate,
            seqOfDR,
            0,
            seqOfMotion,
            caller
        );

        gk.getCashier().distrProfits(amt, seqOfDR);
    }

    function distrIncome(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint fundManager,
        uint seqOfMotion,
        address msgSender        
    ) external onlyDK {

        uint caller = _msgSender(msgSender, 18000);

        require(gk.getROM().isClassMember(caller, 1), 
            "Accountant: not GP");

        IRegisterOfShares _ros = gk.getROS();
        ICashier _cashier = gk.getCashier();

        gk.getGMM().distributeUsd(
            amt,
            expireDate,
            seqOfDR,
            fundManager,
            seqOfMotion,
            caller
        );

        (,WaterfallsRepo.Drop[] memory list) =
            _cashier.distrIncome(amt, seqOfDR, fundManager);

        RulesParser.DistrRule memory rule =
            gk.getSHA().getRule(seqOfDR).DistrRuleParser();

        uint len = list.length;
        while(len > 0) {

            WaterfallsRepo.Drop memory drop = list[len-1];

            if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.ProRata)) {

                uint[] memory seqs = 
                    gk.getROM().sharesInHand(drop.member);
                uint paids = gk.getROM().pointsOfMember(drop.member).paid * 100;

                uint lenOfShares = seqs.length;
                while (lenOfShares >0) {
                    SharesRepo.Share memory share = _ros.getShare(seqs[lenOfShares - 1]);
                    uint deltaPaid = share.body.paid * drop.principal / paids;
                    _ros.decreaseCapital(share.head.seqOfShare, deltaPaid, 0);
                    lenOfShares--;
                }
                
            } else {

                if (drop.principal > 0) {
                    SharesRepo.Share memory share = _ros.getShare(drop.distrDate);
                    _ros.decreaseCapital(
                        share.head.seqOfShare, 
                        drop.principal/100, 
                        0
                    );
                }
                
            }

            len--;
        }
    }

    function transferFund(
        bool fromBMM,
        address to,
        bool isCBP,
        uint amt,
        uint expireDate,
        uint seqOfMotion,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 76000);

        require(gk.getROM().isClassMember(caller, 1) ||
            gk.getROD().isDirector(caller), 
            "GMMK: not GP");

        if (fromBMM) {
            gk.getBMM().transferFund(
                to,
                isCBP,
                amt,
                expireDate,
                seqOfMotion,
                caller
            );
        } else {
            gk.getGMM().transferFund(
                to,
                isCBP,
                amt,
                expireDate,
                seqOfMotion,
                caller
            );
        }

        if (!isCBP) {
            gk.getCashier().transferUsd(to, amt, bytes32(seqOfMotion));
        }
    }
}
