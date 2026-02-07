// SPDX-License-Identifier: UNLICENSED

/* *
 *
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

import "./ICashier.sol";

import "../../common/access/RoyaltyCharge.sol";

contract Cashier is ICashier, RoyaltyCharge {
    using RulesParser for bytes32;
    using WaterfallsRepo for WaterfallsRepo.Repo;
    using BooksRepo for IBaseKeeper;

    mapping(address => uint) private _coffers;
    // userNo => balance
    mapping(uint => uint) private _lockers;

    WaterfallsRepo.Repo private _rivers;

    //###############
    //##   Write   ##
    //###############

    function _transferWithAuthorization(TransferAuth memory auth) private {
        gk.getBank().transferWithAuthorization(
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

        require(gk.getBank().transfer(to, auth.value),
            "Cashier.forwardUsd: transfer failed");
    }

    function custodyUsd(TransferAuth memory auth, bytes32 remark) external onlyKeeper {
        _transferWithAuthorization(auth);
        _coffers[auth.from] += auth.value;
        _coffers[address(0)] += auth.value;
        
        emit CustodyUsd(auth.from, auth.value, remark);
    }

    function releaseUsd(address from, address to, uint amt, bytes32 remark) external onlyKeeper {
        require(_coffers[from] >= amt,
            "Cashier.ReleaseUsd: insufficient amt");

        _coffers[from] -= amt;
        _coffers[address(0)] -= amt;

        emit ReleaseUsd(from, to, amt, remark);

        require(gk.getBank().transfer(to, amt),
            "Cashier.releaseUsd: transfer failed");
    }

    function transferUsd(address to, uint amt, bytes32 remark) external onlyKeeper {

        require(balanceOfComp() >= amt,
            "Cashier.transferUsd: insufficient amt");
        
        emit TransferUsd(to, amt, remark);

        require(gk.getBank().transfer(to, amt),
            "Cashier.transferUsd: transfer failed");        
    }

    // ==== Distribution ====

    function distrProfits(uint amt, uint seqOfDR) external onlyKeeper returns(
        WaterfallsRepo.Drop[] memory mlist
    ){
    
        require(balanceOfComp() >= amt,
            "Cashier.DistrUsd: insufficient amt");

        RulesParser.DistrRule memory rule =
            gk.getSHA().getRule(seqOfDR).DistrRuleParser();

        IRegisterOfMembers _rom = gk.getROM();

        IRegisterOfShares _ros = gk.getROS();
        WaterfallsRepo.Drop memory drop;

        if ( rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.ProRata)) {
            (drop, mlist, ) = _rivers.proRataDistr(amt, _rom, _ros, false);
        } else if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.IntFront)) {
            (drop, mlist, ) = _rivers.intFrontDistr(amt, _ros, rule);
        } else revert("Cashier: wrong type of distribution");

        emit DistrProfits(amt, seqOfDR, drop.seqOfDistr);
        _distrUsd(mlist, bytes32("DistrProfits"));
    }

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

        require(balanceOfComp() >= amt,
            "Cashier.DistrUsd: insufficient amt");

        RulesParser.DistrRule memory rule = 
            gk.getSHA().getRule(seqOfDR).DistrRuleParser();

        IRegisterOfMembers _rom = gk.getROM();
        IRegisterOfShares _ros = gk.getROS();
        WaterfallsRepo.Drop memory drop;

        if ( rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.ProRata)) {
            (drop, mlist, slist) = _rivers.proRataDistr(amt, _rom, _ros, true);
        } else if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.IntFront)) {
            (drop, mlist, slist) = _rivers.intFrontDistr(amt, _ros, rule);
        } else if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.PrinFront)) {
            (drop, mlist, slist) = _rivers.prinFrontDistr(amt, _ros, rule);
        } else if (rule.typeOfDistr == uint8(RulesParser.TypeOfDistr.HuddleCarry)) {
            (drop, mlist, slist) = _rivers.hurdleCarryDistr(amt, _ros, rule, fundManager);
        } else revert("Cashier: wrong type of distribution");

        emit DistrIncome(amt, seqOfDR, fundManager, drop.seqOfDistr);

        _distrUsd(mlist, bytes32("DistrIncome"));
    }

    function depositUsd(uint amt, uint user, bytes32 remark) external onlyKeeper{
        require(balanceOfComp() >= amt,
            "Cashier.depositUsd: insufficient amt");

        _depositUsd(user, amt, remark);
    }

    function _depositUsd(uint payee, uint amt, bytes32 remark) private {
        require(payee > 0, "Cashier.depositUsd: zero user");
        
        emit DepositUsd(amt, payee, remark);

        _lockers[payee] += amt;
        _lockers[0] += amt;
    }

    // ==== Pickup Deposit ====

    function pickupUsd() external {
        
        uint caller = _msgSender(msg.sender, 18000);
        uint value = _lockers[caller];

        if (value > 0) {

            _lockers[caller] = 0;
            _lockers[0] -= value;

            emit PickupUsd(msg.sender, caller, value);

            require(gk.getBank().transfer(msg.sender, value),
                "Cashier.PickupUsd: transfer failed");

        } else revert("Cashier.pickupDeposit: no balance");
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
        uint amt = gk.getBank().balanceOf(address(this));        
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
