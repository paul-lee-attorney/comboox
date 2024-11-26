// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { getROS } = require('./boox');
const { parseUnits, parseTimestamp, longDataParser } = require('./utils');

const printShare = async (ros, seqOfShare) => {
  const share = parseShare(await ros.getShare(seqOfShare));
  console.log('Share No:', seqOfShare, ':', share, '\n');
}


const printShares = async (ros) => {
  const shares = (await ros.getSharesList()).map(v => {
    let share = parseShare(v);
    return({
      classOfShare: share.head.class,
      seqOfShare: share.head.seqOfShare,
      shareholder: share.head.shareholder,
      paid: share.body.paid,
      par: share.body.par,
      cleanPaid: share.body.cleanPaid,      
    });
  });
  console.log('Shares of the Comp:', shares, '\n');
}

const getLatestShare = async (ros) => {
  const list = (await ros.getSeqListOfShares()).map(v => parseInt(v));
  const seqOfShare = list[list.length - 1];
  const share = parseShare(await ros.getShare(seqOfShare));

  return share;
}

function codifyHeadOfShare(head) {
    const sn = `0x${
      head.class.toString(16).padStart(4, '0') +
      head.seqOfShare.toString(16).padStart(8, '0') +
      head.preSeq.toString(16).padStart(8, '0') +
      head.issueDate.toString(16).padStart(12, '0') +
      head.shareholder.toString(16).padStart(10, '0') +
      parseUnits(head.priceOfPaid, 4).padStart(8, '0') +
      parseUnits(head.priceOfPar, 4).padStart(8, '0') +
      head.votingWeight.toString(16).padStart(4, '0') +
      '00'
    }`;

    return sn;
}

function parseHeadOfShare(sn) {
    const head= {
      class: parseInt(sn.substring(2, 6), 16),
      seqOfShare: parseInt(sn.substring(6, 14), 16),
      preSeq: parseInt(sn.substring(14, 22), 16),
      issueDate: parseTimestamp(parseInt(sn.substring(22, 34), 16)),
      shareholder: parseInt(sn.substring(34, 44), 16),
      priceOfPaid: ethers.utils.formatUnits(parseInt(sn.substring(44, 52), 16), 4),
      priceOfPar: ethers.utils.formatUnits(parseInt(sn.substring(52, 60), 16), 4),
      votingWeight: parseInt(sn.substring(60, 64), 16)
    };
  
    return head
};

function parseShare(arr) {
  return {
    head: {
      class: arr[0][0],
      seqOfShare: arr[0][1],
      preSeq: arr[0][2],
      issueDate: parseTimestamp(arr[0][3]),
      shareholder: arr[0][4],
      priceOfPaid: ethers.utils.formatUnits(arr[0][5], 4),
      priceOfPar: ethers.utils.formatUnits(arr[0][6], 4),
      votingWeight: arr[0][7],
      argu: arr[0][8],
    },
    body: {
      payInDeadline: parseTimestamp(arr[1][0]),
      paid: longDataParser(ethers.utils.formatUnits(arr[1][1].toString(), 4)),
      par: longDataParser(ethers.utils.formatUnits(arr[1][2].toString(), 4)),
      cleanPaid: longDataParser(ethers.utils.formatUnits(arr[1][3].toString(), 4)),
      distrWeight: arr[1][4],
    },
  };
}

async function obtainNewShare(tx) {

  const ros = await getROS();
  const receipt = await tx.wait();

  const eventAbi = [
    "event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par)",
    "event PayInCapital(uint256 indexed seqOfShare, uint indexed amount)",
    "event SubAmountFromShare(uint256 indexed seqOfShare, uint indexed paid, uint indexed par)",
    "event DeregisterShare(uint256 indexed seqOfShare)",
    "event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid)",
    "event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid)",
    "event IncreaseEquityOfClass(bool indexed isIncrease, uint indexed class, uint indexed amt)",
  ];
  
  const iface = new ethers.utils.Interface(eventAbi);
  let seqOfShare = 0;
  let share = {};
  
  for (const log of receipt.logs) {
    if (log.address == ros.address) {
      try {
        const parsedLog = iface.parseLog(log);
        
        if (parsedLog.name == "IssueShare") {
          seqOfShare= parseHeadOfShare(parsedLog.args[0]).seqOfShare;          
        }
      } catch (err) {
        console.log("Parse Log Error:", err);
      }
    }
  }

  if (seqOfShare > 0) {
    share = parseShare(await ros.getShare(seqOfShare));
  }

  return share;

}

module.exports = {
    printShare,
    printShares,
    codifyHeadOfShare,
    parseHeadOfShare,
    parseShare,
    obtainNewShare,
    getLatestShare,
};

  