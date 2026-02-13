// SPDX-License-Identifier: UNLICENSED

/* *
 *
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

import "./IRegisterOfRedemptions.sol";

import "../../common/access/AccessControl.sol";


contract RegisterOfRedemptions is IRegisterOfRedemptions, AccessControl {
    using RedemptionsRepo for RedemptionsRepo.Repo;

    // Repository for redemption classes, packs, and requests.
    RedemptionsRepo.Repo private _list;

    // ==== UUPSUpgradable ====
    uint256[50] private __gap;

    //###############
    //##   Write   ##
    //###############

    // ==== Config ====

    function addRedeemableClass(uint class) external onlyKeeper {
        _list.addRedeemableClass(class);
        emit AddRedeemableClass(class);
    }

    function removeRedeemableClass(uint class) external onlyKeeper {
        _list.removeRedeemableClass(class);
        emit RemoveRedeemableClass(class);
    }

    function updateNavPrice(uint class, uint price) external onlyKeeper{
        _list.updateNavPrice(class, price);
        emit UpdateNavPrice(class, price);
    }

    // ==== Redeem ====

    function requestForRedemption(
        uint caller, uint class, uint seqOfShare, uint paid
    ) external onlyKeeper returns(
        RedemptionsRepo.Request memory request
    ) {
        request = _list.requestForRedemption(caller, class, seqOfShare, paid);

        emit RequestForRedemption(request.class, request.seqOfShare, request.paid, request.value);
    }

    function redeem(uint class, uint seqOfPack) external onlyKeeper returns(
        RedemptionsRepo.Request[] memory list, RedemptionsRepo.Request memory info
    ) {
        (list, info) = _list.redeem(class, seqOfPack);

        emit RedeemClass(class, info.paid, info.value);

        uint len = list.length;
        while(len > 0) {
            RedemptionsRepo.Request memory request = list[len-1];
            emit RedeemShare(
                request.shareholder,
                request.class,
                request.seqOfShare,
                request.paid,
                request.value
            );
            len--;
        }
        
    }

    //##################
    //##   Read I/O   ##
    //##################

    function isRedeemable(uint class) external view returns(bool) {
        return _list.isRedeemable(class);
    }

    function getClassesList() external view returns(uint[] memory list) {
        list = _list.getClassesList();
    }

    // ==== Class ====

    function getInfoOfClass(uint class) external view returns(
        RedemptionsRepo.Request memory info
    ) {
        info = _list.getInfoOfClass(class);
    }

    function getPacksList(uint class) external view returns(uint[] memory list) {
        list = _list.getPacksList(class);
    }

    // ==== Pack ====

    function getInfoOfPack(uint class, uint seqOfPack) external view returns(
        RedemptionsRepo.Request memory info    
    ) {
        info = _list.getInfoOfPack(class, seqOfPack);
    }

    function getSharesList(uint class, uint seqOfPack) external view returns(uint[] memory list) {
        list = _list.getSharesList(class, seqOfPack);
    }

    function getRequest(uint class, uint seqOfPack, uint seqOfShare) external view returns(
        RedemptionsRepo.Request memory request
    ) {
        request = _list.getRequest(class, seqOfPack, seqOfShare);
    }

    function getRequests(uint class, uint seqOfPack) external view returns(
        RedemptionsRepo.Request[] memory requests
    ) {
        requests = _list.getRequests(class, seqOfPack);
    }
}
