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

import "../../../../lib/books/LinksRepo.sol";
import "../../roa/IRegisterOfAgreements.sol";

/// @title IAlongs
/// @notice Interface for managing drag-along/tag-along relationships and rules.
interface IAlongs {

    // ################
    // ##   Write    ##
    // ################

    /// @notice Add a dragger with an encoded link rule.
    /// @param rule Encoded link rule.
    /// @param dragger Dragger account.
    function addDragger(bytes32 rule, uint256 dragger) external;

    /// @notice Remove a dragger and its followers.
    /// @param dragger Dragger account.
    function removeDragger(uint256 dragger) external;

    /// @notice Add a follower to a dragger.
    /// @param dragger Dragger account.
    /// @param follower Follower account.
    function addFollower(uint256 dragger, uint256 follower) external;

    /// @notice Remove a follower from a dragger.
    /// @param dragger Dragger account.
    /// @param follower Follower account.
    function removeFollower(uint256 dragger, uint256 follower) external;


    // ###############
    // ##  Read I/O ##
    // ###############

    /// @notice Check whether an account is a dragger.
    /// @param dragger Dragger account.
    /// @return True if dragger.
    function isDragger(uint256 dragger) external view returns (bool);

    /// @notice Get link rule for a dragger.
    /// @param dragger Dragger account.
    /// @return Link rule.
    function getLinkRule(uint256 dragger) external view 
        returns (RulesParser.LinkRule memory);

    /// @notice Check whether a follower is linked to a dragger.
    /// @param dragger Dragger account.
    /// @param follower Follower account.
    /// @return True if linked.
    function isFollower(uint256 dragger, uint256 follower)
        external view returns (bool);

    /// @notice Get list of draggers.
    /// @return Dragger accounts.
    function getDraggers() external view returns (uint256[] memory);

    /// @notice Get followers linked to a dragger.
    /// @param dragger Dragger account.
    /// @return Follower accounts.
    function getFollowers(uint256 dragger) external view returns (uint256[] memory);

    /// @notice Check price/ROE constraints based on link rule.
    /// @param deal Deal data.
    /// @return True if constraints satisfied.
    function priceCheck(
        DealsRepo.Deal memory deal
    ) external view returns (bool);

    /// @notice Check whether a deal triggers along rights.
    /// @param ia Investment agreement address.
    /// @param deal Deal data.
    /// @return True if triggered.
    function isTriggered(address ia, DealsRepo.Deal memory deal) external view returns (bool);
}
