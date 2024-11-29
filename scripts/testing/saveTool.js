// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const path = require("path");
const fs = require("fs");

function saveBooxAddr(targetName, addr) {

    const booxList = path.join(__dirname, "boox.json");
  
    const objContractAddrList = JSON.parse(fs.readFileSync(booxList,"utf-8"));
    objContractAddrList[targetName] = addr;
  
    fs.writeFileSync(
      booxList,
      JSON.stringify(objContractAddrList, undefined, 2)
    );

    console.log('save ', targetName, 'with its address: ', addr, "\n");  
};

function setUserCBP(userNo, bala) {

  const balaList = path.join(__dirname, "cbp.json");

  const objBalaList = JSON.parse(fs.readFileSync(balaList,"utf-8"));
  objBalaList[userNo] = bala.toString();

  fs.writeFileSync(
    balaList,
    JSON.stringify(objBalaList, undefined, 2)
  );
};

function getUserCBP(userNo) {

  const balaList = path.join(__dirname, "cbp.json");

  const objBalaList = JSON.parse(fs.readFileSync(balaList,"utf-8"));
  const bala = BigInt(objBalaList[userNo]);

  return bala;
};


function addCBPToUser(amt, userNo) {

  let bala = getUserCBP(userNo);
  bala += amt;

  setUserCBP(userNo, bala);
};

function minusCBPFromUser(amt, userNo) {

  let bala = getUserCBP(userNo);
  bala -= amt;

  setUserCBP(userNo, bala);
};

function transferCBP(from, to, amt) {

  let amtInLee = BigInt(amt) * 10n ** 13n;

  minusCBPFromUser(amtInLee, from);
  addCBPToUser(amtInLee, to);
}

module.exports = {
    transferCBP,
    setUserCBP,
    getUserCBP,
    addCBPToUser,
    minusCBPFromUser,
    saveBooxAddr,
};
  