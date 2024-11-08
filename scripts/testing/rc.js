// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseUnits } = require('./utils');

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
    pfrParser,
    pfrCodifier,
};

  