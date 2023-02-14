// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
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

    // ==== Rules ====
    function addRule(bytes32 rule) external;

    function removeRule(uint16 seq) external;

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
        bytes32 snOfDeal
    ) external view returns (bool);

    function termIsExempted(
        uint256 title,
        address ia,
        bytes32 snOfDeal
    ) external view returns (bool);

    // ==== Rules ====
    
    function hasRule(uint256 seq) external view returns (bool);

    function qtyOfRules() external view returns (uint256);

    function rules() external view returns (uint256[] memory);

    function getRule(uint256 seq) external view returns (bytes32);
}
