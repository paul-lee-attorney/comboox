// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

import "../common/access/AccessControl.sol";

import "./IROPKeeper.sol";

contract ROPKeeper is IROPKeeper, AccessControl {
    using PledgesRepo for bytes32;
    
    // ###################
    // ##   ROPKeeper   ##
    // ###################

    function _pledgerIsVerified(
        uint pledgor
    ) private view {
        require (_gk.getLOO().getInvestor(pledgor).state == 
            uint8(OrdersRepo.StateOfInvestor.Approved), 
            "ROPK.pledgorIsVerified: not");
    }

    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays,
        uint256 caller
    ) external onlyDK {
        
        IRegisterOfShares _ros = _gk.getROS();

        PledgesRepo.Head memory head = snOfPld.snParser();
        
        head.pledgor = _ros.getShare(head.seqOfShare).head.shareholder;

        require(head.pledgor == caller, "BOPK.createPld: NOT shareholder");

        require(_ros.notLocked(head.seqOfShare, block.timestamp),
            "ROPK.createPledge: target share locked");

        head = _gk.getROP().createPledge(
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
        uint256 caller
    ) external onlyDK {
        _gk.getROP().transferPledge(seqOfShare, seqOfPld, buyer, amt, caller);
    }

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        uint256 caller
    ) external onlyDK {
        

        PledgesRepo.Pledge memory pld = 
            _gk.getROP().refundDebt(seqOfShare, seqOfPld, amt, caller);

        _gk.getROS().increaseCleanPaid(seqOfShare, pld.body.paid);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        uint256 caller
    ) external onlyDK {
        _gk.getROP().extendPledge(seqOfShare, seqOfPld, extDays, caller);    
    }

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint256 caller
    ) external onlyDK {        
        _gk.getROP().lockPledge(seqOfShare, seqOfPld, hashLock, caller);    
    }

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey
    ) external onlyDK {
        

        uint64 paid = _gk.getROP().releasePledge(seqOfShare, seqOfPld, hashKey);
        _gk.getROS().increaseCleanPaid(seqOfShare, paid);
    }

    function execPledge(
        uint seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint groupOfBuyer,
        uint caller
    ) external onlyDK {

        _pledgerIsVerified(buyer);

        IRegisterOfPledges _rop = _gk.getROP();
        _rop.execPledge(seqOfShare, seqOfPld, caller);

        PledgesRepo.Pledge memory pld = 
            _rop.getPledge(seqOfShare, seqOfPld);

        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();

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
        uint256 caller
    ) external onlyDK {
        
        IRegisterOfPledges _rop = _gk.getROP();

        PledgesRepo.Pledge memory pld = _rop.getPledge(seqOfShare, seqOfPld);
        require(pld.head.pledgor == caller, "BOPK.RP: not pledgor");

        _rop.revokePledge(seqOfShare, seqOfPld, caller);
        _gk.getROS().increaseCleanPaid(seqOfShare, pld.body.paid);   
        
    }
}
