// SPDX-License-Identifier: UNLICENSED

/* *
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

import "../common/access/RoyaltyCharge.sol";

import "./IROPKeeper.sol";

contract ROPKeeper is IROPKeeper, RoyaltyCharge {
    using PledgesRepo for bytes32;
    using BooksRepo for IBaseKeeper;
    
    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function _pledgerIsVerified(
        uint pledgor
    ) private view {
        require (gk.getROI().getInvestor(pledgor).state == 
            uint8(InvestorsRepo.StateOfInvestor.Approved), 
            "ROPK: buyer not verified");
        require(gk.getSHA().isSigner(pledgor),
            "ROPK:buyer not signer of SHA");
    }

    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 66000);

        IRegisterOfShares _ros = gk.getROS();

        PledgesRepo.Head memory head = snOfPld.snParser();
        
        head.pledgor = _ros.getShare(head.seqOfShare).head.shareholder;

        require(head.pledgor == caller, "BOPK.createPld: NOT shareholder");

        require(_ros.notLocked(head.seqOfShare, block.timestamp),
            "ROPK.createPledge: target share locked");

        head = gk.getROP().createPledge(
            snOfPld,
            paid,
            par,
            guaranteedAmt,
            execDays
        );

        _ros.decreaseCleanPaid(head.seqOfShare, paid);
    }

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);
        gk.getROP().transferPledge(seqOfShare, seqOfPld, buyer, amt, caller);
    }

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 36000);        

        PledgesRepo.Pledge memory pld = 
            gk.getROP().refundDebt(seqOfShare, seqOfPld, amt, caller);

        gk.getROS().increaseCleanPaid(seqOfShare, pld.body.paid);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 18000);
        gk.getROP().extendPledge(seqOfShare, seqOfPld, extDays, caller);    
    }

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        address msgSender
    ) external onlyDK {        
        uint caller = _msgSender(msgSender, 58000);
        gk.getROP().lockPledge(seqOfShare, seqOfPld, hashLock, caller);    
    }

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey
    ) external onlyDK {
        uint64 paid = gk.getROP().releasePledge(seqOfShare, seqOfPld, hashKey);
        gk.getROS().increaseCleanPaid(seqOfShare, paid);
    }

    function execPledge(
        uint seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint groupOfBuyer,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 88000);

        _pledgerIsVerified(buyer);

        IRegisterOfPledges _rop = gk.getROP();
        _rop.execPledge(seqOfShare, seqOfPld, caller);

        PledgesRepo.Pledge memory pld = 
            _rop.getPledge(seqOfShare, seqOfPld);

        IRegisterOfShares _ros = gk.getROS();
        IRegisterOfMembers _rom = gk.getROM();

        require(_ros.notLocked(pld.head.seqOfShare, block.timestamp),
            "ROPK.createPledge: share locked");
        
        DealsRepo.Deal memory deal;

        deal.head.priceOfPaid = uint32(pld.body.guaranteedAmt * 10000 / pld.body.paid);
        deal.head.priceOfPar = uint32(pld.body.guaranteedAmt * 10000 / pld.body.par);

        deal.body.buyer = uint40(buyer);
        deal.body.groupOfBuyer = uint40(groupOfBuyer);

        _ros.increaseCleanPaid(pld.head.seqOfShare, pld.body.paid);
        _ros.transferShare(pld.head.seqOfShare, pld.body.paid, pld.body.par, 
            deal.body.buyer, deal.head.priceOfPaid, deal.head.priceOfPar);

        if (deal.body.buyer != deal.body.groupOfBuyer && 
            deal.body.groupOfBuyer != _rom.groupRep(deal.body.buyer)) {
                _rom.addMemberToGroup(deal.body.buyer, deal.body.groupOfBuyer);
        }

    }

    function revokePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        address msgSender
    ) external onlyDK {
        uint caller = _msgSender(msgSender, 58000);
        
        IRegisterOfPledges _rop = gk.getROP();

        PledgesRepo.Pledge memory pld = _rop.getPledge(seqOfShare, seqOfPld);
        require(pld.head.pledgor == caller, "BOPK.RP: not pledgor");

        _rop.revokePledge(seqOfShare, seqOfPld, caller);
        gk.getROS().increaseCleanPaid(seqOfShare, pld.body.paid);   
        
    }
}
