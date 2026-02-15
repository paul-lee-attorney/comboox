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

import "../utils/RoyaltyCharge.sol";
import "../InterfacesHub.sol";

library FundRORKeeper {
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // uint32(uint(keccak256("FundRORKeeper")))
    uint constant public TYPE_OF_DOC = 0x7ecb1211;
    uint constant public VERSION = 1;

    //######################
    //##   Error & Event  ##
    //######################

    error FundRORK_WrongParty(bytes32 reason);

    error FundRORK_Overflow(bytes32 reason);

    error FundRORK_ZeroValue(bytes32 reason);

    modifier onlyDK() {
        if (msg.sender != IAccessControl(address(this)).getDK()) {
            revert FundRORK_WrongParty(bytes32("FundRORK_NotDK"));
        }
        _;
    }   

    function _gpOrManager(address _gk, uint caller) private view{
        if (!(_gk.getROM().isClassMember(caller, 1) ||
            _gk.getROD().isDirector(caller))) {
            revert FundRORK_WrongParty(bytes32("FundRORK_NotGPOrManager"));
        }
    }

    function addRedeemableClass(uint class) external onlyDK {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);
        _gpOrManager(_gk, caller);
        _gk.getROR().addRedeemableClass(class);
    }

    function removeRedeemableClass(uint class) external onlyDK  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);
        _gpOrManager(_gk, caller);
        _gk.getROR().removeRedeemableClass(class);
    }

    function updateNavPrice(uint class, uint price) external onlyDK  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);
        _gpOrManager(_gk, caller);
        if (price == 0) {
            revert FundRORK_ZeroValue(bytes32("FundRORK_ZeroPrice"));
        }
        _gk.getROR().updateNavPrice(class, price); 
    }

    function requestForRedemption(
        uint class, uint paid
    ) external onlyDK  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 88000);

        IRegisterOfMembers _rom = _gk.getROM();
        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfRedemptions _ror = _gk.getROR();
        
        if (!_rom.isClassMember(caller, class)) {
            revert FundRORK_WrongParty(bytes32("FundRORK_NotClassMember"));
        }
        if (paid == 0) {
            revert FundRORK_ZeroValue(bytes32("FundRORK_ZeroPaid"));
        }

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

    function redeem(uint class, uint seqOfPack) external onlyDK  {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _gpOrManager(_gk, caller);

        (RedemptionsRepo.Request[] memory list, RedemptionsRepo.Request memory info) = 
            _gk.getROR().redeem(class, seqOfPack);

        ICashier _cashier = _gk.getCashier();
        IRegisterOfShares _ros = _gk.getROS();

        if (info.value * 100 > _cashier.balanceOfComp()) {
            revert FundRORK_Overflow(bytes32("FundRORK_InsufficientBalance"));
        }

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
