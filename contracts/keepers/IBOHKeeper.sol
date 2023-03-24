// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOHKeeper {
    // ############
    // ##  SHA   ##
    // ############

    function setTempOfBOH(address temp, uint8 typeOfDoc) external;

    function createSHA(uint8 typeOfDoc, uint256 caller) external;

    function removeSHA(address sha, uint256 caller) external;

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
