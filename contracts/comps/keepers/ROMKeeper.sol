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

pragma solidity ^0.8.8;

import "../common/access/RoyaltyCharge.sol";

import "./IROMKeeper.sol";

contract ROMKeeper is IROMKeeper, RoyaltyCharge {
    using InterfacesHub for address;

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        gk.getROM().setMaxQtyOfMembers(max);
    }

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) 
    external onlyDK {
        gk.getROS().setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey)
    external onlyDK {
        gk.getROS().requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        gk.getROS().withdrawPayInAmt(hashLock, seqOfShare);
    }

    function payInCapital(
        ICashier.TransferAuth memory auth,
        uint seqOfShare, 
        uint paid, 
        address msgSender
    ) external onlyDK {
        
        uint caller = _msgSender(msgSender, 36000);
        IRegisterOfShares _ros = gk.getROS();
        SharesRepo.Share memory share = _ros.getShare(seqOfShare);
        
        require(share.head.shareholder == caller,
            "UsdROMK.payInCap: not shareholder");

        auth.from = msgSender;
        auth.value = share.head.priceOfPaid * paid / 100;

        gk.getCashier().collectUsd(auth, bytes32("PayInCapital"));

        _ros.payInCapital(seqOfShare, paid);

        emit PayInCapital(seqOfShare, paid, auth.value);
    }

    function decreaseCapital(
        uint256 seqOfShare, 
        uint paid,
        uint par,
        uint amt
    ) external onlyDK {
        IRegisterOfShares _ros=gk.getROS();
        _ros.decreaseCapital(seqOfShare, paid, par);
        uint shareholder = _ros.getShare(seqOfShare).head.shareholder;
        gk.getCashier().depositUsd(shareholder, amt, bytes32("DecreaseCapital"));
    }

    function updatePaidInDeadline(
        uint256 seqOfShare, 
        uint line
    ) external onlyDK {
        gk.getROS().updatePaidInDeadline(seqOfShare, line);
    }

}
