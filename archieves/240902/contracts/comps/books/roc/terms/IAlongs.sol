// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright (c) 2021-2024 LI LI @ JINGTIAN & GONGCHENG.
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

pragma solidity ^0.8.8;

import "../../../../lib/LinksRepo.sol";

interface IAlongs {

    // ################
    // ##   Write    ##
    // ################

    function addDragger(bytes32 rule, uint256 dragger) external;

    function removeDragger(uint256 dragger) external;

    function addFollower(uint256 dragger, uint256 follower) external;

    function removeFollower(uint256 dragger, uint256 follower) external;


    // ###############
    // ##  Read I/O ##
    // ###############

    function isDragger(uint256 dragger) external view returns (bool);

    function getLinkRule(uint256 dragger) external view 
        returns (RulesParser.LinkRule memory);

    function isFollower(uint256 dragger, uint256 follower)
        external view returns (bool);

    function getDraggers() external view returns (uint256[] memory);

    function getFollowers(uint256 dragger) external view returns (uint256[] memory);

    function priceCheck(
        DealsRepo.Deal memory deal
    ) external view returns (bool);

    function isTriggered(address ia, DealsRepo.Deal memory deal) external view returns (bool);
}
