// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "../../../common/access/AccessControl.sol";

import "./IAlongs.sol";

contract DragAlong is IAlongs, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using RulesParser for bytes32;

    IGeneralKeeper private _gk = _getGK();
    IBookOfMembers private _bom = _gk.getBOM();
    IBookOfIA private _boi = _gk.getBOI();

    DraggersRepo internal _repo;

    // ################
    // ##  modifier  ##
    // ################

    modifier dragerExist(uint256 drager) {
        require(_repo.draggersList.contains(drager), "DA.mf.DE: drager not exist");
        _;
    }

    // ###############
    // ##   写接口   ##
    // ###############

    function createLink(bytes32 rule, uint256 drager) external onlyAttorney {
        if (_repo.draggersList.add(drager)) {
            _repo.links[drager].linkRule = rule.linkRuleParser();
        }
    }

    function addFollower(uint256 drager, uint256 follower) external onlyAttorney {
        _repo.links[drager].followers.add(follower);
    }

    function removeFollower(uint256 drager, uint256 follower)
        external
        onlyAttorney
    {
        _repo.links[drager].followers.remove(follower);
    }

    function removeDrager(uint256 drager) external onlyAttorney {
        if (_repo.draggersList.remove(drager)) {
            delete _repo.links[drager];
        }
    }

    // ################
    // ##  查询接口  ##
    // ################

    function linkRule(uint256 drager) external view returns (RulesParser.LinkRule memory) {
        return _repo.links[drager].linkRule;
    }

    function isDrager(uint256 drager) external view returns (bool) {
        return _repo.draggersList.contains(drager);
    }

    function isLinked(uint256 drager, uint256 follower)
        public view returns (bool)
    {
        RulesParser.LinkRule memory lr = _repo.links[drager].linkRule;

        if (lr.typeOfFollowers == 1)
            return _bom.isMember(follower);
        else if (lr.typeOfFollowers == 2) {
            uint i = 0;
            while (i < 7) {
                if (_checkTheClasses(follower, lr.classes[i]))
                    return true;
                i++;
            }
            return false;
        }
        else if (lr.typeOfFollowers == 0)
            return _repo.links[drager].followers.contains(follower);
        return false;
    }

    function _checkTheClasses(uint acct, uint class)
        private view returns(bool) {
            return (class > 0 && _bom.isClassMember(acct, class));
    }

    function dragers() external view returns (uint256[] memory) {
        return _repo.draggersList.values();
    }

    function followers(uint256 drager) external view returns (uint256[] memory) {
        return _repo.links[drager].followers.values();
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

        RulesParser.LinkRule memory lr = _repo.links[caller].linkRule;

        if (
            lr.triggerType <
            uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)
        ) return true;

        if (
            lr.triggerType ==
            uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)
        ) {
            if (deal.head.priceOfPaid >= lr.rate) return true;
            else return false;
        }

        if (
            _roeOfDeal(deal.head.priceOfPaid, share.head.priceOfPaid, deal.head.closingDeadline, share.head.issueDate) >=
            lr.rate
        ) return true;

        return false;
    }

    // ################
    // ##  Term接口  ##
    // ################

    function isTriggered(address ia, DealsRepo.Deal memory deal) public view returns (bool) {
        

        if (_boi.getHeadOfFile(ia).state != uint8(FilesRepo.StateOfFile.Circulated))
            return false;

        if (
            deal.head.typeOfDeal ==
            uint8(DealsRepo.TypeOfDeal.CapitalIncrease) ||
            deal.head.typeOfDeal == uint8(DealsRepo.TypeOfDeal.PreEmptive)
        ) return false;

        if (!_repo.draggersList.contains(deal.head.seller)) return false;

        RulesParser.LinkRule memory rule = _repo.links[deal.head.seller].linkRule;

        if (rule.triggerDate > 0 && 
            (block.timestamp < rule.triggerDate ||
                block.timestamp >= rule.triggerDate + rule.effectiveDays ))
        return false;

        if (rule.triggerType == uint8(TriggerTypeOfAlongs.NoConditions))
            return true;

        uint40 controllor = _bom.controllor();

        if (controllor != _bom.groupRep(deal.head.seller)) return false;

        (uint40 newControllor, uint16 shareRatio) = 
            _boi.mockResultsOfIA(ia);

        if (controllor != newControllor) return true;

        if (shareRatio <= rule.shareRatioThreshold) return true;

        return false;
    }

    function _roeOfDeal(
        uint32 dealPrice,
        uint32 issuePrice,
        uint48 closingDeadline,
        uint48 issueDateOfShare
    ) internal pure returns (uint32 roe) {
        require(dealPrice > issuePrice, "ROE: NEGATIVE selling price");
        require(closingDeadline > issueDateOfShare, "ROE: NEGATIVE holding period");

        uint32 deltaPrice = dealPrice - issuePrice;
        uint32 deltaDate = uint32(closingDeadline - issueDateOfShare);

        roe = (((deltaPrice * 10000) / issuePrice) * 31536000) / deltaDate;
    }
}