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

import "../access/Ownable.sol";
import "../../openzeppelin/utils/Address.sol";
import "../../comps/books/cashier/ICashier.sol";
import "../../lib/InterfacesHub.sol";

/// @title UsdFuelTank
/// @notice Accepts USDC authorization via Cashier and dispenses CBP at a fixed rate.
/// @dev `rate` is the USDC smallest-unit amount per 1e18 CBP.
contract UsdFuelTank is Ownable {
  using InterfacesHub for address;
  using Address for address;

  /// @notice Cashier contract that pulls USDC using off-chain authorization.
  address public cashier;
  /// @notice USDC-per-1e18-CBP exchange rate (USDC in smallest units).
  uint public rate;
  /// @notice Total CBP dispensed by this contract.
  uint public sum;

  // ==== UUPSUpgradable ====

  uint[50] private __gap;

  /// @notice Upgrade implementation via UUPS and register the upgrade in RegCenter.
  /// @param newImplementation New implementation address.
  function upgradeCenterTo(address newImplementation) external {
    upgradeTo(newImplementation);
    rc.getRC().upgradeDoc(newImplementation);
  }

  /// @notice Emitted when Cashier address is updated.
  /// @param newCashier New Cashier address.
  event SetCashier(address indexed newCashier);

  /// @notice Emitted when rate is updated.
  /// @param newRate New USDC-per-1e18-CBP rate.
  event SetRate(uint indexed newRate);

  /// @notice Emitted on successful refuel.
  /// @param buyer CBP recipient.
  /// @param amtOfUSDC USDC amount charged (smallest units).
  /// @param amtOfCbp CBP amount dispensed (18 decimals).
  event Refuel(address indexed buyer, uint indexed amtOfUSDC, uint indexed amtOfCbp);

  /// @notice Emitted when owner withdraws CBP reserve.
  /// @param owner Owner address.
  /// @param amt CBP amount withdrawn.
  event WithdrawFuel(address indexed owner, uint indexed amt);

  // ##################
  // ##  Write I/O   ##
  // ##################

  /// @notice Set Cashier contract.
  /// @param newCashier Cashier address (non-zero, must be a contract).
  function setCashier(address newCashier) external onlyOwner {
    require(newCashier != address(0), "zero cashier");
    require(newCashier.isContract(), "cashier not contract");
    cashier = newCashier;
    emit SetCashier(newCashier);
  }

  /// @notice Set USDC-per-1e18-CBP rate.
  /// @param newRate New rate (must be > 0).
  function setRate(uint newRate) external onlyOwner {
    require(newRate > 0, "zero rate");
    rate = newRate;
    emit SetRate(newRate);
  }

  /// @notice Pull USDC via Cashier authorization and transfer CBP to caller.
  /// @param auth USDC authorization (EIP-3009 style) for Cashier to collect.
  /// @param amt CBP amount requested (18 decimals). If zero, it is derived from auth.value.
  function refuel(ICashier.TransferAuth memory auth, uint amt) external {
    uint balance = 0;
    if (amt == 0) {
      amt = auth.value * 10 ** 18 / rate ;
    } else {
      require (auth.value >= (rate * amt / 10 ** 18), 
        "UsdFT.Refule: insufficient USDC");
      balance = auth.value - (rate * amt / 10 ** 18);
    }

    if (amt > 0 && rc.getRC().balanceOf(address(this)) >= amt) {
      sum += amt;
      emit Refuel (msg.sender, auth.value - balance, amt);
      //remark: bytes("CollectUSDCForRefuelCBP")
      ICashier(cashier).collectUsd(auth,
        bytes32(0x436f6c6c65637455534443466f7252656675656c434250000000000000000000));
      if (!rc.getRC().transfer(msg.sender, amt)) {
        revert ('CBP Transfer Failed');
      } else if (balance > 0) {
        uint temp = balance;
        balance = 0;
        //remark: bytes("RefundBalanceUSDCForRefuelCBP")
        ICashier(cashier).transferUsd(auth.from, temp,
          bytes32(0x526566756e6442616c616e636555534443466f7252656675656c434250000000));
      }
    } else revert ('zero amt or insufficient CBP reserve');

  }

  /// @notice Withdraw CBP reserve to owner.
  /// @param amt CBP amount to withdraw.
  function withdrawFuel(uint amt) external onlyOwner {
    if (rc.getRC().balanceOf(address(this)) >= amt) {
        emit WithdrawFuel(msg.sender, amt);
        if (!rc.getRC().transfer(msg.sender, amt)) {
          revert('CBP Transfer Failed');
        }
    } else revert('insufficient fuel');
  }

}
