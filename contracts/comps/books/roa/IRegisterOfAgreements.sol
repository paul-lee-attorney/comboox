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

import "../../common/components/IFilesFolder.sol";
import "./IInvestmentAgreement.sol";

import "../../../lib/DTClaims.sol";
import "../../../lib/FRClaims.sol";
import "../../../lib/TopChain.sol";
import "../../../lib/InterfacesHub.sol";

/// @title IRegisterOfAgreements
/// @notice Interface for claims handling and IA result mocking.
interface IRegisterOfAgreements is IFilesFolder {

    //#################
    //##    Event    ##
    //#################

    /// @notice Emitted when a first-refusal claim is submitted.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @param caller Claimer user number.
    event ClaimFirstRefusal(address indexed ia, uint256 indexed seqOfDeal, uint256 indexed caller);

    /// @notice Emitted when along claims are accepted for a deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    event AcceptAlongClaims(address indexed ia, uint indexed seqOfDeal);

    /// @notice Emitted when an along right is executed.
    /// @param ia Investment agreement address.
    /// @param snOfDTClaim Drag/tag claim serial number.
    /// @param sigHash Signature hash.
    event ExecAlongRight(address indexed ia, bytes32 indexed snOfDTClaim, bytes32 sigHash);

    /// @notice Emitted when first-refusal result is computed.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    event ComputeFirstRefusal(address indexed ia, uint256 indexed seqOfDeal);

    //#################
    //##  Write I/O  ##
    //#################

    // ======== RegisterOfAgreements ========

    /// @notice Submit a first-refusal claim for an IA deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @param caller Claimer user number.
    /// @param sigHash Signature hash.
    function claimFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external;

    /// @notice Compute first-refusal allocation ratios.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @return output Claims list with weights/ratios.
    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external returns (FRClaims.Claim[] memory output);

    /// @notice Execute drag/tag along right claim.
    /// @param ia Investment agreement address.
    /// @param snOfClaim Encoded claim head.
    // / @param dragAlong True for drag-along.
    // / @param seqOfDeal Deal sequence.
    // / @param seqOfShare Share sequence.
    // / @param paid Paid amount.
    // / @param par Par amount.
    // / @param caller Claimer user number.
    /// @param sigHash Signature hash.
    function execAlongRight(
        address ia,
        bytes32 snOfClaim,
        // bool dragAlong,
        // uint256 seqOfDeal,
        // uint256 seqOfShare,
        // uint paid,
        // uint par,
        // uint256 caller,
        bytes32 sigHash
    ) external;

    /// @notice Accept all along claims for a deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @return Claims list.
    function acceptAlongClaims(
        address ia, 
        uint seqOfDeal
    ) external returns(DTClaims.Claim[] memory);

    /// @notice Create mock results for an IA.
    /// @param ia Investment agreement address.
    function createMockOfIA(address ia) external;

    //################
    //##    Read    ##
    //################

    // ==== FR Claims ====

    /// @notice Check if FR claims exist for a deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @return True if exists.
    function hasFRClaims(address ia, uint seqOfDeal) external view returns (bool);

    /// @notice Check if account has any FR claim.
    /// @param ia Investment agreement address.
    /// @param acct User number.
    /// @return True if claimed.
    function isFRClaimer(address ia, uint256 acct) external returns (bool);

    /// @notice Get deal list with FR claims.
    /// @param ia Investment agreement address.
    /// @return Deal list.
    function getSubjectDealsOfFR(address ia) external view returns(uint[] memory);

    /// @notice Get FR claims of a deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @return Claims list.
    function getFRClaimsOfDeal(address ia, uint256 seqOfDeal)
        external view returns(FRClaims.Claim[] memory);

    /// @notice Check whether all FR claims are accepted.
    /// @param ia Investment agreement address.
    /// @return True if all accepted.
    function allFRClaimsAccepted(address ia) external view returns (bool);

    // ==== DT Claims ====

    /// @notice Check if DT claims exist for a deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @return True if exists.
    function hasDTClaims(address ia, uint256 seqOfDeal) 
        external view returns(bool);

    /// @notice Get deal list with DT claims.
    /// @param ia Investment agreement address.
    /// @return Deal list.
    function getSubjectDealsOfDT(address ia)
        external view returns(uint256[] memory);

    /// @notice Get DT claims of a deal.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @return Claims list.
    function getDTClaimsOfDeal(address ia, uint256 seqOfDeal)
        external view returns(DTClaims.Claim[] memory);

    /// @notice Get DT claim for a share.
    /// @param ia Investment agreement address.
    /// @param seqOfDeal Deal sequence.
    /// @param seqOfShare Share sequence.
    /// @return Claim record.
    function getDTClaimForShare(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external view returns(DTClaims.Claim memory);

    /// @notice Check whether all DT claims are accepted.
    /// @param ia Investment agreement address.
    /// @return True if all accepted.
    function allDTClaimsAccepted(address ia) external view returns(bool);

    // ==== Mock Results ====

    /// @notice Get mock results for IA.
    /// @param ia Investment agreement address.
    /// @return controllor Controller user number.
    /// @return ratio Ratio (0-10000).
    function mockResultsOfIA(address ia) 
        external view 
        returns (uint40 controllor, uint16 ratio);

    /// @notice Get mock results for account.
    /// @param ia Investment agreement address.
    /// @param acct User number.
    /// @return groupRep Group representative.
    /// @return ratio Ratio (0-10000).
    function mockResultsOfAcct(address ia, uint256 acct) 
        external view 
        returns (uint40 groupRep, uint16 ratio);

    // ==== AllClaimsAccepted ====

    /// @notice Check whether all claims are accepted.
    /// @param ia Investment agreement address.
    /// @return True if all accepted.
    function allClaimsAccepted(address ia) external view returns(bool);

}
