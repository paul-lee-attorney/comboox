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

import "../../lib/InterfacesHub.sol";
import "../../lib/DocsRepo.sol";
import "../../lib/DealsRepo.sol";
import "../../lib/InvestorsRepo.sol";
import "../../lib/RulesParser.sol";
import "../../lib/SharesRepo.sol";

import "../../comps/common/access/IDraftControl.sol";
import "../../comps/common/components/IFilesFolder.sol";
import "../../comps/common/components/IMeetingMinutes.sol";
import "../../comps/common/components/ISigPage.sol";

import "../../comps/books/cashier/ICashier.sol";
import "../../comps/books/roa/IInvestmentAgreement.sol";
import "../../comps/books/roa/IRegisterOfAgreements.sol";
import "../../comps/books/roc/IShareholdersAgreement.sol";
import "../../comps/books/roc/terms/ILockUp.sol";
import "../../comps/books/rom/IRegisterOfMembers.sol";
import "../../comps/books/ros/IRegisterOfShares.sol";

/// @title IROAKeeper
/// @notice Interface for investment agreements and deal execution.
interface IROAKeeper {

    // #################
    // ##   Write IO  ##
    // #################

    /// @notice Create a new investment agreement.
    /// @param version Agreement version.
    function createIA(uint256 version) external;

    /// @notice Circulate an IA document for signature.
    /// @param ia Investment agreement address.
    /// @param docUrl Document URL hash.
    /// @param docHash Document content hash.
    function circulateIA(
        address ia,
        bytes32 docUrl,
        bytes32 docHash
    ) external;

    /// @notice Sign an IA document.
    /// @param ia Investment agreement address.
    /// @param sigHash Signature hash.
    function signIA(
        address ia,
        bytes32 sigHash
    ) external;

    // ==== Deal & IA ====

    /// @notice Push deal funds into coffer with hash lock.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @param hashLock Hash lock for closing.
    /// @param closingDeadline Closing deadline timestamp.
    function pushToCoffer(
        address ia,
        uint256 seqOfDeal,
        bytes32 hashLock,
        uint closingDeadline
    ) external;

    /// @notice Close a deal using hash key.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @param hashKey Hash key for closing.
    function closeDeal(
        address ia,
        uint256 seqOfDeal,
        string memory hashKey
    ) external;

    /// @notice Transfer target share per deal terms.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    function transferTargetShare(
        address ia,
        uint256 seqOfDeal
    ) external;

    /// @notice Issue new share for a deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    function issueNewShare(address ia, uint256 seqOfDeal) external;

    /// @notice Terminate a deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    function terminateDeal(
        address ia,
        uint256 seqOfDeal
    ) external;

    /// @notice Pay off an approved deal with transfer authorization.
    /// @param auth Transfer authorization.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @param to Recipient address.
    function payOffApprovedDeal(
        ICashier.TransferAuth memory auth, address ia, uint seqOfDeal,
        address to
    ) external;

}
