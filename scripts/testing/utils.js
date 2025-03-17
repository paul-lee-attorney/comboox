// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const now = async () => {
  return (await hre.ethers.provider.getBlock()).timestamp;
}

const increaseTime = async (seconds) => {
  await hre.ethers.provider.send("evm_increaseTime", [seconds]);
  await hre.ethers.provider.send("evm_mine");
  console.log('Forward On-Chain time for', seconds, 'seconds \n');
  console.log('Current On-Chain Date:', parseTimestamp(await now()), '\n');
}

function parseTimestamp (stamp) {
  return (new Date(stamp * 1000)).toISOString();
}

function longDataParser(data) {
  if (data == '0')
    return '-';
  else
    return data.replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",");
}

function parseUnits(input, dec) {
  const output = ethers.utils.parseUnits(input.toString(), dec).toHexString();
  return output.substring(2);
}

function parseHexToBigInt(input) {
  if (!input.startsWith('0x')) {
    input = '0x' + input;
  }

  const bigNumber = ethers.BigNumber.from(input);

  return BigInt(bigNumber.toString());
}

const Bytes32Zero = `0x${'0'.padEnd(64,'0')}`;
const AddrZero = `0x${'0'.padEnd(40,'0')}`;

const trimAddr = (addr) => {
  return addr.toLowerCase().substring(2);
}


module.exports = {
    now,
    increaseTime,
    parseTimestamp,
    longDataParser,
    parseUnits,
    parseHexToBigInt,
    trimAddr,
    Bytes32Zero,
    AddrZero,
};

  