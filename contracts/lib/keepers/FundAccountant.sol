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

library FundAccountant {
    using RulesParser for bytes32;
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // uint32(uint(keccak256("FundAccountant")));
    uint public constant TYPE_OF_DOC = 0x797eb8dd;
    uint public constant VERSION = 1;

    // #####################
    // ##  Error & Event  ##
    // #####################

    error FundACCT_WrongParty(bytes32 reason);

    modifier onlyDK() {
        address _gk = address(this);
        if (msg.sender != IAccessControl(_gk).getDK()) {
            revert FundACCT_WrongParty("Not DK");
        }
        _;
    }

    function initClass(uint class) external onlyDK  {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        uint sum = _gk.getROS().getInfoOfClass(class).body.paid;
        _gk.getCashier().initClass(class, sum);
    }

    function distrProfits(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint seqOfMotion
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        require(_gk.getROM().isClassMember(caller, 1), 
            "Accountant: not GP");

        _gk.getGMM().distributeUsd(
            amt,
            expireDate,
            seqOfDR,
            0,
            seqOfMotion,
            caller
        );

        _gk.getCashier().distrProfits(amt, seqOfDR);
    }

    function distrIncome(
        uint amt,
        uint expireDate,
        uint seqOfDR,
        uint fundManager,
        uint seqOfMotion        
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        require(_gk.getROM().isClassMember(caller, 1), 
            "Accountant: not GP");

        IRegisterOfShares _ros = _gk.getROS();
        ICashier _cashier = _gk.getCashier();

        _gk.getGMM().distributeUsd(
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
            _gk.getSHA().getRule(seqOfDR).DistrRuleParser();

        uint len = list.length;
        while(len > 0) {

            WaterfallsRepo.Drop memory drop = list[len-1];

            if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.ProRata)) {

                uint[] memory seqs = 
                    _gk.getROM().sharesInHand(drop.member);
                uint paids = _gk.getROM().pointsOfMember(drop.member).paid * 100;

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
        uint seqOfMotion
    ) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 76000);

        require(_gk.getROM().isClassMember(caller, 1) ||
            _gk.getROD().isDirector(caller), 
            "GMMK: not GP");

        if (fromBMM) {
            _gk.getBMM().transferFund(
                to,
                isCBP,
                amt,
                expireDate,
                seqOfMotion,
                caller
            );
        } else {
            _gk.getGMM().transferFund(
                to,
                isCBP,
                amt,
                expireDate,
                seqOfMotion,
                caller
            );
        }

        if (!isCBP) {
            _gk.getCashier().transferUsd(to, amt, bytes32(seqOfMotion));
        }
    }
}
