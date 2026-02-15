// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
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

pragma solidity ^0.8.24;

/// @title IROCKeeper
/// @notice Interface for shareholder agreement lifecycle actions.
interface IROCKeeper {

    // ############
    // ##  SHA   ##
    // ############

    /// @notice Create a shareholder agreement.
    /// @param version Agreement version.
    function createSHA(uint version) external;

    /// @notice Circulate SHA document for signature.
    /// @param sha Shareholders agreement address.
    /// @param docUrl Document URL hash.
    /// @param docHash Document content hash.
    function circulateSHA(
        address sha,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    /// @notice Sign SHA document.
    /// @param sha Shareholders agreement address.
    /// @param sigHash Signature hash.
    function signSHA(
        address sha,
        bytes32 sigHash
    ) external;

    /// @notice Activate a SHA.
    /// @param sha Shareholders agreement address.
    function activateSHA(address sha) external;

    /// @notice Accept SHA with signature hash.
    /// @param sigHash Signature hash.
    function acceptSHA(bytes32 sigHash) external;
}
