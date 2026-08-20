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

import "./EnumerableSet.sol";

library SafeBoxes {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  struct Head {
    uint96 amtHead;
    address from;
    uint48 expireDate;
    uint48 amtTail;
    address to;
  }

  struct Body {
    address counterLocker;
    bytes payload;
  }

  struct Box {
    Head head;
    Body body;
  }

  struct Repo {
    // hashLock => Box
    mapping (bytes32 => Box) boxes;
    EnumerableSet.Bytes32Set snList;
  }

  //#################
  //##  Write I/O  ##
  //#################

  function createBox(
    Repo storage repo,
    address from,
    address to,
    uint expireDate,
    bytes32 hashLock
  ) public {
    Body memory body;
    createBox(repo, from, to, expireDate, body, hashLock);
  }

  function createBox(
    Repo storage repo,
    address from,
    address to,
    uint expireDate,
    Body memory body,
    bytes32 hashLock
  ) public {
    if (repo.snList.add(hashLock)) {        
      Box storage box = repo.boxes[hashLock];

      box.head.from = from;
      box.head.to = to;
      box.head.expireDate = uint48(expireDate);

      box.body = body;
    } else revert ("SafeBox.lockConsideration: occupied");
  }

  function depositMoney(
    Repo storage repo,
    bytes32 hashLock,
    uint amt
  ) public {
    require((amt >> 144) == 0, "SafeBox.depositMoney: amt overflow");

    require(repo.snList.contains(hashLock),
      "SafeBox: hashLock not exist");

    Box storage box = repo.boxes[hashLock];

    require(box.head.amtTail == 0 &&
      box.head.amtHead == 0, "SafeBox.depositMoney: not empty");

    box.head.amtHead = uint96(amt >> 48);
    box.head.amtTail = uint48(amt);

  }

  function pickupDeposits(
      Repo storage repo,
      bytes32 hashLock,
      string memory hashKey
  ) internal returns(Head memory head) {        
    bytes memory key = bytes(hashKey);

    require(hashLock == keccak256(key),
        "SafeBox.pickup: wrong key");

    if (repo.snList.remove(hashLock)) {
      Box storage box = repo.boxes[hashLock];

      require(block.timestamp < box.head.expireDate, 
          "SafeBox.pickup: box expired");

      bool flag;

      if (box.body.counterLocker != address(0)) {
        uint len = key.length;
        bytes memory zero = new bytes(32 - (len % 32));

        bytes memory payload = abi.encodePacked(box.body.payload, len, key, zero);
        (flag, ) = box.body.counterLocker.call(payload);

        require (flag, "SafeBox.pickup: counterCall failed");
      }

      uint amt = (uint(box.head.amtHead) << 48) + box.head.amtTail;

      if (amt > 0) {
        require(address(this).balance >= amt, 
          "SafeBox.pickup: insufficient balance");
        
        (flag, ) = payable(box.head.to).call{value: amt}("");
        require(flag, "SafeBox.pickup: money transfer failed");
      }

      head = box.head;
      delete repo.boxes[hashLock];
    } else revert ("SafeBox.pickup: box not exist");

  }

  function withdrawDeposit(
    Repo storage repo,
    bytes32 hashLock,
    address msgSender
  ) public returns(Head memory head) {

    Box memory box = repo.boxes[hashLock];

    require(block.timestamp >= box.head.expireDate, 
        "SafeBox.withdrawDeposit: box not expired");

    require(box.head.from == msgSender, 
        "SafeBox.withdrawDeposit: wrong msgSender");

    if (repo.snList.remove(hashLock)) {
        head = box.head;
        delete repo.boxes[hashLock];
    } else revert ("SafeBox.withdrawDeposit: box not exist");
  }

    //#################
    //##    Read     ##
    //#################

    function getHeadOfBox(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (Head memory head) {
        return repo.boxes[hashLock].head;
    }

    function getBox(
        Repo storage repo,
        bytes32 hashLock
    ) public view returns (Box memory) {
        return repo.boxes[hashLock];
    }

    function getSnList(
        Repo storage repo
    ) public view returns (bytes32[] memory ) {
        return repo.snList.values();
    }

}


