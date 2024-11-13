// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseUnits, parseHexToBigInt } = require('./utils');

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

module.exports = {
    parseSnOfPFR,
    pfrParser,
    pfrCodifier,
};

  