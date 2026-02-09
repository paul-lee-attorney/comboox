// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "../../comps/common/access/RoyaltyCharge.sol";

import "../../comps/keepers/IRORKeeper.sol";

contract FundRORKeeper is IRORKeeper, RoyaltyCharge {
    using InterfacesHub for address;

    function _gpOrManager(uint caller) private view{
        require(gk.getROM().isClassMember(caller, 1) ||
            gk.getROD().isDirector(caller),
            "FundRORK: not GP or Manager");
    }

    function addRedeemableClass(uint class, address msgSender) external onlyDK{
        uint caller = _msgSender(msgSender, 18000);
        _gpOrManager(caller);
        gk.getROR().addRedeemableClass(class);
    }

    function removeRedeemableClass(uint class, address msgSender) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);
        _gpOrManager(caller);
        gk.getROR().removeRedeemableClass(class);
    }

    function updateNavPrice(uint class, uint price, address msgSender) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);
        _gpOrManager(caller);
        require(price > 0, "FundRORK: zero navPrice");
        gk.getROR().updateNavPrice(class, price); 
    }

    function requestForRedemption(
        uint class, uint paid, address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        IRegisterOfMembers _rom = gk.getROM();
        IRegisterOfShares _ros = gk.getROS();
        IRegisterOfRedemptions _ror = gk.getROR();
        
        require(_rom.isClassMember(caller, class),
            "FundRORK: not class member");
        require(paid > 0, "FundRORK: zero paid");

        uint[] memory sharesInhand = 
            _rom.sharesInClass(caller, class);

        uint len = sharesInhand.length;

        while (len > 0 && paid > 0) {

            SharesRepo.Share memory share = 
                _ros.getShare(sharesInhand[len - 1]);
            len--;

            if (!_ros.notLocked(share.head.seqOfShare, block.timestamp)) {
                continue;
            }

            if (share.body.cleanPaid > 0) {

                uint redPaid;
                
                if (paid >= share.body.cleanPaid) {
                    redPaid = share.body.cleanPaid;
                } else {
                    redPaid = paid;
                }

                paid -= redPaid;
                _ros.decreaseCleanPaid(share.head.seqOfShare, redPaid);                
                _ror.requestForRedemption(caller, class, share.head.seqOfShare, redPaid);

            }
        }

    }

    function redeem(uint class, uint seqOfPack, address msgSender) external onlyDK {
        
        uint caller = _msgSender(msgSender, 18000);
        _gpOrManager(caller);

        (RedemptionsRepo.Request[] memory list, RedemptionsRepo.Request memory info) = 
            gk.getROR().redeem(class, seqOfPack);

        ICashier _cashier = gk.getCashier();
        IRegisterOfShares _ros = gk.getROS();

        require(info.value * 100 <= _cashier.balanceOfComp(), 
            "FundRORK: insufficient balance of Comp");

        _cashier.redeemClass(class, info.paid);

        uint len = list.length;
        while(len > 0) {
            RedemptionsRepo.Request memory request = list[len-1];

            _ros.increaseCleanPaid(request.seqOfShare, request.paid);
            _ros.decreaseCapital(request.seqOfShare, request.paid, request.paid);

            _cashier.depositUsd(
                request.value * 100, 
                request.shareholder,
                bytes32("RedeemShare")
            );

            len--;
        }

    }

}
