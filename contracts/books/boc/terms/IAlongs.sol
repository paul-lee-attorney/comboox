// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/lib/ArrayUtils.sol";
import "../../../common/lib/DealsRepo.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/SharesRepo.sol";
import "../../../common/lib/RulesParser.sol";

import "../../../common/components/IFilesFolder.sol";
import "../../../books/bom/IBookOfMembers.sol";

interface IAlongs {

    enum TriggerTypeOfAlongs {
        NoConditions,
        ControlChanged,
        ControlChangedWithHigherPrice,
        ControlChangedWithHigherROE
    }

    struct Link {
        EnumerableSet.UintSet followers;
        RulesParser.LinkRule linkRule;
    }

    struct DraggersRepo {        
        // drager => Link
        mapping(uint256 => Link) links;
        EnumerableSet.UintSet  draggersList;
    }

    // ################
    // ##   Write    ##
    // ################

    function createLink(bytes32 rule, uint256 drager) external;

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
