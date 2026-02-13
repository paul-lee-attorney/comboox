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

import "../common/access/RoyaltyCharge.sol";

import "./ISHAKeeper.sol";
import "../../lib/LibOfSHAK.sol";

contract SHAKeeper is ISHAKeeper, RoyaltyCharge {
    using LibOfSHAK for uint256;

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        bytes32 snOfClaim,
        bytes32 sigHash
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 88000);
        caller.execAlongRight(ia, snOfClaim, sigHash);
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 36000);        
        caller.acceptAlongDeal(ia, seqOfDeal, sigHash);
    }

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 88000);
        caller.execAntiDilution(ia, seqOfDeal, seqOfShare, sigHash);        
    }

    function takeGiftShares(
        address ia,
        uint256 seqOfDeal
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 58000);
        caller.takeGiftShares(ia, seqOfDeal);
    }

    function execFirstRefusal(
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 88000);
        caller.execFirstRefusal(seqOfFRRule, seqOfRightholder, ia, seqOfDeal, sigHash);
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external  onlyGKProxy {
        uint caller = _msgSender(msg.sender, 18000);
        caller.computeFirstRefusal(ia, seqOfDeal);
    }
}
