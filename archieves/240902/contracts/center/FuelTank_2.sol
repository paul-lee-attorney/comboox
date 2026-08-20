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

import "./access/Ownable.sol";
import "../lib/Address.sol";

contract FuelTank_2 is Ownable {

  uint public rate;
  uint public sum;

  constructor(address rc, uint _rate) {
    init(msg.sender, rc);
    rate = _rate;
  }

  // ##################
  // ##  Write I/O   ##
  // ##################
  
  function setRate(uint _rate) external onlyOwner {
    rate = _rate;
  }

  function refuel() external payable {

    uint amt = msg.value * rate / 10000;

    if (amt > 0 && _rc.balanceOf(address(this)) >= amt) {

      _rc.transfer(msg.sender, amt);
      
      sum += amt;

    } else revert ('zero amt or insufficient balace');

  }

  function withdrawIncome(uint amt) external onlyOwner {
    Address.sendValue(payable(msg.sender), amt);
  }

  function withdrawFuel(uint amt) external onlyOwner {

    if (_rc.balanceOf(address(this)) >= amt) {

        _rc.transfer(msg.sender, amt);

    } else revert('insufficient fuel');
  }

}
