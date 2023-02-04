// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IBOHKeeper {
    // ############
    // ##  SHA   ##
    // ############

    function setTempOfSHA(address temp, uint8 typeOfDoc) external;

    function setTermTemplate(uint8 title, address body) external;

    function createSHA(uint8 docType, uint40 caller) external;

    function removeSHA(address sha, uint40 caller) external;

    function circulateSHA(
        address sha,
        uint40 caller,
        bytes32 docHash
    ) external;

    function signSHA(
        address sha,
        uint40 caller,
        bytes32 sigHash
    ) external;

    function effectiveSHA(address sha, uint40 caller) external;

    function acceptSHA(bytes32 sigHash, uint40 caller) external;
}
