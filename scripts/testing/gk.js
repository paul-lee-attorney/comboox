// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { parseTimestamp, longDataParser } = require("./utils");

const currencies = [
  'USD', 'GBP', 'EUR', 'JPY', 'KRW', 'CNY',
  'AUD', 'CAD', 'CHF', 'ARS', 'PHP', 'NZD', 
  'SGD', 'NGN', 'ZAR', 'RUB', 'INR', 'BRL'
]

const depositOfUsers = async (rc, gk) => {
  const signers = await ethers.getSigners();
  
  for (let i=0; i<7; i++) {
    const userNo = await rc.connect(signers[i]).getMyUserNo();
    const dep = await gk.connect(signers[i]).depositOfMine(userNo);
    console.log('Deposit of User_', userNo, ':', longDataParser(ethers.utils.formatUnits(dep.toString(), 9)), '(GWei). \n');
  }

  const ethOfGK = await ethers.provider.getBalance(gk.address);
  const totalDep = await gk.totalDeposits();
  const ethOfComp = ethOfGK - totalDep;

  console.log('ETH of Comp:', longDataParser(ethers.utils.formatUnits(ethOfComp.toString(), 9)), '(GWei). \n');
}

const parseCompInfo = (arr) => {
  const info = {
    regNum: arr[0],
    regDate: parseTimestamp(arr[1]),
    currency: currencies[arr[2]],
    state: arr[3],
    symbol: ethers.utils.toUtf8String(arr[4]).replace(/\x00/g, ""),
    name: arr[5],
  }

  return info;
}

module.exports = {
  depositOfUsers,
  parseCompInfo,
};

  