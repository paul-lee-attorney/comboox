// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseUnits, parseTimestamp } = require("./utils");


function grParser(hexRule) {
  const rule = {
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
    establishedDate: parseTimestamp(parseInt(hexRule.substring(46, 58), 16)),
    businessTermInYears: parseInt(hexRule.substring(58, 60), 16).toString(),
    typeOfComp: parseInt(hexRule.substring(60, 62), 16).toString(),
    minVoteRatioOnChain: (Number(parseInt(hexRule.substring(62, 66), 16)) / 100).toFixed(2).toString(),    
  };

  return rule;
}

function grCodifier(rule) {
  const hexGR = `0x${
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
  const rule = {
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
  const hexVr = `0x${
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
  const hexRule = `0x${
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
  const rule = {
    seqOfRule: parseInt(hexRule.substring(2, 6), 16), 
    qtyOfSubRule: parseInt(hexRule.substring(6, 8), 16).toString(),
    seqOfSubRule: parseInt(hexRule.substring(8, 10), 16).toString(),
    removePos: hexRule.substring(10, 12) === '01',
    seqOfPos: parseInt(hexRule.substring(12, 16), 16).toString(),
    titleOfPos: titles[parseInt(hexRule.substring(16, 20), 16) - 1],
    nominator: parseInt(hexRule.substring(20, 30), 16).toString(),
    titleOfNominator: titles[parseInt(hexRule.substring(30, 34), 16) - 1],
    seqOfVR: parseInt(hexRule.substring(34, 38), 16).toString(),
    endDate: parseTimestamp(parseInt(hexRule.substring(38, 50), 16)),
    para: parseInt(hexRule.substring(50, 54), 16).toString(),
    argu: parseInt(hexRule.substring(54, 58), 16).toString(),
    data: parseInt(hexRule.substring(58, 66), 16).toString(),
  };

  return rule;
}

function lrParser(hexLr) {
  const rule = {
    seqOfRule: parseInt(hexLr.substring(2, 6), 16), 
    titleOfIssuer: titles[parseInt(hexLr.substring(6, 10), 16) - 1],
    classOfShare: parseInt(hexLr.substring(10, 14), 16).toString(),
    maxTotalPar: Number('0x' + hexLr.substring(14, 22)).toString(),
    titleOfVerifier: titles[parseInt(hexLr.substring(22, 26), 16) - 1],
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

function alongRuleParser(arr) {
  const out = {
    triggerDate: parseTimestamp(arr[0]),
    effectiveDate: parseTimestamp(arr[1]),
    triggerType: arr[2],
    shareRatioThreshold: arr[3],
    rate: arr[4],
    proRata: arr[5],
  };
  return out;
}

function alongRuleCodifier(rule) {
  const out = `0x${
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

const titles = [
  'Shareholder', 'Chairman', 'ViceChairman', 'ManagintDirector', 'Director', 
  'CEO', 'CFO', 'COO', 'CTO', 'President', 'VicePresident', 'Supervisor', 
  'SeniorManager', 'Manager', 'ViceManager'
];

const positionParser = (arr) => {
  return {
    title: titles[arr[0] - 1],
    seqOfPos: arr[1],
    acct: arr[2],
    nominator: arr[3],
    startDate: parseTimestamp(arr[4]),
    endDate: parseTimestamp(arr[5]),
    seqOfVR: arr[6],
    titleOfNominator: titles[arr[7] - 1],
    argu: arr[8],
  }
};

module.exports = {
    grParser,
    grCodifier,
    vrParser,
    vrCodifier,
    prParser,
    prCodifier,
    lrParser,
    lrCodifier,
    alongRuleParser,
    alongRuleCodifier,
    titles,
    positionParser,
};

  