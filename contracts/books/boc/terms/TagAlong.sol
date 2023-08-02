// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

// import "../../../common/ruting/BOGSetting.sol";

import "./DragAlong.sol";

contract TagAlong is DragAlong {
    using ArrayUtils for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;

    // #############
    // ##  写接口  ##
    // #############

    function isExempted(address ia, DealsRepo.Deal memory deal) external view returns (bool) {        
        IMeetingMinutes _gmm = _getGK().getGMM();

        uint seqOfMotion = _getGK().getBOI().getHeadOfFile(ia).seqOfMotion;

        require(_gmm.isPassed(seqOfMotion), "motion NOT passed");

        if (!isTriggered(ia, deal)) return true;

        // uint seqOfMotion = _getGK().getBOI().getHeadOfFile(ia).seqOfMotion;

        uint256[] memory consentParties = _gmm.getCaseOfAttitude(
            seqOfMotion,
            1
        ).voters;

        uint256[] memory signers = ISigPage(ia).getParties();

        uint256[] memory agreedParties = consentParties.merge(signers);

        uint256[] memory rightholders = _repo.links[deal.head.seller].followers.values();

        return rightholders.fullyCoveredBy(agreedParties);

    }
}
