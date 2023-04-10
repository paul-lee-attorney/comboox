// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./terms/ITerm.sol";
import "../../books/boa/IInvestmentAgreement.sol";
import "../../common/components/ISigPage.sol";
import "../../common/lib/EnumerableSet.sol";

interface IShareholdersAgreement {

    // enum TypeOfDoc {
    //      ...
    //     AntiDilution,    22
    //     DragAlong,       23
    //     LockUp,          24
    //     Options          25
    //     TagAlong,        26
    // }

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

    |  1024  | LinkRule  |  DragAlong/TagAlong | Dragging Rules for DragAlong / TagAlong right |
    ...

    |  1280  | AntiDilution  |  PriceBenchMarks | Price benchmarks for specific class with AntiDilution rights|
    ...

*/

    struct TermsRepo {
        // title => body
        mapping(uint256 => address) terms;
        EnumerableSet.UintSet seqList;
    }

    struct RulesRepo {
        // seq => rule
        mapping(uint256 => uint256) rules;
        EnumerableSet.UintSet seqList;
    }

    //##################
    //##    写接口     ##
    //##################

    function createTerm(uint typeOfDoc, uint version) external returns (address body);

    function removeTerm(uint typeOfDoc) external;

    // ==== Rules ====
    function addRule(uint256 rule) external;

    function removeRule(uint256 seq) external;

    //##################
    //##    读接口    ##
    //##################

    // ==== Terms ====

    function hasTitle(uint256 title) external view returns (bool);

    function qtyOfTerms() external view returns (uint256);

    function titles() external view returns (uint256[] memory);

    function getTerm(uint256 title) external view returns (address);

    function termIsTriggered(
        uint256 title,
        address ia,
        uint256 seqOfDeal
    ) external view returns (bool);

    function termIsExempted(
        uint256 title,
        address ia,
        uint256 seqOfDeal
    ) external view returns (bool);

    // ==== Rules ====
    
    function hasRule(uint256 seq) external view returns (bool);

    function qtyOfRules() external view returns (uint256);

    function rules() external view returns (uint256[] memory);

    function getRule(uint256 seq) external view returns (uint256);
}
