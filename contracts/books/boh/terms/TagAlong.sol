// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa/IInvestmentAgreement.sol";

import "../../../common/ruting/BOMSetting.sol";
import "../../../common/ruting/BOASetting.sol";

import "../../../common/components/ISigPage.sol";

import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/SNParser.sol";

import "./DragAlong.sol";

contract TagAlong is DragAlong, BOMSetting {
    using EnumerableSet for EnumerableSet.UintSet;
    using SNParser for bytes32;

    // struct linkRule {
    //     uint40 drager;
    //     uint40 group;
    //     // 0-no condition; 1- biggest && shareRatio > threshold;
    //     uint8 triggerType;
    //     bool basedOnPar;
    //     // threshold to define material control party
    //     uint32 threshold;
    //     // false - free amount; true - pro rata (transfered parValue : original parValue)
    //     bool proRata;
    //     uint32 unitPrice;
    //     uint32 ROE;
    // }

    EnumerableSet.UintSet private _supporters;

    // #############
    // ##  写接口  ##
    // #############

    function _inputArray(uint40[] memory arr) private {
        uint256 len = arr.length;

        while (len != 0) {
            _supporters.add(arr[len - 1]);
            len--;
        }
    }

    function isExempted(address ia, bytes32 sn) external returns (bool) {
        require(_bog.isPassed(uint256(uint160(ia))), "motion NOT passed");

        if (!isTriggered(ia, sn)) return true;

        uint256 typeOfIA = IInvestmentAgreement(ia).typeOfIA();
        uint256 motionId = (typeOfIA << 160) + uint256(uint160(ia));

        uint40[] memory consentParties = _bog.getCaseOfAttitude(
            motionId,
            1
        ).voters;

        uint40[] memory signers = _boa.partiesOfDoc(ia);

        _supporters.emptyItems();

        _inputArray(consentParties);

        _inputArray(signers);

        uint40[] memory rightholders = _followers[_links[sn.sellerOfDeal()]]
            .valuesToUint40();

        uint256 len = rightholders.length;

        while (len != 0) {
            if (!_supporters.contains(rightholders[len - 1])) return false;
            len--;
        }

        return true;
    }
}
