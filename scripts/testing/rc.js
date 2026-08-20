// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { network } from "hardhat";
import { expect } from "chai";
import { formatUnits, parseUnits, Interface } from "ethers";
import { parseHexToBigInt, AddrZero, longDataParser } from './utils';
import { getUserCBP } from "./saveTool";

// This section includes the testing functions for the registration of new users in
// ComBoox. Each new user may obtain a sum of awards for its registration, rate
// of which is defined in Platform Rule. And, the Platform Rule can only be set
// and revised by the owner of the Platform.
export async function cbpOfUsers(rc, addrGK, usrComp) {
  const {ethers} = await network.connect();
  const signers = await ethers.getSigners();
  for (let i=0; i<7; i++) {
    const userNo = await getUserNo(rc, signers[i]);
    const bala = await rc.balanceOf(signers[i].address);

    const balaExpected = getUserCBP(userNo.toString());
    expect(balaExpected).to.equal(BigInt(bala.toString()));

    console.log('CBP Balance of User_', userNo, ':', longDataParser(formatUnits(bala.toString(), 9)), '(GLee). \n');
  }
  if (addrGK != AddrZero) {
    const cbpOfComp = await rc.balanceOf(addrGK);

    const cbpOfCompExpected = getUserCBP(usrComp.toString());
    expect(cbpOfCompExpected).to.equal(BigInt(cbpOfComp.toString()));

    console.log('CBP Balance of Comp:', usrComp, ":", longDataParser(formatUnits(cbpOfComp.toString(), 9)), '(GLee). \n');
  }
}

export function parseSnOfPFR(sn) {
  sn = sn.substring(2);
  return {
    eoaRewards: formatUnits(parseHexToBigInt(sn.substring(0, 10)).toString(), 9),
    coaRewards: formatUnits(parseHexToBigInt(sn.substring(10, 20)).toString(), 9),
    floor: formatUnits(parseHexToBigInt(sn.substring(20, 30)).toString(), 9),
    rate: parseInt(sn.substring(30, 34), 16),
    para: parseInt(sn.substring(34, 38), 16), 
  };
}

export function pfrParser(arrRule) {
  const out = {
    eoaRewards: formatUnits(arrRule[0], 9),
    coaRewards: formatUnits(arrRule[1], 9),
    floor: formatUnits(arrRule[2], 9),
    rate: formatUnits(arrRule[3], 2),
    para: arrRule[4],
  }

  return out;
}

export function userParser(user) {
  const out = {
    primeKey: {
      pubKey: user[0][0],
      discount: formatUnits(user[0][1], 9),
      gift: formatUnits(user[0][2], 9),
      coupon: formatUnits(user[0][3], 9),
    },
    backupKey: {
      pubKey: user[1][0],
      discount: formatUnits(user[1][1], 9),
      gift: formatUnits(user[1][2], 9),
      coupon: formatUnits(user[1][3], 9),
    },
  }

  return out;
}

export function pfrCodifier(rule) {
  const out = `0x${
    parseUnits(rule.eoaRewards, 9).toString(16).padStart(10, '0') +
    parseUnits(rule.coaRewards, 9).toString(16).padStart(10, '0') +
    parseUnits(rule.floor, 9).toString(16).padStart(10, '0') +
    parseUnits(rule.rate, 2).toString(16).padStart(4, '0') +
    rule.para.toString(16).padStart(4, '0') +
    '0'.padEnd(26, '0')
  }`;

  return out;
}

export async function royaltyTest(addrOfRC, from, to, tx, rate, func) {

  const receipt = await tx.wait();

  const eventAbi = [
    "event Transfer(address indexed from, address indexed to, uint256 value)",
    "event CloneDoc(bytes32 indexed snOfDoc, address indexed body)",
    "event ProxyDoc(bytes32 indexed snOfDoc, address indexed body)",
    "event UpgradeDoc(bytes32 indexed snOfDoc, address indexed body)",
  ];
  
  const iface = new Interface(eventAbi);
  let addr = AddrZero;

  let flag = false;
  
  for (const log of receipt.logs) {
    if (log.address == addrOfRC){
      const parsedLog = iface.parseLog(log);
      if (!flag && parsedLog.name == "Transfer") 
      {
        flag = (
            parsedLog.args[0].toLowerCase() == from.toLowerCase() && 
            parsedLog.args[1].toLowerCase() == to.toLowerCase() && 
            parsedLog.args[2] == (BigInt(rate) * 10n ** 13n)
        );
      }
      if (
          parsedLog.name == "CloneDoc" || 
          parsedLog.name == "ProxyDoc" ||
          parsedLog.name == "UpgradeDoc"
      ) {
        addr = parsedLog.args[1];
      }
    }
  }

  if (flag) {
    console.log(" \u2714 Passed Royalty Test for", func, "\n");
  } else {
    console.log(" \u00D7 FAILED Royalty Test for", func, "\n");
  }

  return addr;
}

export async function getUserNo(rc, signer) {
  const userNo = await rc.connect(signer).getMyUserNo();
  return userNo;
}

export async function getAllUsers(rc, maxSignerNum) {
  const { ethers } = await network.connect();
  const signers = await ethers.getSigners();

  let users = [];

  for (let i = 0; i <= maxSignerNum; i++) {
    const signer = signers[i];
    const userNo = await rc.connect(signer).getMyUserNo();
    users.push(userNo);
    console.log("User_", userNo.toString(), ":", signer.address);
  }
  return users;
}
  