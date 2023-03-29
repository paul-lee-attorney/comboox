// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boh/terms/IAntiDilution.sol";
import "../books/boh/terms/ITerm.sol";
import "../books/boh/terms/IAlongs.sol";

import "../books/boh/IShareholdersAgreement.sol";

import "../books/boa/IInvestmentAgreement.sol";

import "../common/components/IFilesFolder.sol";
import "../common/components/ISigPage.sol";

import "../common/lib/RulesParser.sol";
import "../common/lib/SharesRepo.sol";
import "../common/lib/FRClaims.sol";

interface ISHAKeeper {

    // ======== TagAlong & DragAlong ========

    function execAlongRight(
        address ia,
        uint256 seqOfDeal,
        bool dragAlong,
        uint256 seqOfShare,
        uint64 paid,
        uint64 par,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function acceptAlongDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external;

    // ======== AntiDilution ========

    function execAntiDilution(
        address ia,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function takeGiftShares(
        address ia,
        uint256 seqOfDeal,
        uint40 caller
    ) external;

    // ======== FirstRefusal ========

    function execFirstRefusal(
        uint256 seqOfFRRule,
        uint256 seqOfRightholder,
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function acceptFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external;
}
