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


import "../InterfacesHub.sol";
import "../utils/RoyaltyCharge.sol";
import "../books/PledgesRepo.sol";

library ROPKeeper {
    using PledgesRepo for bytes32;
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // uint32(uint(keccak256("ROPKeeper")));
    uint public constant TYPE_OF_DOC = 0x4fcfb5a7;
    uint public constant VERSION = 1;

    // #######################
    // ##   Error & Event   ##
    // #######################

    error ROPK_NotVerified(bytes32 reason);

    error ROPK_WrongParty(bytes32 reason);

    error ROPK_ShareLocked(bytes32 reason);


    function _pledgerIsVerified(
        address _gk,
        uint pledgor
    ) private view {
        if (_gk.getROI().getInvestor(pledgor).state != 
            uint8(InvestorsRepo.StateOfInvestor.Approved)) {
            revert ROPK_NotVerified(bytes32("ROPK_PledgorNotVerified"));
        }
        if (!_gk.getSHA().isSigner(pledgor)) {
            revert ROPK_NotVerified(bytes32("ROPK_ShaNotSignedByPledgor"));
        }
    }

    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION, 66000
        );

        IRegisterOfShares _ros = _gk.getROS();

        PledgesRepo.Head memory head = snOfPld.snParser();
        
        head.pledgor = _ros.getShare(head.seqOfShare).head.shareholder;

        if (head.pledgor != caller) {
            revert ROPK_WrongParty(bytes32("ROPK_NotPledgor"));
        }

        if (!_ros.notLocked(head.seqOfShare, block.timestamp)) {
            revert ROPK_ShareLocked(bytes32("ROPK_ShareLocked"));
        }

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
        uint amt
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION, 88000
        );
        _gk.getROP().transferPledge(seqOfShare, seqOfPld, buyer, amt, caller);
    }

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION, 36000
        );

        PledgesRepo.Pledge memory pld = 
            _gk.getROP().refundDebt(seqOfShare, seqOfPld, amt, caller);

        _gk.getROS().increaseCleanPaid(seqOfShare, pld.body.paid);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION, 18000
        );
        _gk.getROP().extendPledge(seqOfShare, seqOfPld, extDays, caller);    
    }

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(
            TYPE_OF_DOC, VERSION, 58000
        );
        _gk.getROP().lockPledge(seqOfShare, seqOfPld, hashLock, caller);
    }

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey
    ) external {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);

        uint64 paid = _gk.getROP().releasePledge(seqOfShare, seqOfPld, hashKey);
        _gk.getROS().increaseCleanPaid(seqOfShare, paid);
    }

    function execPledge(
        uint seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint groupOfBuyer
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 88000);

        _pledgerIsVerified(_gk, buyer);

        IRegisterOfPledges _rop = _gk.getROP();
        _rop.execPledge(seqOfShare, seqOfPld, caller);

        PledgesRepo.Pledge memory pld = 
            _rop.getPledge(seqOfShare, seqOfPld);

        IRegisterOfShares _ros = _gk.getROS();
        IRegisterOfMembers _rom = _gk.getROM();

        if (!_ros.notLocked(pld.head.seqOfShare, block.timestamp)) {
            revert ROPK_ShareLocked(bytes32("ROPK_ShareLocked"));
        }
        
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
        uint256 seqOfPld
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);
        
        IRegisterOfPledges _rop = _gk.getROP();

        PledgesRepo.Pledge memory pld = _rop.getPledge(seqOfShare, seqOfPld);
        if (pld.head.pledgor != caller) {
            revert ROPK_WrongParty(bytes32("ROPK_NotPledgor"));
        }

        if (!_gk.getROS().notLocked(pld.head.seqOfShare, block.timestamp)) {
            revert ROPK_ShareLocked(bytes32("ROPK_ShareLocked"));
        }

        _rop.revokePledge(seqOfShare, seqOfPld, caller);
        _gk.getROS().increaseCleanPaid(seqOfShare, pld.body.paid);   
        
    }
}
