// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/ruting/BOGSetting.sol";

import "../../../common/lib/ArrayUtils.sol";

import "./DragAlong.sol";

contract TagAlong is BOGSetting, DragAlong {
    using ArrayUtils for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;
    // using ArrayUtils for uint40[];

    // #############
    // ##  写接口  ##
    // #############

    function isExempted(address ia, DealsRepo.Deal memory deal) external view returns (bool) {        
        require(_bog.isPassed(uint256(uint160(ia))), "motion NOT passed");

        if (!isTriggered(ia, deal)) return true;

        uint256[] memory consentParties = _bog.getCaseOfAttitude(
            uint256(uint160(ia)),
            1
        ).voters;

        uint256[] memory signers = ISigPage(ia).getParties();

        uint256[] memory agreedParties = consentParties.merge(signers);

        uint256[] memory rightholders = _dragers[deal.head.seller].followers.values();

        return rightholders.fullyCoveredBy(agreedParties);

    }
}
