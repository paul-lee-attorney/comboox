// SPDX-License-Identifier: UNLICENSED

/* *
 *
 * Copyright (c) 2021-2025 LI LI @ JINGTIAN & GONGCHENG.
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

import "../../../lib/RedemptionsRepo.sol";

interface IRegisterOfRedemptions {

    event AddRedeemableClass(uint indexed class);

    event RemoveRedeemableClass(uint indexed class);

    event UpdateNavPrice(uint indexed class, uint indexed price);

    event RequestForRedemption(uint class, uint indexed seqOfShare, uint indexed paid, uint indexed value);

    event RedeemClass(uint indexed class, uint indexed sumOfPaid, uint indexed totalValue);

    event RedeemShare(uint shareholder, uint indexed class, uint seqOfShare, uint indexed paid, uint indexed value);

    //###############
    //##   Write   ##
    //###############

    // ==== Config ====

    function addRedeemableClass(uint class) external;

    function removeRedeemableClass(uint class) external;

    function updateNavPrice(uint class, uint price) external;

    function requestForRedemption(
        uint caller, 
        uint class, 
        uint seqOfShare, 
        uint paid
    ) external returns(
        RedemptionsRepo.Request memory request
    );

    function redeem(uint class, uint seqOfPack) external returns(
        RedemptionsRepo.Request[] memory list, RedemptionsRepo.Request memory info
    );

    //##################
    //##   Read I/O   ##
    //##################

    function isRedeemable(uint class) external view returns(bool);

    function getClassesList() external view returns(uint[] memory list);

    // ==== Class ====

    function getInfoOfClass(uint class) external view returns(
        RedemptionsRepo.Request memory info
    );

    function getPacksList(uint class) external view returns(uint[] memory list); 

    // ==== Pack ====

    function getInfoOfPack(uint class, uint seqOfPack) external view returns(
        RedemptionsRepo.Request memory info    
    );

    function getSharesList(uint class, uint seqOfPack) external view returns(uint[] memory list);

    function getRequest(uint class, uint seqOfPack, uint seqOfShare) external view returns(
        RedemptionsRepo.Request memory request
    );

    function getRequests(uint class, uint seqOfPack) external view returns(
        RedemptionsRepo.Request[] memory requests
    );
}
