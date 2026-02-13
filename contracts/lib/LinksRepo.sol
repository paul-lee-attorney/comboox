// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2026 LI LI @ JINGTIAN & GONGCHENG.
 *
 * This WORK is licensed under ComBoox SoftWare License 1.0, a copy of which 
 * can be obtained at:
 *         [https://github.com/paul-lee-attorney/comboox]
 *
 * THIS WORK IS PROVIDED ON AN "AS IS" BASIS, WITHOUT 
 * WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
 * TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE. IN NO 
 * EVENT SHALL ANY CONTRIBUTOR BE LIABLE TO YOU FOR ANY DAMAGES.
 *
 * YOU ARE PROHIBITED FROM DEPLOYING THE SMART CONTRACTS OF THIS WORK, IN WHOLE 
 * OR IN PART, FOR WHATEVER PURPOSE, ON ANY BLOCKCHAIN NETWORK THAT HAS ONE OR 
 * MORE NODES THAT ARE OUT OF YOUR CONTROL.
 * */

pragma solidity ^0.8.24;

import "../comps/books/rom/IRegisterOfMembers.sol";
import "../comps/books/ros/IRegisterOfShares.sol";

import "./DealsRepo.sol";
import "./RulesParser.sol";
import "./SharesRepo.sol";

/// @title LinksRepo
/// @notice Library for managing drag-along/tag-along relationships and rules.
/// @dev Stores rules by group representative and tracks follower sets.
library LinksRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using RulesParser for bytes32;

    /// @notice Trigger conditions for along rights.
    enum TriggerTypeOfAlongs {
        NoConditions,
        ControlChanged,
        ControlChangedWithHigherPrice,
        ControlChangedWithHigherROE
    }

    /// @notice Link rule and its followers set.
    struct Link {
        RulesParser.LinkRule linkRule;
        EnumerableSet.UintSet followersList;
    }

    /// @notice Repository storage for links by dragger group.
    struct Repo {
        // dragger => Link
        mapping(uint256 => Link) links;
        EnumerableSet.UintSet  draggersList;
    }

    /// @dev Reverts if dragger is not registered.
    modifier draggerExist(Repo storage repo, uint dragger, IRegisterOfMembers _rom) {
        require(isDragger(repo, dragger, _rom), "LR.mf.draggerExist: not");
        _;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    /// @notice Add a dragger with a link rule.
    /// @param repo Repository storage.
    /// @param rule Encoded link rule.
    /// @param dragger Dragger account.
    /// @param _rom Register of members.
    function addDragger(Repo storage repo, bytes32 rule, uint256 dragger, IRegisterOfMembers _rom) public {
        uint40 groupRep = _rom.groupRep(dragger);
        if (repo.draggersList.add(groupRep))
            repo.links[groupRep].linkRule = rule.linkRuleParser();
    }

    /// @notice Remove a dragger and its followers.
    /// @param repo Repository storage.
    /// @param dragger Dragger account (group representative).
    function removeDragger(Repo storage repo, uint256 dragger) public {
        if (repo.draggersList.remove(dragger))
            delete repo.links[dragger];
        }

    /// @notice Add a follower to a dragger.
    /// @param repo Repository storage.
    /// @param dragger Dragger account (group representative).
    /// @param follower Follower account.
    function addFollower(Repo storage repo, uint256 dragger, uint256 follower) public {
        repo.links[dragger].followersList.add(uint40(follower));
    }

    /// @notice Remove a follower from a dragger.
    /// @param repo Repository storage.
    /// @param dragger Dragger account (group representative).
    /// @param follower Follower account.
    function removeFollower(Repo storage repo, uint256 dragger, uint256 follower) public {
        repo.links[dragger].followersList.remove(follower);
    }

    // ################
    // ##  Read I/O  ##
    // ################

    /// @notice Check whether an account is a dragger.
    /// @param repo Repository storage.
    /// @param dragger Dragger account.
    /// @param _rom Register of members.
    function isDragger(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view returns (bool) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.draggersList.contains(groupRep);
    }

    /// @notice Get link rule for a dragger.
    /// @param repo Repository storage.
    /// @param dragger Dragger account.
    /// @param _rom Register of members.
    function getLinkRule(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view draggerExist(repo, dragger, _rom)
        returns (RulesParser.LinkRule memory) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].linkRule;
    }

    /// @notice Check whether a follower is linked to a dragger.
    /// @param repo Repository storage.
    /// @param dragger Dragger account.
    /// @param follower Follower account.
    /// @param _rom Register of members.
    function isFollower(
        Repo storage repo, 
        uint256 dragger, 
        uint256 follower,
        IRegisterOfMembers _rom
    ) public view draggerExist(repo, dragger, _rom) 
        returns (bool) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].followersList.contains(uint40(follower));
    }

    /// @notice Get list of draggers (group representatives).
    /// @param repo Repository storage.
    function getDraggers(Repo storage repo) public view returns (uint256[] memory) {
        return repo.draggersList.values();
    }

    /// @notice Get followers linked to a dragger.
    /// @param repo Repository storage.
    /// @param dragger Dragger account.
    /// @param _rom Register of members.
    function getFollowers(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view draggerExist(repo, dragger, _rom) returns (uint256[] memory) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].followersList.values();
    }

    /// @notice Check price/ROE constraints based on link rule.
    /// @param repo Repository storage.
    /// @param deal Deal data.
    /// @param _ros Register of shares.
    /// @param _rom Register of members.
    function priceCheck(
        Repo storage repo,
        DealsRepo.Deal memory deal,
        IRegisterOfShares _ros,
        IRegisterOfMembers _rom
    ) public view returns (bool) {

        RulesParser.LinkRule memory lr = 
            getLinkRule(repo, deal.head.seller, _rom);

        if (lr.triggerType == uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)) 
            return (deal.head.priceOfPaid >= lr.rate);

        SharesRepo.Share memory share = 
            _ros.getShare(deal.head.seqOfShare);

        if (lr.triggerType == uint8(TriggerTypeOfAlongs.ControlChangedWithHigherROE))
            return (_roeOfDeal(
                deal.head.priceOfPaid, 
                share.head.priceOfPaid, 
                deal.head.closingDeadline, 
                share.head.issueDate) >= lr.rate);

        return true;
    }

    /// @dev Compute annualized ROE in basis points (scaled).
    function _roeOfDeal(
        uint dealPrice,
        uint issuePrice,
        uint closingDeadline,
        uint issueDateOfShare
    ) private pure returns (uint roe) {
        require(dealPrice > issuePrice, "ROE: NEGATIVE selling price");
        require(closingDeadline > issueDateOfShare, "ROE: NEGATIVE holding period");

        roe = (dealPrice - issuePrice) * 31536 * 10 ** 7 / issuePrice / (closingDeadline - issueDateOfShare);
    }
}
