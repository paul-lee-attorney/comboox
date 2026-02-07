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

import "./IBookOfPoints.sol";
import "../../openzeppelin/token/ERC20/ERC20Upgradeable.sol";
import "./BookOfDocs.sol";

contract BookOfPoints is IBookOfPoints, ERC20Upgradeable, BookOfDocs {

    // ==== UUPSUpgradable ====

    uint256[50] private __gap;

    function initialize(
        address owner_,
        address regCenter_,
        address keeper
    ) external virtual override initializer {
        __ERC20_init("ComBooxPoints", "CBP");
        _initUsers(keeper);
        _init(owner_, regCenter_);
    }
    
    // ##################
    // ##  Mint & Lock ##
    // ##################

    function mint(address to, uint amt) external onlyOwner {
        _mint(to, amt);
    }

    function burn(uint amt) external onlyOwner {
        _burn(msg.sender, amt);
    }

}
