// SPDX-License-Identifier: UNLICENSED

/* *
 * v.0.2.5
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

import "./IRegCenter.sol";
import "./Oracles/IPriceConsumer_3.sol";
import "./books/BookOfDocs.sol";

contract RegCenter_2 is IRegCenter, BookOfDocs {
    
    IPriceConsumer_3 private _oracle;

    constructor(address keeper) BookOfDocs(keeper){}

    // #################
    // ##    Write    ##
    // #################

    function setOracle(address pf) external onlyKeeper {
        _oracle = IPriceConsumer_3(pf);
    }

    function setPriceFeed(uint seq, address feed_ ) onlyKeeper external {
        _oracle.setPriceFeed(seq, feed_);
        emit SetPriceFeed(seq, feed_);
    }

    function regUser() external {
        uint gift = _regUser();
        if (gift > 0) {
            _mint(msg.sender, gift * 10 ** 9);
        }
    }

    function getUserNo(address targetAddr, uint fee, uint author) external returns (uint40) {

        uint40 target = _getUserNo(targetAddr);

        require(docExist(msg.sender), 
            "RC.getUserNo: not registered ");
            
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

        UsersRepo.User memory t = _getUserByNo(_getUserNo(targetAddr));
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

        t.primeKey.coupon++;
    }

    function getOracle () external view returns(address) {
        return address(_oracle);
    }

    function getPriceFeed(uint seq) external view returns (address) {
        return _oracle.getPriceFeed(seq);
    }

    function decimals(address quote) public view returns (uint8) {
        return _oracle.decimals(quote);
    }

    function getCentPriceInWei(uint seq) external view returns(uint) {
        return _oracle.getCentPriceInWei(seq);
    }

}
