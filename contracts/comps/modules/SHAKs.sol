// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
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

import "../common/access/AccessControl.sol";

import "./ISHAKs.sol";

abstract contract SHAKs is ISHAKs, AccessControl{
    // using BooksRepo for IBaseKeeper;

    // ###################
    // ##   SHAKeeper   ##
    // ###################

    function _getSHAKeeper() private view returns(ISHAKeeper) {
        return ISHAKeeper(_gk.getKeeper(9));
    }

    // ======= TagAlong ========

    function execTagAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external{
        _getSHAKeeper().execAlongRight(
                ia,
                seqOfDeal,
                false,
                seqOfShare,
                paid,
                par,
                msg.sender,
                sigHash
            );
    }

    // ======= DragAlong ========

    function execDragAlong(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        bytes32 sigHash
    ) external{
        _getSHAKeeper().execAlongRight(
                ia,
                seqOfDeal,
                true,
                seqOfShare,
                paid,
                par,
                msg.sender,
                sigHash
            );
    }

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external{
        _getSHAKeeper().acceptAlongDeal(ia, seqOfDeal, msg.sender, sigHash);
    }

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        bytes32 sigHash
    ) external{
        _getSHAKeeper().execAntiDilution(ia, seqOfDeal, seqOfShare, msg.sender, sigHash);
    }

    function takeGiftShares(address ia, uint256 seqOfDeal) external{
        _getSHAKeeper().takeGiftShares(ia, seqOfDeal, msg.sender);
    }

    // ======== First Refusal ========

    function execFirstRefusal(
        uint256 seqOfRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        bytes32 sigHash
    ) external{
        _getSHAKeeper().execFirstRefusal(seqOfRule, seqOfRightholder, ia, seqOfDeal, msg.sender, sigHash);
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external{
        _getSHAKeeper().computeFirstRefusal(
                ia,
                seqOfDeal,
                msg.sender
            );
    }

}
