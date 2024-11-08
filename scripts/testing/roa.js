// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseUnits, longDataParser } = require("./utils");

function parseHeadOfDeal(arr) {
  return {
    typeOfDeal: arr[0],
    seqOfDeal: arr[1],
    preSeq: arr[2],
    classOfShare: arr[3],
    seqOfShare: arr[4],
    seller: arr[5], 
  }
};

function parseDeal (arr) {
  return {
    head: parseHeadOfDeal(arr[0]),
    body: {
      buyer: arr[1][0],
      groupOfBuyer: arr[1][1],
      paid: longDataParser(ethers.utils.formatUnits(arr[1][2].toString(), 4)),
      par: longDataParser(ethers.utils.formatUnits(arr[1][3].toString(), 4)),
      distrWeight: arr[1][4],
      flag: arr[1][5],
    },
    hashLock: arr[2],
  }
};

function codifyHeadOfDeal(head) {
  let hexSn = `0x${
    (Number(head.typeOfDeal).toString(16).padStart(2, '0')) +
    (Number(head.seqOfDeal).toString(16).padStart(4, '0')) +
    (Number(head.preSeq).toString(16).padStart(4, '0')) +
    (Number(head.classOfShare).toString(16).padStart(4, '0')) +
    (Number(head.seqOfShare).toString(16).padStart(8, '0')) +
    (Number(head.seller).toString(16).padStart(10, '0')) +
    parseUnits(head.priceOfPaid, 4).padStart(8, '0') +
    parseUnits(head.priceOfPar, 4).padStart(8, '0') +
    (Number(head.closingDeadline).toString(16).padStart(12, '0')) + 
    (Number(head.votingWeight).toString(16).padStart(4, '0'))
  }`;
  return hexSn;
}

module.exports = {
    parseHeadOfDeal,
    codifyHeadOfDeal,
    parseDeal,
};

  