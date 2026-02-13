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

import "../../common/components/ISigPage.sol";
import "../../../openzeppelin/utils/structs/EnumerableSet.sol";
import "../../../lib/DocsRepo.sol";

/// @notice Design notes:
/// - The implementation is created via BookOfDocs/DocsRepo `cloneDoc()` and is not upgradeable.
/// - `typeOfDoc` and `version` are validated in RegCenter/BookOfDocs/DocsRepo `cloneDoc()`.
/// - Overwrites during drafting are allowed by design; before finalization, contents are mutable.
/// - Finalization calls `lockContents()` (onlyOwner) and revokes the Attorneys role and Owner, so no further edits are possible.
/// - Drafting changes do not require on-chain state tracking; only finalized Terms/Rules are used by other registers.
/// - `finalizeSHA()` is intended to be triggered by the Owner after validation, then submitted to shareholder approval;
///   once effective, Terms/Rules serve as the ledger source for other contracts.
/// @title IShareholdersAgreement
/// @notice Interface for terms/rules registry in the Shareholders Agreement.
interface IShareholdersAgreement is ISigPage {

    enum TitleOfTerm {
        ZeroPoint,
        AntiDilution,   // 1
        LockUp,         // 2
        DragAlong,      // 3
        TagAlong,       // 4
        Options         // 5
    }

    // ==== Rules ========

/*
    |  Seq  |        Type       |    Abb       |            Description                     |       
    |    0  |  GovernanceRule   |     GR       | Board Constitution and General Rules of GM | 
    |    1  |  VotingRuleOfGM   |     CI       | VR for Capital Increase                    |
    |    2  |                   |   SText      | VR for External Share Transfer             |
    |    3  |                   |   STint      | VR for Internal Share Transfer             |
    |    4  |                   |    1+3       | VR for CI & STint                          |
    |    5  |                   |    2+3       | VR for SText & STint                       |
    |    6  |                   |   1+2+3      | VR for CI & SText & STint                  |
    |    7  |                   |    1+2       | VR for CI & SText                          |
    |    8  |                   |   SHA        | VR for Update SHA                          |
    |    9  |                   |  O-Issue-GM  | VR for Ordinary Issues of GeneralMeeting   |
    |   10  |                   |  S-Issue-GM  | VR for Special Issues Of GeneralMeeting    |
    |   11  | VotingRuleOfBoard |     CI       | VR for Capital Increase                    |
    |   12  |                   |   SText      | VR for External Share Transfer             |
    |   13  |                   |   STint      | VR for Internal Share Transfer             |
    |   14  |                   |    1+3       | VR for CI & STint                          |
    |   15  |                   |    2+3       | VR for SText & STint                       |
    |   16  |                   |   1+2+3      | VR for CI & SText & STint                  |
    |   17  |                   |    1+2       | VR for CI & SText                          |
    |   18  |                   |   SHA        | VR for Update SHA                          |
    |   19  |                   |  O-Issue-B   | VR for Ordinary Issues Of Board            |
    |   20  |                   |  S-Issue-B   | VR for Special Issues Of Board             |
    |   21  | UnilateralDecision| UniDecPower  | UnilateralDicisionPowerWithoutVoting       |
    ...

    |  256  | PositionAllocateRule |   PA Rule   | Management Positions' Allocation Rules    |
    ...

    |  512  | FirstRefusalRule  |  FR for CI...| FR rule for Investment Deal                |
    ...

    |  768  | GroupUpdateOrder  |  GroupUpdate | Grouping Members as per their relationship |
    ...

    |  1024 | ListingRule       |  ListingRule | Listing Rule for Share Issue & Transfer    |
    ...

*/

    struct TermsRepo {
        // typeOfDoc => body
        mapping(uint256 => address) terms;
        EnumerableSet.UintSet seqList;
    }

    struct RulesRepo {
        // seq => rule
        mapping(uint256 => bytes32) rules;
        EnumerableSet.UintSet seqList;
    }

    //##################
    //##     Write    ##
    //##################

    /**
     * @dev Create a clone contract as per the template type number (`typeOfDoc`) 
     * and its version number (`version`).
     * Note `typeOfDoc` and `version` shall be bigger than zero.
     */
    /// @notice Create a term clone by type and version.
    /// @param typeOfDoc Term type identifier (> 0).
    /// @param version Template version (> 0).
    function createTerm(uint typeOfDoc, uint version) external;

    /**
     * @dev Remove tracking of a clone contract from mapping as per its template 
     * type number (`typeOfDoc`). 
     */
    /// @notice Remove a term by type.
    /// @param typeOfDoc Term type identifier.
    function removeTerm(uint typeOfDoc) external;

    /**
     * @dev Add a pre-defined `rule` into the Rules Mapping (seqNumber => rule)
     * Note a sequence number (`seqNumber`) of the `rule` SHALL be able to be parsed by 
     * RuleParser library, and such `seqNumber` shall be used as the search key to 
     * retrieve the rule from the Rules Mapping.
     */
    /// @notice Add a rule by sequence.
    /// @param seqOfRule Rule sequence.
    /// @param rule Packed rule bytes32.
    function addRule(uint seqOfRule, bytes32 rule) external;

    /**
     * @dev Remove tracking of a rule from the Rules Mapping as per its sequence 
     * number (`seq`). 
     */
    /// @notice Remove a rule by sequence.
    /// @param seq Rule sequence.
    function removeRule(uint256 seq) external;

    /**
     * @dev Initiate the Shareholders Agreement with predefined default rules. 
     */
    /// @notice Initialize default rules.
    function initDefaultRules() external;

    /**
     * @dev Transfer special Roles having write authorities to address "Zero",
     * so as to fix the contents of the Shareholders Agreement avoiding any further 
     * revision by any EOA. 
     */
    /// @notice Finalize SHA and lock contents.
    function finalizeSHA() external;

    //################
    //##    Read    ##
    //################

    // ==== Terms ====
 
    /**
     * @dev Returns whether a specific Term numbered as `typeOfDoc` exist  
     * in the current Shareholders Agreemnt.
     */
    /// @notice Check if a term exists.
    /// @param typeOfDoc Term type identifier.
    /// @return True if exists.
    function hasTitle(uint256 typeOfDoc) external view returns (bool);

    /**
     * @dev Returns total quantities of Terms in the current 
     * Shareholders Agreemnt.
     */
    /// @notice Get number of terms.
    /// @return Term count.
    function qtyOfTerms() external view returns (uint256);

    /**
     * @dev Returns total quantities of Terms stiputed in the current 
     * Shareholders Agreemnt.
     */
    /// @notice Get term type list.
    /// @return Term type ids.
    function getTitles() external view returns (uint256[] memory);

    /**
     * @dev Returns the contract address of the specific Term  
     * numbered as `typeOfDoc` from the Terms Mapping of the Shareholders Agreemnt.
     */
    /// @notice Get term contract address.
    /// @param typeOfDoc Term type identifier.
    /// @return Term contract address.
    function getTerm(uint256 typeOfDoc) external view returns (address);

    // ==== Rules ====

    /**
     * @dev Returns whether a specific Rule numbered as `seq` exist  
     * in the current Shareholders Agreemnt.
     */    
    /// @notice Check if a rule exists.
    /// @param seq Rule sequence.
    /// @return True if exists.
    function hasRule(uint256 seq) external view returns (bool);

    /**
     * @dev Returns total quantities of Rules in the current 
     * Shareholders Agreemnt.
     */
    /// @notice Get number of rules.
    /// @return Rule count.
    function qtyOfRules() external view returns (uint256);

    /**
     * @dev Returns total quantities of Rules stiputed in the current 
     * Shareholders Agreemnt.
     */
    /// @notice Get rule sequence list.
    /// @return Rule ids.
    function getRules() external view returns (uint256[] memory);

    /**
     * @dev Returns the specific Rule numbered as `seq` from the Rules Mapping
     * of the Shareholders Agreemnt.
     */
    /// @notice Get a rule by sequence.
    /// @param seq Rule sequence.
    /// @return Packed rule bytes32.
    function getRule(uint256 seq) external view returns (bytes32);
}
