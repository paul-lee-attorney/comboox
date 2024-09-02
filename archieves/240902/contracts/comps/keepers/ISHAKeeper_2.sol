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

import "../books/roc/terms/IAntiDilution.sol";
import "../books/roc/terms/IAlongs.sol";

import "../books/roc/IShareholdersAgreement.sol";

import "../books/roa/IInvestmentAgreement.sol";

import "../common/components/IFilesFolder.sol";
import "../common/components/ISigPage.sol";

import "../../lib/RulesParser.sol";
import "../../lib/SharesRepo.sol";
import "../../lib/FRClaims.sol";

interface ISHAKeeper_2 {

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        uint256 seqOfDeal,
        bool dragAlong,
        uint256 seqOfShare,
        uint paid,
        uint par,
        address msgSender,
        bytes32 sigHash
    ) external;

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        address msgSender,
        bytes32 sigHash
    ) external;

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        address msgSender,
        bytes32 sigHash
    ) external;

    function takeGiftShares(
        address ia,
        uint256 seqOfDeal,
        address msgSender
    ) external;

    // ======== FirstRefusal ========

    function execFirstRefusal(
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        address msgSender,
        bytes32 sigHash
    ) external;

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        address msgSender
    ) external;
}
