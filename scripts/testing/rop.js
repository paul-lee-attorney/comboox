// SPDX-License-Identifier: UNLICENSED

const { parseTimestamp, longDataParser } = require("./utils");

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const states = [
  'Plending', 'Issued', 'Locked', 'Released', 'Executed', 'Revoked'
];

function parsePledge(arr) {
  return {
    head: {
      seqOfShare: arr[0][0],
      seqOfPld: arr[0][1],
      createDate: parseTimestamp(arr[0][2]),
      daysToMaturity: arr[0][3],
      guaranteeDays: arr[0][4],
      creditor: arr[0][5],
      debtor: arr[0][6],
      pledgor: arr[0][7],
      state: states[arr[0][8]],
    },
    body: {
      paid: longDataParser(ethers.utils.formatUnits((arr[1][0]).toString(), 4)),
      par: longDataParser(ethers.utils.formatUnits((arr[1][1]).toString(), 4)),
      guaranteedAmt: longDataParser(ethers.utils.formatUnits((arr[1][2]).toString(), 4)),
      preSeq: arr[1][3],
      execDays: arr[1][4],
      para: arr[1][5],
      argu: arr[1][6],
    },
    hashLock: arr[2],
  };
}

function codifyHeadOfPledge(head) {
  let sn = `0x${
    Number(head.seqOfShare).toString(16).padStart(8, '0') +
    Number(head.seqOfPld).toString(16).padStart(4, '0') +
    Number(head.createDate).toString(16).padStart(12, '0') +
    Number(head.daysToMaturity).toString(16).padStart(4, '0') +
    Number(head.guaranteeDays).toString(16).padStart(4, '0') +
    Number(head.creditor).toString(16).padStart(10, '0') +
    Number(head.debtor).toString(16).padStart(10, '0') +
    Number(head.pledgor).toString(16).padStart(10, '0') +
    Number(head.state).toString(16).padStart(2, '0')
  }`;

  return sn;
}

module.exports = {
    codifyHeadOfPledge,
    parsePledge,
};

  