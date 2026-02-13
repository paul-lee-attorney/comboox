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

import "./IRegCenter.sol";
import "./books/BookOfPoints.sol";

contract RegCenter is BookOfPoints, IRegCenter{

    // ==== UUPSUpgradable ====

    uint256[50] private __gap;

    // #################
    // ##    Write    ##
    // #################

    function regUser() external {
        uint gift = _regUser();
        if (gift > 0) {
            _mint(msg.sender, gift * 10 ** 9);
        }
    }

    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40) {

        uint40 target = _getUserNo(targetAddr);

        require(docExist(msg.sender), 
            "RC.getUserNo: Doc NOT registered");
            
        UsersRepo.Key memory rr = getRoyaltyRule(author);
        address authorAddr = _getUserByNo(author).primeKey.pubKey; 

        _chargeFee(targetAddr, fee, authorAddr, rr);

        return target;
    }

    function _chargeFee(
        address targetAddr, 
        uint fee, 
        address authorAddr,
        UsersRepo.Key memory rr
    ) private {

        UsersRepo.User memory t = _getUser(targetAddr);
        address ownerAddr = getOwner();

        UsersRepo.Rule memory pr = getPlatformRule();
        
        uint floorPrice = uint(pr.floor) * 10 ** 9;

        require(fee >= floorPrice, "RC.chargeFee: lower than floor");

        uint offAmt = uint(t.primeKey.coupon) * uint(rr.discount) * fee / 10000 + uint(rr.coupon) * 10 ** 9;
        
        fee = (offAmt < (fee - floorPrice))
            ? (fee - offAmt)
            : floorPrice;

        uint giftAmt = uint(rr.gift) * 10 ** 9;

        if (ownerAddr == authorAddr || pr.rate == 2000) {
            if (fee > giftAmt)
                _transfer(t.primeKey.pubKey, authorAddr, fee - giftAmt);
        } else {
            _transfer(t.primeKey.pubKey, ownerAddr, fee * (2000 - pr.rate) / 10000);
            
            uint balaceAmt = fee * (8000 + pr.rate) / 10000;
            if ( balaceAmt > giftAmt)
                _transfer(t.primeKey.pubKey, authorAddr, balaceAmt - giftAmt);
        }

        _addCouponOnce(targetAddr);
    }

    // ==== Self Query ====

    function getMyUserNo() external view returns(uint40) {
        return _getUserNo(msg.sender);
    }

    function getMyUser() external view returns (UsersRepo.User memory) {
        return _getUser(msg.sender);
    }

    // ==== Admin Checking ====

    function getUserNo(address targetAddr) external view onlyKeeper returns (uint40) {
        return _getUserNo(targetAddr);
    }

    function getUser(address targetAddr) external view onlyKeeper returns (UsersRepo.User memory) {
        return _getUser(targetAddr);
    }

    function getUserByNo(uint acct) external view onlyKeeper returns (UsersRepo.User memory) {
        return _getUserByNo(acct);
    }

}