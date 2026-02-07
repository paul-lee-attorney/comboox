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

pragma solidity ^0.8.8;

import "../../common/components/ISigPage.sol";
import "../../../lib/EnumerableSet.sol";
import "../../../lib/DocsRepo.sol";

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
        // title => body
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
    function createTerm(uint typeOfDoc, uint version) external;

    /**
     * @dev Remove tracking of a clone contract from mapping as per its template 
     * type number (`typeOfDoc`). 
     */
    function removeTerm(uint typeOfDoc) external;

    /**
     * @dev Add a pre-defined `rule` into the Rules Mapping (seqNumber => rule)
     * Note a sequence number (`seqNumber`) of the `rule` SHALL be able to be parsed by 
     * RuleParser library, and such `seqNumber` shall be used as the search key to 
     * retrieve the rule from the Rules Mapping.
     */
    function addRule(uint seqOfRule, bytes32 rule) external;

    /**
     * @dev Remove tracking of a rule from the Rules Mapping as per its sequence 
     * number (`seq`). 
     */
    function removeRule(uint256 seq) external;

    /**
     * @dev Initiate the Shareholders Agreement with predefined default rules. 
     */
    function initDefaultRules() external;

    /**
     * @dev Transfer special Roles having write authorities to address "Zero",
     * so as to fix the contents of the Shareholders Agreement avoiding any further 
     * revision by any EOA. 
     */
    function finalizeSHA() external;

    //################
    //##    Read    ##
    //################

    // ==== Terms ====
 
    /**
     * @dev Returns whether a specific Term numbered as `title` exist  
     * in the current Shareholders Agreemnt.
     */
    function hasTitle(uint256 title) external view returns (bool);

    /**
     * @dev Returns total quantities of Terms in the current 
     * Shareholders Agreemnt.
     */
    function qtyOfTerms() external view returns (uint256);

    /**
     * @dev Returns total quantities of Terms stiputed in the current 
     * Shareholders Agreemnt.
     */
    function getTitles() external view returns (uint256[] memory);

    /**
     * @dev Returns the contract address of the specific Term  
     * numbered as `title` from the Terms Mapping of the Shareholders Agreemnt.
     */
    function getTerm(uint256 title) external view returns (address);

    // ==== Rules ====

    /**
     * @dev Returns whether a specific Rule numbered as `seq` exist  
     * in the current Shareholders Agreemnt.
     */    
    function hasRule(uint256 seq) external view returns (bool);

    /**
     * @dev Returns total quantities of Rules in the current 
     * Shareholders Agreemnt.
     */
    function qtyOfRules() external view returns (uint256);

    /**
     * @dev Returns total quantities of Rules stiputed in the current 
     * Shareholders Agreemnt.
     */
    function getRules() external view returns (uint256[] memory);

    /**
     * @dev Returns the specific Rule numbered as `seq` from the Rules Mapping
     * of the Shareholders Agreemnt.
     */
    function getRule(uint256 seq) external view returns (bytes32);
}
