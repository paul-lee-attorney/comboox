// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { getUserDepo } = require("./saveTool");
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

    const depExpected = getUserDepo(userNo.toString());
    expect(depExpected).to.equal(BigInt(dep.toString()));

    console.log('Deposit of User_', userNo, ':', longDataParser(ethers.utils.formatUnits(dep.toString(), 9)), '(GWei). \n');
  }

  const ethOfGK = await ethers.provider.getBalance(gk.address);
  const totalDep = await gk.totalDeposits();
  const ethOfComp = BigInt(ethOfGK.toString()) - BigInt(totalDep.toString());

  const depExpected = getUserDepo("8");    
  expect(depExpected).to.equal(ethOfComp);

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

const usdOfUsers = async (usdc, addrOfCashier) => {
  const signers = await ethers.getSigners();
  let bala = 0n;
  for (let i=0; i<7; i++) {  
    bala = await usdc.balanceOf(signers[i].address);
    console.log("Balance Of Signer", i, ":", bala);
  }
  bala = await usdc.balanceOf(addrOfCashier);
  console.log("Balance Of Comp:", bala);
}

module.exports = {
  depositOfUsers,
  parseCompInfo,
  usdOfUsers,
};

  