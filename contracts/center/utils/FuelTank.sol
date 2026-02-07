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

pragma solidity ^0.8.8;

import "./access/Ownable.sol";
import "../lib/Address.sol";

contract FuelTank is Ownable {

  uint public rate;
  uint public sum;

  constructor(address rc, uint _rate) {
    init(msg.sender, rc);
    rate = _rate;
  }

  event SetRate(uint indexed newRate);
  event Refuel (address indexed buyer, uint indexed amtOfEth, uint indexed amtOfCbp);
  event WithdrawFuel (address indexed owner, uint indexed amt);
  event WithdrawIncome (address indexed owner, uint indexed amt);

  // ##################
  // ##  Write I/O   ##
  // ##################
  
  function setRate(uint newRate) external onlyOwner {
    rate = newRate;
    emit SetRate(newRate);
  }

  function refuel() external payable {

    uint amt = msg.value * rate / 10000;

    if (amt > 0 && rc.balanceOf(address(this)) >= amt) {
      sum += amt;
      emit Refuel (msg.sender, msg.value, amt);
      if (!rc.transfer(msg.sender, amt)) {
        revert ('CBP Transfer Failed');
      }
    } else revert ('zero amt or insufficient balance');

  }

  function withdrawIncome(uint amt) external onlyOwner {
    require(address(this).balance >= amt, 'Insufficient ETH');
    emit WithdrawIncome(msg.sender, amt);
    Address.sendValue(payable(msg.sender), amt);
  }

  function withdrawFuel(uint amt) external onlyOwner {
    if (rc.balanceOf(address(this)) >= amt) {
        emit WithdrawFuel(msg.sender, amt);
        if (!rc.transfer(msg.sender, amt)) {
          revert('CBP Transfer Failed');
        }
    } else revert('insufficient fuel');
  }

}
