// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import {network} from "hardhat";
// import { parseUnits as } from "ethers";

const now = async () => {
  const { ethers } = await network.connect();
  return (await ethers.provider.getBlock()).timestamp;
}

const increaseTime = async (seconds) => {
  const { ethers } = await network.connect();
  await ethers.provider.send("evm_increaseTime", [seconds]);
  await ethers.provider.send("evm_mine");
  console.log('Forward On-Chain time for', seconds, 'seconds \n');
  console.log('Current On-Chain Date:', parseTimestamp(await now()), '\n');
}

function parseTimestamp (stamp) {
  return (new Date(Number(stamp) * 1000)).toISOString();
}

function longDataParser(data) {
  if (data == '0')
    return '-';
  else
    return data.replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",");
}

// function parseUnits(input, dec) {
//   const output = parseUnits(input, dec).toString(16);
//   return output.substring(2);
// }

function parseHexToBigInt(input) {
  if (!input.startsWith('0x')) {
    input = '0x' + input;
  }

  return BigInt(input);
}

const Bytes32Zero = `0x${'0'.padEnd(64,'0')}`;
const AddrZero = `0x${'0'.padEnd(40,'0')}`;

const trimAddr = (addr) => {
  return addr.toLowerCase().substring(2);
}


export {
  now,
  increaseTime,
  parseTimestamp,
  longDataParser,
  // parseUnits,
  parseHexToBigInt,
  trimAddr,
  Bytes32Zero,
  AddrZero,
};

  