// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const now = async () => {
  return (await hre.ethers.provider.getBlock()).timestamp;
}

const increaseTime = async (seconds) => {
  await hre.ethers.provider.send("evm_increaseTime", [seconds]);
  await hre.ethers.provider.send("evm_mine");
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
      issueDate: parseInt(sn.substring(22, 34), 16),
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

function grParser(hexRule) {
  let rule = {
    fundApprovalThreshold: parseInt(hexRule.substring(2, 10), 16).toString(),
    basedOnPar: hexRule.substring(10, 12) === '01',
    proposeWeightRatioOfGM: (Number(parseInt(hexRule.substring(12,16), 16)) / 100).toFixed(2).toString(),
    proposeHeadRatioOfMembers: (Number(parseInt(hexRule.substring(16, 20), 16)) / 100).toFixed(2).toString(),
    proposeHeadRatioOfDirectorsInGM: (Number(parseInt(hexRule.substring(20, 24), 16)) / 100).toFixed(2).toString(),
    proposeHeadRatioOfDirectorsInBoard: (Number(parseInt(hexRule.substring(24, 28), 16)) / 100).toFixed(2).toString(),
    maxQtyOfMembers: parseInt(hexRule.substring(28, 32), 16).toString(),
    quorumOfGM: (Number(parseInt(hexRule.substring(32, 36), 16)) / 100).toFixed(2).toString(),
    maxNumOfDirectors: parseInt(hexRule.substring(36, 38), 16).toString(),
    tenureMonOfBoard: parseInt(hexRule.substring(38, 42), 16).toString(),
    quorumOfBoardMeeting: (Number(parseInt(hexRule.substring(42, 46), 16)) / 100).toFixed(2).toString(),
    establishedDate: parseInt(hexRule.substring(46, 58), 16),
    businessTermInYears: parseInt(hexRule.substring(58, 60), 16).toString(),
    typeOfComp: parseInt(hexRule.substring(60, 62), 16).toString(),
    minVoteRatioOnChain: (Number(parseInt(hexRule.substring(62, 66), 16)) / 100).toFixed(2).toString(),    
  };

  return rule;
}

function grCodifier(rule) {
  let hexGR = `0x${
    Number(rule.fundApprovalThreshold).toString(16).padStart(8, '0') +
    (rule.basedOnPar ? '01' : '00') +
    (Number(rule.proposeWeightRatioOfGM) * 100).toString(16).padStart(4, '0') +
    (Number(rule.proposeHeadRatioOfMembers) * 100).toString(16).padStart(4, '0') + 
    (Number(rule.proposeHeadRatioOfDirectorsInGM) * 100).toString(16).padStart(4, '0') + 
    (Number(rule.proposeHeadRatioOfDirectorsInBoard) * 100).toString(16).padStart(4, '0') + 
    Number(rule.maxQtyOfMembers).toString(16).padStart(4, '0') +       
    (Number(rule.quorumOfGM) * 100).toString(16).padStart(4, '0') +       
    Number(rule.maxNumOfDirectors).toString(16).padStart(2, '0') +       
    Number(rule.tenureMonOfBoard).toString(16).padStart(4, '0') +       
    (Number(rule.quorumOfBoardMeeting) * 100).toString(16).padStart(4, '0') +       
    rule.establishedDate.toString(16).padStart(12, '0') + 
    Number(rule.businessTermInYears).toString(16).padStart(2, '0') +                 
    Number(rule.typeOfComp).toString(16).padStart(2, '0')+                 
    (Number(rule.minVoteRatioOnChain) * 100).toString(16).padStart(4, '0')                 
  }`;

  return hexGR;
}

function vrParser(hexVr) {
  let rule = {
    seqOfRule:parseInt(hexVr.substring(2, 6), 16).toString(), 
    qtyOfSubRule:parseInt(hexVr.substring(6, 8), 16).toString(),
    seqOfSubRule:parseInt(hexVr.substring(8, 10), 16).toString(),
    authority: parseInt(hexVr.substring(10, 12), 16).toString(),
    headRatio: (Number(parseInt(hexVr.substring(12, 16), 16)) / 100).toFixed(2).toString(),
    amountRatio: (Number(parseInt(hexVr.substring(16, 20), 16)) / 100).toFixed(2).toString(),
    onlyAttendance: hexVr.substring(20, 22) === '01',
    impliedConsent: hexVr.substring(22, 24) === '01',
    partyAsConsent: hexVr.substring(24, 26) === '01',
    againstShallBuy: hexVr.substring(26, 28) === '01',
    frExecDays: parseInt(hexVr.substring(28, 30), 16).toString(),
    dtExecDays: parseInt(hexVr.substring(30, 32), 16).toString(),
    dtConfirmDays: parseInt(hexVr.substring(32, 34), 16).toString(),
    invExitDays: parseInt(hexVr.substring(34, 36), 16).toString(),
    votePrepareDays: parseInt(hexVr.substring(36, 38), 16).toString(),
    votingDays: parseInt(hexVr.substring(38, 40), 16).toString(),
    execDaysForPutOpt: parseInt(hexVr.substring(40, 42), 16).toString(),
    vetoers: [parseInt(hexVr.substring(42, 52), 16).toString(), parseInt(hexVr.substring(52, 62), 16).toString()],
    para: '0',    
  }
  return rule;
}

function vrCodifier(objVr, seq) {
  let hexVr = `0x${
    (seq.toString(16).padStart(4, '0')) +
    (Number(objVr.qtyOfSubRule).toString(16).padStart(2, '0')) +
    (Number(objVr.seqOfSubRule).toString(16).padStart(2, '0')) +
    (Number(objVr.authority).toString(16).padStart(2, '0')) +
    ((Number(objVr.headRatio) * 100).toString(16).padStart(4, '0')) +
    ((Number(objVr.amountRatio) * 100).toString(16).padStart(4, '0')) +
    (objVr.onlyAttendance ? '01' : '00' )+
    (objVr.impliedConsent ? '01' : '00' )+
    (objVr.partyAsConsent ? '01' : '00' )+
    (objVr.againstShallBuy ? '01' : '00' )+
    (Number(objVr.frExecDays).toString(16).padStart(2, '0')) +
    (Number(objVr.dtExecDays).toString(16).padStart(2, '0')) +
    (Number(objVr.dtConfirmDays).toString(16).padStart(2, '0')) +
    (Number(objVr.invExitDays).toString(16).padStart(2, '0')) +
    (Number(objVr.votePrepareDays).toString(16).padStart(2, '0')) +
    (Number(objVr.votingDays).toString(16).padStart(2, '0')) +
    (Number(objVr.execDaysForPutOpt).toString(16).padStart(2, '0')) +
    (Number(objVr.vetoers[0]).toString(16).padStart(10, '0')) +
    (Number(objVr.vetoers[1]).toString(16).padStart(10, '0')) +
    '0000' 
  }`;
  return hexVr;
}

function prCodifier(rule, seq) {
  let hexRule = `0x${
    (seq.toString(16).padStart(4, '0')) +
    (Number(rule.qtyOfSubRule).toString(16).padStart(2, '0')) +
    (Number(rule.seqOfSubRule).toString(16).padStart(2, '0')) +
    (rule.removePos ? '01' : '00' ) +
    (Number(rule.seqOfPos).toString(16).padStart(4, '0')) +
    (Number(rule.titleOfPos).toString(16).padStart(4, '0')) +
    (Number(rule.nominator).toString(16).padStart(10, '0')) +
    (Number(rule.titleOfNominator).toString(16).padStart(4, '0')) +
    (Number(rule.seqOfVR).toString(16).padStart(4, '0')) +
    (rule.endDate.toString(16).padStart(12, '0')) +
    '0'.padStart(16, '0')
  }`;
  return hexRule;
} 

function prParser(hexRule) {
  let rule = {
    seqOfRule: parseInt(hexRule.substring(2, 6), 16), 
    qtyOfSubRule: parseInt(hexRule.substring(6, 8), 16).toString(),
    seqOfSubRule: parseInt(hexRule.substring(8, 10), 16).toString(),
    removePos: hexRule.substring(10, 12) === '01',
    seqOfPos: parseInt(hexRule.substring(12, 16), 16).toString(),
    titleOfPos: parseInt(hexRule.substring(16, 20), 16).toString(),
    nominator: parseInt(hexRule.substring(20, 30), 16).toString(),
    titleOfNominator: parseInt(hexRule.substring(30, 34), 16).toString(),
    seqOfVR: parseInt(hexRule.substring(34, 38), 16).toString(),
    endDate: parseInt(hexRule.substring(38, 50), 16),
    para: parseInt(hexRule.substring(50, 54), 16).toString(),
    argu: parseInt(hexRule.substring(54, 58), 16).toString(),
    data: parseInt(hexRule.substring(58, 66), 16).toString(),
  };

  return rule;
}

function lrParser(hexLr) {
  let rule = {
    seqOfRule: parseInt(hexLr.substring(2, 6), 16), 
    titleOfIssuer: parseInt(hexLr.substring(6, 10), 16).toString(),
    classOfShare: parseInt(hexLr.substring(10, 14), 16).toString(),
    maxTotalPar: Number('0x' + hexLr.substring(14, 22)).toString(),
    titleOfVerifier: parseInt(hexLr.substring(22, 26), 16).toString(),
    maxQtyOfInvestors: parseInt(hexLr.substring(26, 30), 16).toString(),
    ceilingPrice: ethers.utils.formatUnits(BigInt('0x' + hexLr.substring(30, 38)), 4),
    floorPrice: ethers.utils.formatUnits(BigInt('0x' + hexLr.substring(38, 46)), 4),
    lockupDays: parseInt(hexLr.substring(46, 50), 16).toString(),
    offPrice: ethers.utils.formatUnits(BigInt('0x' + hexLr.substring(50, 54)), 4),
    votingWeight: parseInt(hexLr.substring(54, 58), 16).toString(),
    distrWeight: parseInt(hexLr.substring(58, 62), 16).toString(),
  }
  return rule;
}

function lrCodifier( objLr, seq) {
  const hexLr = `0x${
    (Number(seq).toString(16).padStart(4, '0')) +
    (Number(objLr.titleOfIssuer).toString(16).padStart(4, '0')) +
    (Number(objLr.classOfShare).toString(16).padStart(4, '0')) +
    (Number(objLr.maxTotalPar).toString(16).padStart(8, '0')) +
    (Number(objLr.titleOfVerifier).toString(16).padStart(4, '0')) +
    (Number(objLr.maxQtyOfInvestors).toString(16).padStart(4, '0')) +
    (parseUnits(objLr.ceilingPrice, 4).padStart(8, '0')) +
    (parseUnits(objLr.floorPrice, 4).padStart(8, '0')) +
    (Number(objLr.lockupDays).toString(16).padStart(4, '0')) +
    (parseUnits(objLr.offPrice, 4).padStart(4, '0')) +
    Number(objLr.votingWeight).toString(16).padStart(4, '0') +
    Number(objLr.distrWeight).toString(16).padStart(4, '0') +
    '0000'
  }`;
  return hexLr;
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

function alongRuleCodifier(rule) {
  let out = `0x${
    rule.triggerDate.toString(16).padStart(12, '0') +
    Number(rule.effectiveDays).toString(16).padStart(4, '0') +
    Number(rule.triggerType).toString(16).padStart(2, '0') +
    parseUnits(rule.shareRatioThreshold, 2).padStart(4, '0') +
    parseUnits(rule.rate, 4).padStart(8, '0') +
    (rule.proRata ? '01' : '00') +
    '0'.padEnd(32, '0')
  }`;
  return out;
}

const Bytes32Zero = `0x${'0'.padEnd(64,'0')}`;
const AddrZero = `0x${'0'.padEnd(40,'0')}`;

function parseHeadOfDeal(arr) {
  return {
    typeOfDeal: arr[0],
    seqOfDeal: arr[1],
    preSeq: arr[2],
    classOfShare: arr[3],
    seqOfShare: arr[4],
    seller: arr[5], 
  }
}

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
    now,
    increaseTime,
    parseTimestamp,
    codifyHeadOfShare,
    parseHeadOfShare,
    parseShare,
    grParser,
    grCodifier,
    vrParser,
    vrCodifier,
    prParser,
    prCodifier,
    lrParser,
    lrCodifier,
    longDataParser,
    pfrParser,
    pfrCodifier,
    alongRuleCodifier,
    parseUnits,
    Bytes32Zero,
    AddrZero,
    codifyHeadOfDeal,
};

  