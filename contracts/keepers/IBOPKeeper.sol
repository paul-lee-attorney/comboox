// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../common/lib/PledgesRepo.sol";
// import "../common/lib/SharesRepo.sol";
import "../common/lib/DealsRepo.sol";
import "../common/lib/DocsRepo.sol";
import "../common/lib/RulesParser.sol";

interface IBOPKeeper {
    // ###################
    // ##   BOPKeeper   ##
    // ###################
    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays,
        uint256 caller
    ) external;

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint256 caller        
    ) external;

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        uint256 caller
    ) external;

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        uint256 caller
    ) external;

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint256 caller
    ) external;

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey
    ) external;

    function execPledge(
        bytes32 snOfDeal,
        uint256 seqOfPld,
        uint version,
        address primeKeyOfCaller,
        uint buyer,
        uint groupOfBuyer,
        uint256 caller
    ) external;

    function revokePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld,
        uint256 caller
    ) external;

}
