// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ERC20/IERC20.sol";

contract FuleTank {

  address public owner;
  address public regCenter;
  uint public rate;
  uint public sum;

  constructor(address _regCenter, uint _rate) {
    owner = msg.sender;
    regCenter = _regCenter;
    rate = _rate;
  }

  modifier onlyOwner() {
    require (msg.sender == owner, 'FT: not owner');
    _;
  }

  // ##################
  // ##  Write I/O   ##
  // ##################

  function setOwner(address _owner) external onlyOwner {
    owner = _owner;
  }

  function setRegCenter(address _regCenter) external onlyOwner { 
    regCenter = _regCenter;
  }
  
  function setRate(uint _rate) external onlyOwner {
    rate = _rate;
  }

  function refule() external payable {

    uint amt = msg.value * rate / 10000;

    if (amt > 0 && IERC20(regCenter).balanceOf(address(this)) >= amt) {

      IERC20(regCenter).transfer(msg.sender, amt);
      
      sum += amt;

    } else revert ('zero amt or insufficient balace');

  }

  function withdrawIncome(uint amt) external onlyOwner {

    if (address(this).balance >= amt) {

      payable(msg.sender).transfer(amt);

    } else revert('insufficient amount');
  }

}



