// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../boa/IInvestmentAgreement.sol";
import "../../boa/InvestmentAgreement.sol";
import "../../boa/IMockResults.sol";

import "../../../common/ruting/ROMSetting.sol";
import "../../../common/ruting/BOSSetting.sol";
import "../../../common/ruting/BOASetting.sol";

import "../../../common/lib/SNParser.sol";
import "../../../common/lib/EnumerableSet.sol";
import "../../../common/components/RepoOfDocs.sol";

import "./IAlongs.sol";

contract DragAlong is IAlongs, ROMSetting, BOSSetting, BOASetting {
    using SNParser for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    enum TriggerTypeOfAlongs {
        NoConditions,
        ControlChanged,
        ControlChangedWithHigherPrice,
        ControlChangedWithHigherROE
    }

    // struct linkRule {
    //     uint40 drager;
    //     uint40 group;
    //     // 0-no condition; 1- not biggest || biggest but shareRatio < threshold; 2- 1 && price >= uintPrice; 3- 1 && roe >= ROE
    //     uint8 triggerType;
    //     // threshold to define material control party
    //     uint32 threshold;
    //     // false - free amount; true - pro rata (transfered parValue : original parValue)
    //     bool proRata;
    //     uint32 unitPrice;
    //     uint32 ROE;
    // }

    EnumerableSet.UintSet private _dragers;
    EnumerableSet.Bytes32Set private _rules;

    // rule => followers
    mapping(bytes32 => EnumerableSet.UintSet) internal _followers;

    // drager => rule
    mapping(uint256 => bytes32) internal _links;

    // ################
    // ##  modifier  ##
    // ################

    modifier dragerExist(uint40 drager) {
        require(_dragers.contains(drager), "WRONG drager ID");
        _;
    }

    // ################
    // ##   写接口   ##
    // ################

    function createLink(bytes32 rule, uint40 drager) external onlyAttorney {
        if (_dragers.add(drager) && _rules.add(rule)) {
            _links[drager] = rule;
        }
    }

    function addFollower(uint40 drager, uint40 follower) external onlyAttorney {
        _followers[_links[drager]].add(follower);
    }

    function removeFollower(uint40 drager, uint40 follower)
        external
        onlyAttorney
    {
        _followers[_links[drager]].remove(follower);
    }

    function removeDrager(uint40 drager) external onlyAttorney {
        if (_dragers.remove(drager)) {
            delete _links[drager];
        }
    }

    function delLink(bytes32 rule) external onlyAttorney {
        if (_rules.remove(rule)) {
            delete _followers[rule];
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function linkRule(uint40 drager) external view returns (bytes32) {
        return _links[drager];
    }

    function isDrager(uint40 drager) external view returns (bool) {
        return _dragers.contains(drager);
    }

    function isLinked(uint40 drager, uint40 follower)
        public
        view
        returns (bool)
    {
        return _followers[_links[drager]].contains(follower);
    }

    function dragers() external view returns (uint40[] memory) {
        return _dragers.valuesToUint40();
    }

    function followers(uint40 drager) external view returns (uint40[] memory) {
        return _followers[_links[drager]].valuesToUint40();
    }

    function priceCheck(
        address ia,
        bytes32 sn,
        bytes32 shareNumber,
        uint40 caller
    ) external view returns (bool) {
        if (!isTriggered(ia, sn)) return false;

        uint40 drager = sn.sellerOfDeal();

        require(
            caller == drager,
            "DA.priceCheck: caller is not drager of DragAlong"
        );

        require(
            isLinked(caller, shareNumber.shareholder()),
            "DA.PriceCheck: caller and target shareholder NOT linked"
        );

        uint32 dealPrice = sn.priceOfDeal();
        uint48 closingDate = IInvestmentAgreement(ia).closingDateOfDeal(
            sn.seqOfDeal()
        );

        bytes32 rule = _links[caller];

        if (
            rule.triggerTypeOfLink() <
            uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)
        ) return true;

        if (
            rule.triggerTypeOfLink() ==
            uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)
        ) {
            if (dealPrice >= rule.unitPriceOfLink()) return true;
            else return false;
        }

        uint32 issuePrice = shareNumber.issuePrice();
        uint48 issueDate = shareNumber.issueDate();

        if (
            _roeOfDeal(dealPrice, issuePrice, closingDate, issueDate) >=
            rule.roeOfLink()
        ) return true;

        return false;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, bytes32 sn) public view returns (bool) {
        if (_boa.currentState(ia) != uint8(RepoOfDocs.RODStates.Circulated))
            return false;

        if (
            sn.typeOfDeal() ==
            uint8(InvestmentAgreement.TypeOfDeal.CapitalIncrease) ||
            sn.typeOfDeal() == uint8(InvestmentAgreement.TypeOfDeal.PreEmptive)
        ) return false;

        uint40 seller = sn.sellerOfDeal();

        if (!_dragers.contains(seller)) return false;

        bytes32 rule = _links[seller];

        if (rule.triggerTypeOfLink() == uint8(TriggerTypeOfAlongs.NoConditions))
            return true;

        uint40 controllor = _rom.controllor();

        if (controllor != _rom.groupRep(seller)) return false;

        (uint40 newControllor, uint64 ratio) = IMockResults(
            _boa.mockResultsOfIA(ia)
        ).topGroup();

        if (controllor != newControllor) return true;

        if (ratio <= rule.thresholdOfLink()) return true;

        return false;
    }

    function _roeOfDeal(
        uint32 dealPrice,
        uint32 issuePrice,
        uint48 closingDate,
        uint48 issueDateOfShare
    ) internal pure returns (uint32 roe) {
        require(dealPrice > issuePrice, "NEGATIVE selling price");
        require(closingDate > issueDateOfShare, "NEGATIVE holding period");

        uint32 deltaPrice = dealPrice - issuePrice;
        uint32 deltaDate = uint32(closingDate - issueDateOfShare);

        roe = (((deltaPrice * 10000) / issuePrice) * 31536000) / deltaDate;
    }
}
