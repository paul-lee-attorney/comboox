// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { formatUnits } from "ethers"; 
import { parseTimestamp, longDataParser, parseHexToBigInt } from "./utils";

const parseFromSn = (sn) => {
  sn = sn.substring(2);
  return {
    from: sn.substring(0, 40),
    buyer: parseInt(sn.substring(40, 50), 16),
    groupRep: parseInt(sn.substring(50, 60), 16),
    classOfShare: parseInt(sn.substring(60, 64), 16), 
  };
}

const parseToSn = (sn) => {
  sn = sn.substring(2);
  return {
    to: sn.substring(0, 40),
    seller: parseInt(sn.substring(40, 50), 16),
    seqOfShare: parseInt(sn.substring(50, 58), 16),
    state: parseInt(sn.substring(58, 60), 16),
    inEth: sn.substring(60, 62) == '01',
    isOffer: sn.substring(62, 64) == '01',
  };
}

const parseQtySn = (sn) => {
  sn = sn.substring(2);
  return {
    paid: longDataParser(formatUnits(parseHexToBigInt(sn.substring(0, 16)).toString(), 4)),
    price: longDataParser(formatUnits(parseInt(sn.substring(16, 24), 16), 4)),
    votingWeight: parseInt(sn.substring(24, 28), 16),
    distrWeight: parseInt(sn.substring(28, 32), 16),
    consideration: longDataParser(formatUnits(parseHexToBigInt(sn.substring(32, 64)).toString(), 8)),
  };
}

const parseNode = (sn) => {
  sn = sn.substring(2);
  return {
    prev: parseInt(sn.substring(0, 8), 16),
    next: parseInt(sn.substring(8, 16), 16),
    issuer: parseInt(sn.substring(16, 26), 16),
    paid: formatUnits(parseHexToBigInt(sn.substring(26, 42)).toString(), 4),
    price: formatUnits(parseHexToBigInt(sn.substring(42, 50)).toString(), 4),
    expireDate: parseTimestamp(parseInt(sn.substring(50, 62), 16)),
    isOffer: (sn.substring(62, 64) == '01'),
  };
}

const parseData = (sn) => {
  sn = sn.substring(2);
  return {
    classOfShare: parseInt(sn.substring(0, 4), 16),
    seqOfShare: parseInt(sn.substring(4, 12), 16),
    groupRep: parseInt(sn.substring(12, 22), 16),
    votingWeight: parseInt(sn.substring(22, 26), 16),
    distrWeight: parseInt(sn.substring(26, 30), 16),
    margin: formatUnits(parseHexToBigInt(sn.substring(30, 62)).toString(), 8),
    inEth: (sn.substring(62, 64) == '01'),
  };
}

const parseOrder = (arr) => {
  return {
    node: {
      prev: arr[0][0],
      next: arr[0][1],
      issuer: arr[0][2],
      paid: longDataParser(formatUnits(arr[0][3].toString(), 4)),
      price: formatUnits(arr[0][4], 4),
      expireDate: parseTimestamp(arr[0][5]),
      isOffer: arr[0][6],
    },
    data: {
      classOfShare: arr[1][0],
      seqOfShare: arr[1][1],
      groupRep: arr[1][2],
      votingWeight: arr[1][3],
      distrWeight: arr[1][4],
      margin: longDataParser(formatUnits(arr[1][5].toString(), 8)),
      inEth: arr[1][6],
      pubKey: arr[1][7],
      date: arr[1][8],
      issueDate: parseTimestamp(arr[1][9]),
    },
  };
}

export {
    parseFromSn,
    parseToSn,
    parseQtySn,
    parseData,
    parseNode,
    parseOrder,
};

  