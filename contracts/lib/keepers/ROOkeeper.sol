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

library ROOKeeper {
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // uint32(uint(keccak256("ROOKeeper")));
    uint public constant TYPE_OF_DOC = 0x3ac07862;
    uint public constant VERSION = 1;

    // #####################
    // ##  Error & Event  ##
    // #####################

    error ROOK_NotDK(bytes32 reason);

    error ROOK_ShareLocked(bytes32 reason);
    
    error ROOK_TargetLocked(bytes32 reason);

    error ROOK_WrongParty(bytes32 reason);

    event PayOffSwap(
        uint256 indexed seqOfOpt, uint256 indexed seqOfSwap, address indexed from, 
        address to, uint value
    );

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        if (IAccessControl(_gk).getDK() != msg.sender)
            revert ROOK_NotDK(bytes32("ROOK_NotDK"));

        _gk.getROO().updateOracle(seqOfOpt, d1, d2, d3);
    }

    function execOption(uint256 seqOfOpt) external {
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);
        address(this).getROO().execOption(seqOfOpt, caller);
    }

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        uint closingDate = _gk.getROO().getOption(seqOfOpt).body.closingDeadline;

        IRegisterOfOptions _roo = _gk.getROO(); 
        IRegisterOfShares _ros = _gk.getROS();

        if (!_ros.notLocked(seqOfTarget, closingDate))
            revert ROOK_ShareLocked(bytes32("ROOK_TargetLocked"));

        if (!_ros.notLocked(seqOfPledge, closingDate))
            revert ROOK_ShareLocked(bytes32("ROOK_PledgeLocked"));

        SwapsRepo.Swap memory swap = 
            _roo.createSwap(seqOfOpt, seqOfTarget, paidOfTarget, seqOfPledge, caller);

        _ros.decreaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        if (swap.isPutOpt)
            _ros.decreaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);        
    }

    function payOffSwap(
        ICashier.TransferAuth memory auth, 
        uint256 seqOfOpt, 
        uint256 seqOfSwap, 
        address to
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 40000);

        IRegisterOfShares _ros = _gk.getROS();
        SwapsRepo.Swap memory swap = 
            _gk.getROO().getSwap(seqOfOpt, seqOfSwap);

        uint seller = to.msgSender(TYPE_OF_DOC, VERSION, 18000);

        if (seller != _ros.getShare(swap.seqOfTarget).head.shareholder)
            revert ROOK_WrongParty(bytes32("ROOK_WrongPayee"));

        uint valueOfDeal = swap.paidOfTarget * swap.priceOfDeal / 100;

        auth.from = msg.sender;
        auth.value = valueOfDeal;

        // remark: PayOffSwap
        _gk.getCashier().forwardUsd(
            auth, 
            to, 
            bytes32(0x5061794f66665377617000000000000000000000000000000000000000000000)
        );
        emit PayOffSwap(seqOfOpt, seqOfSwap, msg.sender, to, auth.value);

        _payOffSwap(_gk, seqOfOpt, seqOfSwap, caller);
    }

    function _payOffSwap(
        address _gk, uint seqOfOpt, uint seqOfSwap, uint caller
    ) private {

        IRegisterOfShares _ros = _gk.getROS();

        SwapsRepo.Swap memory swap =
            _gk.getROO().payOffSwap(seqOfOpt, seqOfSwap);

        if (!_ros.notLocked(swap.seqOfTarget, block.timestamp))
            revert ROOK_TargetLocked(bytes32("ROOK_TargetLocked"));

        uint buyer = _ros.getShare(swap.seqOfPledge).head.shareholder;
        
        if (caller != buyer)
            revert ROOK_WrongParty(bytes32("ROOK_WrongPayer"));

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        _ros.transferShare(
            swap.seqOfTarget, swap.paidOfTarget, swap.paidOfTarget, 
            buyer, swap.priceOfDeal, swap.priceOfDeal
        );

        if (swap.isPutOpt) {
            _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);
        }
    }

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 58000);
    
        SwapsRepo.Swap memory swap = 
            _gk.getROO().terminateSwap(seqOfOpt, seqOfSwap);

        IRegisterOfShares _ros = _gk.getROS();
        uint seller = _ros.getShare(swap.seqOfTarget).head.shareholder;

        if(caller != seller)
            revert ROOK_WrongParty(bytes32("ROOK_NotSeller"));

        if(!_ros.notLocked(swap.seqOfPledge, block.timestamp))
            revert ROOK_ShareLocked(bytes32("ROOK_PledgeLocked"));

        _ros.increaseCleanPaid(swap.seqOfTarget, swap.paidOfTarget);
        
        if(swap.isPutOpt) {
            _ros.increaseCleanPaid(swap.seqOfPledge, swap.paidOfPledge);
            _ros.transferShare(swap.seqOfPledge, swap.paidOfPledge, swap.paidOfPledge, 
                seller, swap.priceOfDeal, swap.priceOfDeal);
        }
    }
}
