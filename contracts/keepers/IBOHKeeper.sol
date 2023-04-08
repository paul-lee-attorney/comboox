// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boh/IShareholdersAgreement.sol";
import "../books/boh/terms/ILockUp.sol";

import "../common/components/ISigPage.sol";

import "../common/lib/OfficersRepo.sol";
import "../common/lib/RulesParser.sol";
import "../common/lib/DocsRepo.sol";

interface IBOHKeeper {
    // ############
    // ##  SHA   ##
    // ############

    // function setTempOfBOH(address temp, uint8 typeOfDoc) external;

    function createSHA(uint16 version, address primeKeyOfCaller, uint40 caller) external;

    // function removeSHA(address sha, uint256 caller) external;

    function circulateSHA(
        address sha,
        uint256 seqOfVR,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external;

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external;

    function effectiveSHA(address sha, uint256 caller) external;

    function acceptSHA(bytes32 sigHash, uint256 caller) external;
}
