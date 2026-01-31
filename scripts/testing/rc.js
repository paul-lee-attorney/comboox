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

export async function cbpOfUsers(rc, addrOfGK) {
  const {ethers} = await network.connect();
  const signers = await ethers.getSigners();
  for (let i=0; i<7; i++) {
    const userNo = await rc.connect(signers[i]).getMyUserNo();
    const bala = await rc.balanceOf(signers[i].address);

    const balaExpected = getUserCBP(userNo.toString());
    expect(balaExpected).to.equal(BigInt(bala.toString()));

    console.log('CBP Balance of User_', userNo, ':', longDataParser(formatUnits(bala.toString(), 9)), '(GLee). \n');
  }
  if (addrOfGK != AddrZero) {
    const cbpOfComp = await rc.balanceOf(addrOfGK);

    const cbpOfCompExpected = getUserCBP("8");
    expect(cbpOfCompExpected).to.equal(BigInt(cbpOfComp.toString()));

    console.log('CBP Balance of Comp:', longDataParser(formatUnits(cbpOfComp.toString(), 9)), '(GLee). \n');
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
    "event Transfer(address indexed from, address indexed to, uint256 indexed value)",
    "event CreateDoc(bytes32 indexed snOfDoc, address indexed body)",
  ];
  
  const iface = new Interface(eventAbi);
  let addr = AddrZero;

  let flag = false;
  
  for (const log of receipt.logs) {
    if (log.address == addrOfRC) {
      try {
        const parsedLog = iface.parseLog(log);
        
        if (parsedLog.name == "CreateDoc") {
          addr = parsedLog.args[1];
        } else if (parsedLog.name == "Transfer") {
          flag = (parsedLog.args[0] == from && parsedLog.args[1] == to && 
              BigInt(parsedLog.args[2]) == (BigInt(rate) * 10n ** 13n));
        }
      } catch (err) {
        console.log("Parse Log Error:", err);
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

// export default {
//     cbpOfUsers,
//     parseSnOfPFR,
//     pfrParser,
//     pfrCodifier,
//     royaltyTest,
//     userParser,
// };

  