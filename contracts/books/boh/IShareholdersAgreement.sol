// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/ISigPage.sol";

interface IShareholdersAgreement {

    enum TermTitle {
        ZeroPoint, //            0
        LockUp, //              1
        AntiDilution, //        2
        DragAlong, //           3
        TagAlong, //            4
        Options //               5
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
    ...

    |  256  |  BoardSeatsRule   |      BSR     | Board Seats Allocation Rights to Members   |
    ...

    |  512  | FirstRefusalRule  |  FR for CI...| FR rule for Investment Deal                |
    ...

    |  768  | GroupUpdateOrder  |  GroupUpdate | Grouping Members as per their relationship |
    ...

    |  1024  | LinkRule  |  GroupUpdate | Grouping Members as per their relationship |
    ...

*/

    //##################
    //##    写接口     ##
    //##################

    function createTerm(uint8 title) external returns (address body);

    function removeTerm(uint8 title) external;

    function finalizeTerms() external;

    // ==== Rules ====
    function addRule(bytes32 rule) external;

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
        uint256 snOfDeal
    ) external view returns (bool);

    function termIsExempted(
        uint256 title,
        address ia,
        uint256 snOfDeal
    ) external view returns (bool);

    // ==== Rules ====
    
    function hasRule(uint256 seq) external view returns (bool);

    function qtyOfRules() external view returns (uint256);

    function rules() external view returns (uint256[] memory);

    function getRule(uint256 seq) external view returns (bytes32);
}
