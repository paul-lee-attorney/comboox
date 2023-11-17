// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS NOT FOR FREE AND IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.8;

import "../books/roc/IShareholdersAgreement.sol";
import "../books/roc/terms/ILockUp.sol";

import "../common/components/ISigPage.sol";

import "../../lib/OfficersRepo.sol";
import "../../lib/RulesParser.sol";
import "../../lib/DocsRepo.sol";

interface IROCKeeper {
    // ############
    // ##  SHA   ##
    // ############

    // function setTempOfBOH(address temp, uint8 typeOfDoc) external;

    function createSHA(uint version, address primeKeyOfCaller, uint caller) external;

    // function removeSHA(address sha, uint256 caller) external;

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash,
        uint256 caller
    ) external;

    function signSHA(
        address sha,
        bytes32 sigHash,
        uint256 caller
    ) external;

    function activateSHA(address sha, uint256 caller) external;

    function acceptSHA(bytes32 sigHash, uint256 caller) external;
}
