// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOAKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    function setTempOfIA(address temp, uint256 typeOfDoc) external;

    function createIA(uint256 typeOfDoc, uint256 caller) external;

    function removeIA(address ia, uint256 caller) external;

    function circulateIA(
        address ia,
        uint256 caller,
        bytes32 docUrl,
        bytes32 docHash
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
        uint48 closingDate,
        uint256 caller
    ) external;

    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey,
        uint256 caller
    ) external;

    function transferTargetShare(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external;

    function issueNewShare(address ia, uint256 seqOfDeal) external;

    function revokeDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        string memory hashKey
    ) external;

    function terminateDeal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller
    ) external;

}
