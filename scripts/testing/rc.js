// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { getRC, getGK } = require('./boox');
const { parseUnits, parseHexToBigInt, AddrZero } = require('./utils');

function parseSnOfPFR(sn) {
  sn = sn.substring(2);
  return {
    eoaRewards: ethers.utils.formatUnits(parseHexToBigInt(sn.substring(0, 10)).toString(), 9),
    coaRewards: ethers.utils.formatUnits(parseHexToBigInt(sn.substring(10, 20)).toString(), 9),
    floor: ethers.utils.formatUnits(parseHexToBigInt(sn.substring(20, 30)).toString(), 9),
    rate: parseInt(sn.substring(30, 34), 16),
    para: parseInt(sn.substring(34, 38), 16), 
  };
}

function pfrParser(arrRule) {
  const out = {
    eoaRewards: ethers.utils.formatUnits(arrRule[0], 9),
    coaRewards: ethers.utils.formatUnits(arrRule[1], 9),
    floor: ethers.utils.formatUnits(arrRule[2], 9),
    rate: ethers.utils.formatUnits(arrRule[3], 2),
    para: arrRule[4],
  }

  return out;
}

function pfrCodifier(rule) {
  const out = `0x${
    parseUnits(rule.eoaRewards, 9).padStart(10, '0') +
    parseUnits(rule.coaRewards, 9).padStart(10, '0') +
    parseUnits(rule.floor, 9).padStart(10, '0') +
    parseUnits(rule.rate, 2).padStart(4, '0') +
    rule.para.toString(16).padStart(4, '0') +
    '0'.padEnd(26, '0')
  }`;

  return out;
}

async function royaltyTest(addrOfRC, from, to, tx, rate, func) {

  const receipt = await tx.wait();

  const eventAbi = [
    "event Transfer(address indexed from, address indexed to, uint256 indexed value)",
    "event CreateDoc(bytes32 indexed snOfDoc, address indexed body)",
  ];
  
  const iface = new ethers.utils.Interface(eventAbi);
  let addr = AddrZero;
  
  for (const log of receipt.logs) {
    if (log.address == addrOfRC) {
      try {
        const parsedLog = iface.parseLog(log);
        
        if (parsedLog.name == "CreateDoc") {
          addr = parsedLog.args[1];
        } else if (parsedLog.name == "Transfer") {
          expect(parsedLog.args[0]).to.equal(from);
          expect(parsedLog.args[1]).to.equal(to);
          expect(parsedLog.args[2]).to.equal(BigNumber.from(rate * 10n ** 13n));
          console.log("Passed Royalty Test for", func, "\n");
        }
      } catch (err) {
        console.log("Parse Log Error:", err);
      }
    }
  }

  return addr;
}

module.exports = {
    parseSnOfPFR,
    pfrParser,
    pfrCodifier,
    royaltyTest,
};

  