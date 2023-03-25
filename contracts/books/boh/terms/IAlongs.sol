// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/lib/DealsRepo.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/SharesRepo.sol";
import "../../../common/lib/RulesParser.sol";

// import "../../boa/IInvestmentAgreement.sol";
// import "../../bos/IBookOfShares.sol";

interface IAlongs {

    enum TriggerTypeOfAlongs {
        NoConditions,
        ControlChanged,
        ControlChangedWithHigherPrice,
        ControlChangedWithHigherROE
    }

    struct Drager {
        EnumerableSet.UintSet followers;
        RulesParser.LinkRule linkRule;
    }

    // ################
    // ##   Write    ##
    // ################

    function createLink(uint256 rule, uint256 drager) external;

    function addFollower(uint256 drager, uint256 follower) external;

    function removeFollower(uint256 drager, uint256 follower) external;

    function removeDrager(uint256 drager) external;

    // ###############
    // ##  查询接口  ##
    // ###############

    function linkRule(uint256 drager) external view returns (RulesParser.LinkRule memory);

    function isDrager(uint256 drager) external view returns (bool);

    function isLinked(uint256 drager, uint256 follower)
        external
        view
        returns (bool);

    function dragers() external view returns (uint256[] memory);

    function followers(uint256 drager) external view returns (uint256[] memory);

    function priceCheck(
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint256 caller
    ) external view returns (bool);

    function isTriggered(address ia, DealsRepo.Deal memory deal) external view returns (bool);
}
