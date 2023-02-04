// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../common/components/ISigPage.sol";

interface IShareholdersAgreement is ISigPage {
    //##################
    //##    写接口    ##
    //##################

    function createTerm(uint8 title) external returns (address body);

    function removeTerm(uint8 title) external;

    function finalizeTerms() external;

    // ======== Rules ========
    function addRule(bytes32 rule) external;

    function removeRule(uint16 seq) external;

    function setBoardSeatsOf(uint40 nominator, uint8 quota) external;

    function addRightholderOfRule(uint16 seqOfRule, uint40 rightholder)
        external;

    function removeRightholderOfRule(uint16 seqOfRule, uint40 rightholder)
        external;

    // ==== GroupUpdateOrders ====

    function addOrder(bytes32 order) external;

    function delOrder(bytes32 order) external;

    //##################
    //##    读接口    ##
    //##################

    function hasTitle(uint8 title) external view returns (bool);

    function qtyOfTerms() external view returns (uint8);

    function titles() external view returns (uint8[] memory);

    function bodies() external view returns (address[] memory);

    function getTerm(uint8 title) external view returns (address);

    function termIsTriggered(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view returns (bool);

    function termIsExempted(
        uint8 title,
        address ia,
        bytes32 snOfDeal
    ) external view returns (bool);

    // ======== Rules ========

    function basedOnPar() external view returns (bool);

    function proposalThreshold() external view returns (uint16);

    function maxNumOfDirectors() external view returns (uint8);

    function tenureOfBoard() external view returns (uint8);

    function appointerOfOfficer(uint16 title) external view returns (uint40);

    function boardSeatsOf(uint40 acct) external view returns (uint8);

    function votingRules(uint16 typeOfVote) external view returns (bytes32);

    function additionalVetoholdersOfVR(uint16 typeOfVote)
        external
        view
        returns (uint40[] memory);

    // ==== FirstRefusal ====

    function isSubjectToFR(uint8 typeOfDeal) external view returns (bool);

    function ruleOfFR(uint8 typeOfDeal) external view returns (bytes32);

    function isRightholderOfFR(uint8 typeOfDeal, uint40 acct)
        external
        view
        returns (bool);

    function rightholdersOfFR(uint8 typeOfDeal)
        external
        view
        returns (uint40[] memory);

    // ==== GroupUpdateOrders ====

    function groupOrders() external view returns (bytes32[] memory);

    function lengthOfOrders() external view returns (uint256);
}
