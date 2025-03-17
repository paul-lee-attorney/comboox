// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseTimestamp, longDataParser, parseHexToBigInt } = require("./utils");

const stateOfInvestor = [
  'Pending', 'Approved', 'Revoked'
]

const parseInvestor = (arr) => {
  return {
    userNo: arr[0],
    groupRep: arr[1],
    regDate: parseTimestamp(arr[2]),
    verifier: arr[3],
    approveDate: parseTimestamp(arr[4]),
    approved: stateOfInvestor[arr[6]],
    idHash: arr[7],
  };
}

const parseDeal = (sn) => {
  sn = sn.substring(2);
  return {
    classOfShare: parseInt(sn.substring(0, 4), 16),
    seqOfShare: parseInt(sn.substring(4, 12), 16),
    buyer: parseInt(sn.substring(12, 22), 16),
    groupRep: parseInt(sn.substring(22, 32), 16),
    paid: longDataParser(ethers.utils.formatUnits(parseHexToBigInt(sn.substring(32, 48)).toString(), 4)),
    price: longDataParser(ethers.utils.formatUnits(parseInt(sn.substring(48, 56), 16), 4)),
    votingWeight: parseInt(sn.substring(56, 60), 16),
    distrWeight: parseInt(sn.substring(60, 64), 16),
  };
}

const parseNode = (sn) => {
  sn = sn.substring(2);
  return {
    prev: parseInt(sn.substring(0, 8), 16),
    next: parseInt(sn.substring(8, 16), 16),
    issuer: parseInt(sn.substring(16, 26), 16),
    paid: ethers.utils.formatUnits(parseHexToBigInt(sn.substring(26, 42)).toString(), 4),
    price: ethers.utils.formatUnits(parseHexToBigInt(sn.substring(42, 50)).toString(), 4),
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
    margin: ethers.utils.formatUnits(parseHexToBigInt(sn.substring(30, 62)).toString(), 18),
    inEth: (sn.substring(62, 64) == '01'),
  };
}

const parseOrder = (arr) => {
  return {
    node: {
      prev: arr[0][0],
      next: arr[0][1],
      issuer: arr[0][2],
      paid: longDataParser(ethers.utils.formatUnits(arr[0][3].toString(), 4)),
      price: ethers.utils.formatUnits(arr[0][4], 4),
      expireDate: parseTimestamp(arr[0][5]),
      isOffer: arr[0][6],
    },
    data: {
      classOfShare: arr[1][0],
      seqOfShare: arr[1][1],
      groupRep: arr[1][2],
      votingWeight: arr[1][3],
      distrWeight: arr[1][4],
      margin: longDataParser(ethers.utils.formatUnits(arr[1][5].toString(), 18)),
      state: arr[1][6]
    },
  };
}

module.exports = {
    parseInvestor,
    parseDeal,
    parseNode,
    parseData,
    parseOrder,
};

  