// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { formatUnits, parseUnits } from "ethers";
import { longDataParser } from "./utils";

function getDealValue(priceInCent, paidInDollar, centPrice) {
  return priceInCent * paidInDollar * centPrice;
}

function parseHeadOfDeal(arr) {
  return {
    typeOfDeal: arr[0],
    seqOfDeal: arr[1],
    preSeq: arr[2],
    classOfShare: arr[3],
    seqOfShare: arr[4],
    seller: arr[5],
    priceOfPaid: Number(formatUnits((arr[6]).toString(), 4)),
    priceOfPar: arr[7],
    closingDeadline: arr[8],
    votingWeight: arr[9],
  }
};

function parseDeal (arr) {
  return {
    head: parseHeadOfDeal(arr[0]),
    body: {
      buyer: arr[1][0],
      groupOfBuyer: arr[1][1],
      paid: longDataParser(formatUnits(arr[1][2].toString(), 4)),
      par: longDataParser(formatUnits(arr[1][3].toString(), 4)),
      state: arr[1][4],
      para: arr[1][5],
      distrWeight: arr[1][6],
      flag: arr[1][7],
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
    parseUnits(head.priceOfPaid.toString(), 4).toString(16).padStart(8, '0') +
    parseUnits(head.priceOfPar.toString(), 4).toString(16).padStart(8, '0') +
    (Number(head.closingDeadline).toString(16).padStart(12, '0')) + 
    (Number(head.votingWeight).toString(16).padStart(4, '0'))
  }`;
  return hexSn;
}

export {
    getDealValue,
    parseHeadOfDeal,
    codifyHeadOfDeal,
    parseDeal,
};

  