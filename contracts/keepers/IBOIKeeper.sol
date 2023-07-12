// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../books/boi/IInvestmentAgreement.sol";

import "../common/components/IFilesFolder.sol";
import "../common/components/ISigPage.sol";

import "../common/lib/DocsRepo.sol";
import "../common/lib/RulesParser.sol";
import "../common/lib/SharesRepo.sol";

interface IBOIKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    // function setTempOfIA(address temp, uint256 typeOfDoc) external;

    function createIA(uint256 version, address primeKeyOfCaller, uint caller) external;

    // function removeIA(address ia, uint256 caller) external;

    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external;

    function signIA(
        address ia,
        uint256 caller,
        bytes32 sigHash
    ) external;

    // ==== Deal & IA ====

    function pushToCoffer(
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline,
        uint256 caller
    ) external;

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external;

    function transferTargetShare(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external;

    function issueNewShare(address ia, uint256 seqOfDeal) external;

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external;

}
