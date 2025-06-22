// SPDX-License-Identifier: UNLICENSED

/* *
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

import "./access/Ownable.sol";
import "../lib/Address.sol";
import "../comps/books/cashier/ICashier.sol";

contract UsdFuelTank is Ownable {

  address public cashier;
  uint public rate;
  uint public sum;

  constructor(address rc, uint _rate) {
    init(msg.sender, rc);
    rate = _rate;
  }

  event SetCashier(address indexed newCashier);
  event SetRate(uint indexed newRate);
  event Refuel(address indexed buyer, uint indexed amtOfUSDC, uint indexed amtOfCbp);
  event WithdrawFuel(address indexed owner, uint indexed amt);

  // ##################
  // ##  Write I/O   ##
  // ##################

  function setCashier(address newCashier) external onlyOwner {
    cashier = newCashier;
    emit SetCashier(newCashier);
  }

  function setRate(uint newRate) external onlyOwner {
    rate = newRate;
    emit SetRate(newRate);
  }

  function refuel(ICashier.TransferAuth memory auth, uint amt) external {
    uint balance = 0;
    if (amt == 0) {
      amt = auth.value * 10 ** 18 / rate ;
    } else {
      require (auth.value >= (rate * amt / 10 ** 18), 
        "UsdFT.Refule: insufficient USDC");
      balance = auth.value - (rate * amt / 10 ** 18);
    }

    if (amt > 0 && _rc.balanceOf(address(this)) >= amt) {
      sum += amt;
      emit Refuel (msg.sender, auth.value - balance, amt);
      //remark: CollectUSDCForRefuelCBP
      ICashier(cashier).collectUsd(auth,
        bytes32(0x436f6c6c65637455534443466f7252656675656c434250000000000000000000));
      if (!_rc.transfer(msg.sender, amt)) {
        revert ('CBP Transfer Failed');
      } else if (balance > 0) {
        uint temp = balance;
        balance = 0;
        //remark: RefundBalanceUSDCForRefuelCBP
        ICashier(cashier).transferUsd(auth.from, temp, 
          bytes32(0x526566756e6442616c616e636555534443466f7252656675656c434250000000));
      }
    } else revert ('zero amt or insufficient CBP reserve');

  }

  function withdrawFuel(uint amt) external onlyOwner {
    if (_rc.balanceOf(address(this)) >= amt) {
        emit WithdrawFuel(msg.sender, amt);
        if (!_rc.transfer(msg.sender, amt)) {
          revert('CBP Transfer Failed');
        }
    } else revert('insufficient fuel');
  }

}
