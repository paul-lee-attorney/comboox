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

import "../books/roc/terms/ILockUp.sol";

import "../common/components/ISigPage.sol";

import "../../lib/OfficersRepo.sol";
import "../../lib/RulesParser.sol";
import "../../lib/DocsRepo.sol";

interface IROCKeeper_2 {

    // ############
    // ##  SHA   ##
    // ############

    function createSHA(uint version, address msgSender) external;

    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash,
        address msgSender
    ) external;

    function signSHA(
        address sha,
        bytes32 sigHash,
        address msgSender
    ) external;

    function activateSHA(address sha, address msgSender) external;

    function acceptSHA(bytes32 sigHash, address msgSender) external;
}
