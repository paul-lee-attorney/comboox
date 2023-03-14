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

    function setTempOfBOH(address temp, uint256 typeOfDoc) external;

    function createSHA(uint256 typeOfDoc, uint256 caller) external;

    function removeSHA(address sha, uint256 caller) external;

    function circulateSHA(
        address sha,
        uint256 caller,
        uint256 seqOfVR,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    function signSHA(
        address sha,
        uint256 caller,
        bytes32 sigHash
    ) external;

    function effectiveSHA(address sha, uint256 caller) external;

    function acceptSHA(bytes32 sigHash, uint256 caller) external;
}
