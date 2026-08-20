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

import "../center/access/Ownable.sol";
import "../lib/SafeBoxes.sol";

contract SafeDepositBox is Ownable {
  using SafeBoxes for SafeBoxes.Repo;

  SafeBoxes.Repo private _boxes;

  event CreateBox(
    bytes32 indexed hashLock, address indexed from, address indexed to, uint expireDate, uint user 
  );
  event CreateBoxWithCounterlCall(
    bytes32 indexed hashLock, address indexed from, address indexed to, 
    uint expireDate, address counterLocker, uint user
  );
  event DepositMoney(bytes32 indexed hashLock, uint indexed amt, uint indexed payer);
  event PickupDeposit(bytes32 indexed hashLock, address indexed from, address indexed to, uint amt, uint user);
  event WithdrawDeposit(bytes32 indexed hashLock, address indexed from, address indexed to, uint amt, uint user);
  event WithdrawIncome(address indexed owner, uint indexed income);

  modifier onlyOnwer{
    require(msg.sender == getOwner(),
      "SafeBox: not owner");
    _;    
  }

  //#################
  //##    Write    ##
  //#################

  function _msgSender(
      uint rate
  ) private returns(uint40 usr) {
      usr = _rc.getUserNo(
          msg.sender, 
          rate * (10 ** 10), 
          _rc.getMyUserNo()
      );
  }

  // ==== Config ====

  function regUser() external onlyOnwer{
    _rc.regUser();
  }

  function getMyUserNo() external onlyOwner returns(uint){
    return _rc.getMyUserNo();
  }

  function getIncome() external view returns(uint) {
    return _rc.balanceOf(address(this));
  }

  function withdrawIncome() external onlyOnwer {
    uint income = _rc.balanceOf(address(this));
    _rc.transfer(msg.sender, income);

    emit WithdrawIncome(msg.sender, income);
  }

  // ==== Box ====

  function createBox(
    address from,
    address to,
    uint expireDate,
    bytes32 hashLock
  ) external {
    _boxes.createBox(from, to, expireDate, hashLock);
    emit CreateBox(hashLock, from, to, expireDate, _msgSender(18000));
  }

  function createBox(
    address from,
    address to,
    uint expireDate,
    SafeBoxes.Body memory body,
    bytes32 hashLock
  ) external {
    _boxes.createBox(from, to, expireDate, body, hashLock);
    emit CreateBoxWithCounterlCall(hashLock, from, to, expireDate, body.counterLocker, _msgSender(18000));
  }

  function depositMoney(
    bytes32 hashLock
  ) external payable{
    uint amt = msg.value;
    _boxes.depositMoney(hashLock, amt);
    emit DepositMoney(hashLock, amt, _msgSender(18000));
  }

  function pickupDeposit(
    bytes32 hashLock,
    string memory hashKey
  ) external {
    SafeBoxes.Head memory head =
      _boxes.pickupDeposits(hashLock, hashKey);
    uint amt = uint(head.amtHead) << 48 + head.amtTail;
    emit PickupDeposit(hashLock, head.from, head.to, amt, _msgSender(18000));
  }

  function withdrawDeposit(
    bytes32 hashLock
  ) external {
    SafeBoxes.Head memory head =
      _boxes.withdrawDeposit(hashLock, msg.sender);
    uint amt = uint(head.amtHead) << 48 + head.amtTail;
    emit WithdrawDeposit(hashLock, head.from, head.to, amt, _msgSender(18000));
  }

    //#################
    //##    Read     ##
    //#################

    function getHeadOfBox(
        bytes32 hashLock
    ) external view returns (SafeBoxes.Head memory head) {
        return _boxes.getHeadOfBox(hashLock);
    }

    function getBox(
        bytes32 hashLock
    ) external view returns (SafeBoxes.Box memory) {
        return _boxes.getBox(hashLock);
    }

    function getSnList() external view returns (bytes32[] memory ) {
        return _boxes.getSnList();
    }

}