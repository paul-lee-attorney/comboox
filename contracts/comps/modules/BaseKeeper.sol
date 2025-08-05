// SPDX-License-Identifier: UNLICENSED

/* *
 * v0.2.5
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

import "../common/access/AccessControl.sol";
import "./IBaseKeeper.sol";

abstract contract BaseKeeper is IBaseKeeper, AccessControl {
    using Address for address;

    CompInfo internal _info;

    mapping(uint256 => address) private _books;
    mapping(uint256 => address) internal _keepers;
    mapping(address => uint256) private _titleOfKeeper;

    modifier isNormal() {
        require(_info.state == 0, "GK: deprecated");
        _;
    }

    // ---- Entity ----

    function setCompInfo (
        uint8 _currency,
        bytes18 _symbol,
        string memory _name
    ) external onlyDK {
        _info.currency = _currency;
        _info.symbol = _symbol;
        _info.name = _name;
    }

    function getCompInfo() external view returns(CompInfo memory) {
        return _info;
    }

    function getCompUser() external view onlyOwner returns (UsersRepo.User memory) {
        return _rc.getUser();
    }

    // ---- Keepers ----

    function regKeeper(
        uint256 title, 
        address keeper
    ) external onlyDK {
        _titleOfKeeper[_keepers[title]] = 0;
        _keepers[title] = keeper;
        _titleOfKeeper[keeper] = title;
        emit RegKeeper(title, keeper, msg.sender);
    }

    function isKeeper(address caller) external view returns (bool) {   
        return _titleOfKeeper[caller] > 0;
    }

    function getKeeper(uint256 title) external view returns (address) {
        return _keepers[title];
    }

    function getTitleOfKeeper(address keeper) external view returns (uint) {
        return _titleOfKeeper[keeper];
    }

    // ---- Books ----

    function regBook(uint256 title, address book) external onlyDK {
        _books[title] = book;
        emit RegBook(title, book, msg.sender);
    } 

    function getBook(uint256 title) external view returns (address) {
        return _books[title];
    }


}
