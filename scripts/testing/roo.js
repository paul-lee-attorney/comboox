// SPDX-License-Identifier: UNLICENSED

const { parseTimestamp, parseUnits, longDataParser } = require("./utils");

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const typeOfOpt = [
    'Call @ Price', 'Put @ Price', 'Call @ ROE', 'Put @ ROE', 
    'Call @ Price & Cnds', 'Put @ Price & Cnds', 'Call @ ROE & Cnds', 'Put @ ROE & Cnds'
];

const stateOfOpt = [
    'Pending', 'Issued', 'Executed', 'Closed'
];

const logicOpr = [
    'ZeroPoint',  '&', '||', '=', '!=', '&&', '||', '&|', '|&',
    '==', '!=!=', '=!=', '&=', '=&', '|=', '=|', 
    '&=', '!=&', '|!=', '!=|'
];

const compOpr = [
    'ZeroPoint', '==', '!=', '>', '<', '>=', '<='
]

const stateOfSwap = [
    'Pending', 'Issued', 'Closed', 'Terminated'
]

function parseSwap(arr) {
    return {
        seqOfSwap: arr[0],
        seqOfPledge: arr[1],
        paidOfPledge: longDataParser(ethers.utils.formatUnits(arr[2].toString(), 4)),
        seqOfTarget: arr[3],
        paidOfTarget: longDataParser(ethers.utils.formatUnits(arr[4].toString(), 4)),
        priceOfDeal: ethers.utils.formatUnits(arr[5].toString(), 4),
        isPutOpt: arr[6],
        state: stateOfSwap[arr[7]],
    };
}

function parseOracle(arr) {
    return {
        timestamp: parseTimestamp(arr[0]),
        rate: arr[1],
        data1: longDataParser(ethers.utils.formatUnits(arr[2].toString(), 4)),
        data2: longDataParser(ethers.utils.formatUnits(arr[3].toString(), 4)),
        data3: longDataParser(ethers.utils.formatUnits(arr[4].toString(), 4)),       
    };
}

function parseOption(arr) {
    return {
        head: {
            seqOfOpt: arr[0][0],
            typeOfOpt: arr[0][1],
            classOfShare: arr[0][2],
            rate: Number(arr[0][3]) / 10000,
            issueDate: arr[0][4],
            triggerDate: arr[0][5],
            execDays: arr[0][6],
            closingDays: arr[0][7],
            obligor: arr[0][8],
        },
        cond: {
            seqOfCond: arr[1][0],
            logicOpr: arr[1][1],
            compOpr1: arr[1][2],
            para1: Number(arr[1][3]) / 10000,
            compOpr2: arr[1][4],
            para2: Number(arr[1][5]) / 10000,
            compOpr3: arr[1][6],
            para3: arr[1][7],
        },
        body: {
            closingDeadline: arr[2][0],
            rightholder: arr[2][1],
            paid: Number(arr[2][2]) / 10000,
            par: Number(arr[2][3]) / 10000,
            state: stateOfOpt[arr[2][4]],
            para: arr[2][5],
            argu: arr[2][6],
        },
    };
}

function codifyHeadOfOption(head) {
    const out = `0x${
      Number(head.seqOfOpt).toString(16).padStart(8, '0') +
      Number(head.typeOfOpt).toString(16).padStart(2, '0') +
      Number(head.classOfShare).toString(16).padStart(4, '0') +
      parseUnits(head.rate, 4).padStart(8, '0') +
      head.issueDate.toString(16).padStart(12, '0') +
      head.triggerDate.toString(16).padStart(12, '0') +
      Number(head.execDays).toString(16).padStart(4, '0') +
      Number(head.closingDays).toString(16).padStart(4, '0') +
      Number(head.obligor).toString(16).padStart(10, '0')
    }`;
    return out;
}

function codifyCond(cond) {
    const out = `0x${
      Number(cond.seqOfCond).toString(16).padStart(8, '0') +
      Number(cond.logicOpr).toString(16).padStart(2, '0') +
      Number(cond.compOpr1).toString(16).padStart(2, '0') +
      parseUnits(cond.para1, 4).padStart(16, '0') +
      Number(cond.compOpr2).toString(16).padStart(2, '0') +
      parseUnits(cond.para2, 4).padStart(16, '0') +
      Number(cond.compOpr3).toString(16).padStart(2, '0') +
      parseUnits(cond.para3, 4).padStart(16, '0')
    }`;
    return out;
  }
    
module.exports = {
    parseSwap,
    parseOracle,
    codifyHeadOfOption,
    parseOption,
    codifyCond,
};

