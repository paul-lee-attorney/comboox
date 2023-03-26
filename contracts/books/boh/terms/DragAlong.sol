// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/ruting/BOASetting.sol";
import "../../../common/ruting/ROMSetting.sol";

import "../../../common/lib/RulesParser.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/lib/SharesRepo.sol";

import "../../../common/components/IRepoOfDocs.sol";
import "../../../common/access/AccessControl.sol";

import "./IAlongs.sol";

contract DragAlong is IAlongs, BOASetting, ROMSetting, AccessControl {
    using RulesParser for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // drager => Drager
    mapping(uint256 => Drager) internal _dragers;
    EnumerableSet.UintSet private _dragersList;

    // ################
    // ##  modifier  ##
    // ################

    modifier dragerExist(uint256 drager) {
        require(_dragersList.contains(drager), "DA.mf.DE: drager not exist");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function createLink(uint256 rule, uint256 drager) external onlyAttorney {
        if (_dragersList.add(drager)) {
            _dragers[drager].linkRule = rule.linkRuleParser();
        }
    }

    function addFollower(uint256 drager, uint256 follower) external onlyAttorney {
        _dragers[drager].followers.add(follower);
    }

    function removeFollower(uint256 drager, uint256 follower)
        external
        onlyAttorney
    {
        _dragers[drager].followers.remove(follower);
    }

    function removeDrager(uint256 drager) external onlyAttorney {
        if (_dragersList.remove(drager)) {
            delete _dragers[drager];
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function linkRule(uint256 drager) external view returns (RulesParser.LinkRule memory) {
        return _dragers[drager].linkRule;
    }

    function isDrager(uint256 drager) external view returns (bool) {
        return _dragersList.contains(drager);
    }

    function isLinked(uint256 drager, uint256 follower)
        public
        view
        returns (bool)
    {
        return _dragers[drager].followers.contains(follower);
    }

    function dragers() external view returns (uint256[] memory) {
        return _dragersList.values();
    }

    function followers(uint256 drager) external view returns (uint256[] memory) {
        return _dragers[drager].followers.values();
    }

    function priceCheck(
        address ia,
        DealsRepo.Deal memory deal,
        SharesRepo.Share memory share,
        uint256 caller
    ) external view returns (bool) {
                
        if (!isTriggered(ia, deal)) return false;

        require(
            caller == deal.head.seller,
            "DA.PC: caller is not drager"
        );

        RulesParser.LinkRule memory lr = _dragers[caller].linkRule;

        if (
            lr.triggerType <
            uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)
        ) return true;

        if (
            lr.triggerType ==
            uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)
        ) {
            if (deal.head.priceOfPaid >= lr.unitPrice) return true;
            else return false;
        }

        if (
            _roeOfDeal(deal.head.priceOfPaid, share.head.price, deal.head.closingDate, share.head.issueDate) >=
            lr.roe
        ) return true;

        return false;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, DealsRepo.Deal memory deal) public view returns (bool) {
        
        if (_boa.getHeadOfDoc(ia).state != uint8(IRepoOfDocs.RODStates.Circulated))
            return false;

        if (
            deal.head.typeOfDeal ==
            uint8(DealsRepo.TypeOfDeal.CapitalIncrease) ||
            deal.head.typeOfDeal == uint8(DealsRepo.TypeOfDeal.PreEmptive)
        ) return false;

        if (!_dragersList.contains(deal.head.seller)) return false;

        RulesParser.LinkRule memory rule = _dragers[deal.head.seller].linkRule;

        if (rule.triggerType == uint8(TriggerTypeOfAlongs.NoConditions))
            return true;

        uint40 controllor = _rom.controllor();

        if (controllor != _rom.groupRep(deal.head.seller)) return false;

        (uint40 newControllor, uint16 shareRatio) = 
            _boa.mockResultsOfIA(ia);

        if (controllor != newControllor) return true;

        if (shareRatio <= rule.shareRatioThreshold) return true;

        return false;
    }

    function _roeOfDeal(
        uint32 dealPrice,
        uint32 issuePrice,
        uint48 closingDate,
        uint48 issueDateOfShare
    ) internal pure returns (uint32 roe) {
        require(dealPrice > issuePrice, "ROE: NEGATIVE selling price");
        require(closingDate > issueDateOfShare, "ROE: NEGATIVE holding period");

        uint32 deltaPrice = dealPrice - issuePrice;
        uint32 deltaDate = uint32(closingDate - issueDateOfShare);

        roe = (((deltaPrice * 10000) / issuePrice) * 31536000) / deltaDate;
    }
}
