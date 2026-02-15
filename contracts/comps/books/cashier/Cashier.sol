// SPDX-License-Identifier: UNLICENSED

/* *
 *
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

import "./ICashier.sol";

import "../../../lib/utils/RoyaltyCharge.sol";
import "../../common/access/AccessControl.sol";

contract Cashier is ICashier, AccessControl {
    using RulesParser for bytes32;
    using WaterfallsRepo for WaterfallsRepo.Repo;
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // Custody balances by external account address (escrowed USD).
    mapping(address => uint) private _coffers;
    // Deposit balances by internal user number (pending pickups).
    mapping(uint => uint) private _lockers;

    // Waterfall distribution repository and accounting state.
    WaterfallsRepo.Repo private _rivers;

    // ==== UUPSUpgradable ====
    uint256[50] private __gap;


    //###############
    //##   Write   ##
    //###############

    // Pull USD from `auth.from` into this contract using authorization data.
    // `auth` carries the EIP-3009 style authorization parameters.
    function _transferWithAuthorization(TransferAuth memory auth) private {
        _gk.getBank().transferWithAuthorization(
            auth.from, 
            address(this), 
            auth.value,
            auth.validAfter, 
            auth.validBefore, 
            auth.nonce, 
            auth.v,
            auth.r,
            auth.s
        );
    }

    function initClass(uint class, uint principal) external onlyKeeper {
        WaterfallsRepo.Drop memory info =
            _rivers.initClass(class, principal * 100);
        emit InitClass(class, principal, info.distrDate);
    }

    function redeemClass(uint class, uint principal) external onlyKeeper {
        _rivers.redeemClass(class, principal * 100);
        emit RedeemClass(class, principal);
    }

    function collectUsd(TransferAuth memory auth, bytes32 remark) external onlyKeeper {
        _transferWithAuthorization(auth);
        emit ReceiveUsd(auth.from, auth.value, remark);
    }

    function forwardUsd(TransferAuth memory auth, address to, bytes32 remark) external onlyKeeper{
        _transferWithAuthorization(auth);
        emit ForwardUsd(auth.from, to, auth.value, remark);

        if (!_gk.getBank().transfer(to, auth.value)) {
            revert Cashier_TransferFailed(bytes32("Cashier_TransferFailed"));
        }
    }

    function custodyUsd(TransferAuth memory auth, bytes32 remark) external onlyKeeper {
        _transferWithAuthorization(auth);
        _coffers[auth.from] += auth.value;
        _coffers[address(0)] += auth.value;
        
        emit CustodyUsd(auth.from, auth.value, remark);
    }

    function releaseUsd(address from, address to, uint amt, bytes32 remark) external onlyKeeper {
        if(_coffers[from] < amt) {
            revert Cashier_Overflow("Cashier_InsufficientAmt");
        }

        _coffers[from] -= amt;
        _coffers[address(0)] -= amt;

        emit ReleaseUsd(from, to, amt, remark);

        if (!_gk.getBank().transfer(to, amt)) {
            revert Cashier_TransferFailed(bytes32("Cashier_TransferFailed"));
        }
    }

    function transferUsd(address to, uint amt, bytes32 remark) external onlyKeeper {

        if (balanceOfComp() < amt) {
            revert Cashier_Overflow(bytes32("Cashier_InsufficientAmt"));
        }
        
        emit TransferUsd(to, amt, remark);

        if (!_gk.getBank().transfer(to, amt)) {
            revert Cashier_TransferFailed(bytes32("Cashier_TransferFailed"));
        }
    }

    // ==== Distribution ====

    function distrProfits(uint amt, uint seqOfDR) external onlyKeeper returns(
        WaterfallsRepo.Drop[] memory mlist
    ){
    
        if (balanceOfComp() < amt) {
            revert Cashier_Overflow(bytes32("Cashier_InsufficientAmt"));
        }

        RulesParser.DistrRule memory rule =
            _gk.getSHA().getRule(seqOfDR).DistrRuleParser();

        IRegisterOfMembers _rom = _gk.getROM();

        IRegisterOfShares _ros = _gk.getROS();
        WaterfallsRepo.Drop memory drop;

        if ( rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.ProRata)) {
            (drop, mlist, ) = _rivers.proRataDistr(amt, _rom, _ros, false);
        } else if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.IntFront)) {
            (drop, mlist, ) = _rivers.intFrontDistr(amt, _ros, rule);
        } else revert Cashier_WrongState(bytes32("Cashier_WrongTypeOfDistr"));

        emit DistrProfits(amt, seqOfDR, drop.seqOfDistr);
        _distrUsd(mlist, bytes32("DistrProfits"));
    }

    // Book each distribution drop as a deposit for the member.
    // `mlist` is the list of drops to deposit; `remark` tags the ledger entry.
    function _distrUsd(WaterfallsRepo.Drop[] memory mlist, bytes32 remark) private {
        uint len = mlist.length;
        while (len > 0) {
            WaterfallsRepo.Drop memory drop = mlist[len-1];
            _depositUsd(drop.member, drop.income + drop.principal, remark);
            len--;
        }
    }

    function distrIncome(uint amt, uint seqOfDR, uint fundManager) external onlyKeeper 
        returns(WaterfallsRepo.Drop[] memory mlist, WaterfallsRepo.Drop[] memory slist){

        if (balanceOfComp() < amt) {
            revert Cashier_Overflow(bytes32("Cashier_ShortOfAmt"));
        }

        RulesParser.DistrRule memory rule = 
            _gk.getSHA().getRule(seqOfDR).DistrRuleParser();

        IRegisterOfMembers _rom = _gk.getROM();
        IRegisterOfShares _ros = _gk.getROS();
        WaterfallsRepo.Drop memory drop;

        if ( rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.ProRata)) {
            (drop, mlist, slist) = _rivers.proRataDistr(amt, _rom, _ros, true);
        } else if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.IntFront)) {
            (drop, mlist, slist) = _rivers.intFrontDistr(amt, _ros, rule);
        } else if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.PrinFront)) {
            (drop, mlist, slist) = _rivers.prinFrontDistr(amt, _ros, rule);
        } else if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.HuddleCarry)) {
            (drop, mlist, slist) = _rivers.hurdleCarryDistr(amt, _ros, rule, fundManager);
        } else revert Cashier_WrongState(bytes32("Cashier_WrongTypeOfDistr"));

        emit DistrIncome(amt, seqOfDR, fundManager, drop.seqOfDistr);

        _distrUsd(mlist, bytes32("DistrIncome"));
    }

    function depositUsd(uint amt, uint user, bytes32 remark) external onlyKeeper{
        if (balanceOfComp() < amt) {
            revert Cashier_Overflow(bytes32("Cashier_ShortOfAmt"));
        }

        _depositUsd(user, amt, remark);
    }

    // Credit `amt` USD to the internal deposit locker of `payee`.
    // `remark` is an accounting tag for the deposit event.
    function _depositUsd(uint payee, uint amt, bytes32 remark) private {
        if (payee == 0) {
            revert Cashier_WrongParty(bytes32("Cashier_ZeroPayee"));
        }
        
        emit DepositUsd(amt, payee, remark);

        _lockers[payee] += amt;
        _lockers[0] += amt;
    }

    // ==== Pickup Deposit ====

    function pickupUsd() external {
        
        uint caller = msg.sender.msgSender(0xa019f9ef, 1, 18000);
        uint value = _lockers[caller];

        if (value > 0) {

            _lockers[caller] = 0;
            _lockers[0] -= value;

            emit PickupUsd(msg.sender, caller, value);

            if (!_gk.getBank().transfer(msg.sender, value)) {
                revert Cashier_TransferFailed(bytes32("Cashier_TransferFailed"));
            }

        } else revert Cashier_Overflow(bytes32("Cashier_NoBalance"));
    }

    //##################
    //##   Read I/O   ##
    //##################

    function custodyOf(address acct) external view returns(uint) {
        return _coffers[acct];
    }

    function totalEscrow() external view returns(uint) {
        return _coffers[address(0)];
    }

    function totalDeposits() external view returns(uint) {
        return _lockers[0];
    }

    function depositOfMine(uint user) external view returns(uint) {
        return _lockers[user];
    }

    function balanceOfComp() public view returns(uint) {
        uint amt = _gk.getBank().balanceOf(address(this));        
        return amt - _coffers[address(0)] - _lockers[0];
    }

    // ==== Waterfalls Distribution ====

    // ---- Drop ----

    function getDrop(
        uint seqOfDistr, uint member, uint class, uint seqOfShare
    ) external view returns(WaterfallsRepo.Drop memory drop) {
        drop = _rivers.getDrop(seqOfDistr, member, class, seqOfShare);
    }

    // ---- Flow ----

    function getFlowInfo(
        uint seqOfDistr, uint member, uint class
    ) external view returns(WaterfallsRepo.Drop memory info) {
        info = _rivers.getFlowInfo(seqOfDistr, member, class);
    }

    function getDropsOfFlow(
        uint seqOfDistr, uint member, uint class
    ) external view returns(WaterfallsRepo.Drop[] memory list) {
        list = _rivers.getDropsOfFlow(seqOfDistr, member, class);
    }

    // ---- Creek ----

    function getCreekInfo(
        uint seqOfDistr, uint member
    ) external view returns(WaterfallsRepo.Drop memory info) {
        info = _rivers.getCreekInfo(seqOfDistr, member);
    }

    function getDropsOfCreek(
        uint seqOfDistr, uint member
    ) external view returns(WaterfallsRepo.Drop[] memory list) {
        list = _rivers.getDropsOfCreek(seqOfDistr, member);
    }

    // ---- Stream ----

    function getStreamInfo(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop memory info) {
        info = _rivers.getStreamInfo(seqOfDistr);
    }

    function getCreeksOfStream(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop[] memory list) {
        list = _rivers.getCreeksOfStream(seqOfDistr);
    }

    function getDropsOfStream(
        uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop[] memory list) {
        list = _rivers.getDropsOfStream(seqOfDistr);
    }

    // ---- Member ----

    function getPoolInfo(
        uint member, uint class
    ) external view returns(WaterfallsRepo.Drop memory drop) {
        drop = 
            _rivers.getPoolInfo(member, class);
    }

    function getLakeInfo(
        uint member
    ) external view returns(WaterfallsRepo.Drop memory drop) {
        drop = 
            _rivers.getLakeInfo(member);
    }

    // ==== Waterfalls Class ====

    function getInitSeaInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info) {
        info = _rivers.getInitSeaInfo(class);
    }

    function getSeaInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info) {
        info = _rivers.getSeaInfo(class);
    }

    function getGulfInfo(
        uint class
    ) external view returns(WaterfallsRepo.Drop memory info) {
        info = _rivers.getGulfInfo(class);
    }

    function getIslandInfo(
        uint class, uint seqOfDistr
    ) external view returns(WaterfallsRepo.Drop memory info) {
        info = _rivers.getIslandInfo(class, seqOfDistr);
    }

    function getListOfClasses() external view returns(
        uint[] memory list
    ) {
        list = _rivers.getListOfClasses();
    }

    function getAllSeasInfo() external view returns(
        WaterfallsRepo.Drop[] memory list
    ) {
        list = _rivers.getAllSeasInfo();
    }

    // ==== Waterfalls Sum ====

    function getOceanInfo() external view returns(
        WaterfallsRepo.Drop memory info
    ) {
        info = _rivers.getOceanInfo();
    }

}
