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

library ROMKeeper {
    using InterfacesHub for address;
    using RoyaltyCharge for address;

    // = uint32(uint(keccak256("ROMKeeper")));
    uint public constant TYPE_OF_DOC = 0xa223ca65;
    uint public constant VERSION = 1;

    // ######################
    // ##   Error & Event  ##
    // ######################

    error ROMK_NotDK(bytes32 reason);

    error ROMK_NotShareholder(bytes32 reason);

    event PayInCapital(uint seqOfShare, uint paid, uint amt);

    modifier onlyDK() {
        if(msg.sender != IAccessControl(address(this)).getDK())
            revert ROMK_NotDK(bytes32("ROMK_NotDK"));
        _;
    }

    function setMaxQtyOfMembers(uint max) external onlyDK  {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _gk.getROM().setMaxQtyOfMembers(max);
    }

    function setPayInAmt(
        uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock
    ) external onlyDK  {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _gk.getROS().setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(
        bytes32 hashLock, string memory hashKey
    ) external  {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _gk.getROS().requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(
        bytes32 hashLock, uint seqOfShare
    ) external onlyDK {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _gk.getROS().withdrawPayInAmt(hashLock, seqOfShare);
    }

    function payInCapital(
        ICashier.TransferAuth memory auth,
        uint seqOfShare, 
        uint paid
    ) external {
        address _gk = address(this);        
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 36000);

        IRegisterOfShares _ros = _gk.getROS();
        SharesRepo.Share memory share = _ros.getShare(seqOfShare);
        
        if(share.head.shareholder != caller)
            revert ROMK_NotShareholder(bytes32("ROMK_NotShareholder"));

        auth.from = msg.sender;
        auth.value = share.head.priceOfPaid * paid / 100;

        _gk.getCashier().collectUsd(auth, bytes32("PayInCapital"));

        _ros.payInCapital(seqOfShare, paid);

        emit PayInCapital(seqOfShare, paid, auth.value);
    }

    function decreaseCapital(
        uint seqOfVR, uint256 seqOfShare, 
        uint paid, uint par, uint amt,
        uint seqOfMotion
    ) external {
        address _gk = address(this);
        uint caller = msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _gk.getGMM().decreaseCapital(
            seqOfVR, seqOfShare, paid, par, amt, seqOfMotion, caller
        );
        IRegisterOfShares _ros=_gk.getROS();
        uint shareholder = _ros.getShare(seqOfShare).head.shareholder;
        _ros.decreaseCapital(seqOfShare, paid, par);
        _gk.getCashier().depositUsd(shareholder, amt, bytes32("DecreaseCapital"));
    }

    function updatePaidInDeadline(
        uint256 seqOfShare, 
        uint line
    ) external onlyDK {
        address _gk = address(this);
        msg.sender.msgSender(TYPE_OF_DOC, VERSION, 18000);

        _gk.getROS().updatePaidInDeadline(seqOfShare, line);
    }

}
