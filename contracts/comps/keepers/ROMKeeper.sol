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

import "../common/access/RoyaltyCharge.sol";

import "./IROMKeeper.sol";

contract ROMKeeper is IROMKeeper, RoyaltyCharge {

    // ###################
    // ##   ROMKeeper   ##
    // ###################

    function setMaxQtyOfMembers(uint max) external onlyDK {
        _gk.getROM().setMaxQtyOfMembers(max);
    }

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) 
    external onlyDK {
        _gk.getROS().setPayInAmt(seqOfShare, amt, expireDate, hashLock);
    }

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey)
    external onlyDK {
        _gk.getROS().requestPaidInCapital(hashLock, hashKey);
    }

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external onlyDK {
        _gk.getROS().withdrawPayInAmt(hashLock, seqOfShare);
    }

    function payInCapital(
        uint seqOfShare, 
        uint amt,
        uint msgValue,
        address msgSender
    ) external onlyDK {
        
        uint caller = _msgSender(msgSender, 36000);

        IRegisterOfShares _ros = _gk.getROS();

        SharesRepo.Share memory share =
            _ros.getShare(seqOfShare);

        uint centPrice = _gk.getCentPrice();
        uint valueOfDeal = amt * centPrice / 100;
        
        require(share.head.shareholder == caller,
            "ROMK.payInCap: not shareholder");
        require(valueOfDeal <= msgValue,
            "ROMK.payInCap: insufficient amt");
        
        msgValue -= valueOfDeal;
        if (msgValue > 0) {
            _gk.saveToCoffer(
                caller, msgValue, 
                bytes32(0x4465706f73697442616c616e63654f66506179496e4361700000000000000000)
            ); // reason: DepositBalanceOfPayInCap 
        }

        _ros.payInCapital(seqOfShare, amt);
        emit PayInCapital(seqOfShare, amt, valueOfDeal);
    }

    function decreaseCapital(
        uint256 seqOfShare, 
        uint paid, 
        uint par
    ) external onlyDK {
        _gk.getROS().decreaseCapital(seqOfShare, paid, par);
    }

    function updatePaidInDeadline(
        uint256 seqOfShare, 
        uint line
    ) external onlyDK {
        _gk.getROS().updatePaidInDeadline(seqOfShare, line);
    }

}
