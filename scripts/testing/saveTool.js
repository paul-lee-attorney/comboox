// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { join } from "path";
import { readFileSync, writeFileSync } from "fs";

const __dirname = import.meta.dirname;

// ==== Boox Address ====

export function saveBooxAddr(targetName, addr) {

    const booxList = join(__dirname, "boox.json");
  
    const objContractAddrList = JSON.parse(readFileSync(booxList,"utf-8"));
    objContractAddrList[targetName] = addr;
  
    writeFileSync(
      booxList,
      JSON.stringify(objContractAddrList, undefined, 2)
    );

    console.log('save ', targetName, 'with its address: ', addr, "\n");  
};

// ==== CBP ====

export function setUserCBP(userNo, bala) {

  const balaList = join(__dirname, "cbp.json");

  const objBalaList = JSON.parse(readFileSync(balaList,"utf-8"));
  objBalaList[userNo] = bala.toString();

  writeFileSync(
    balaList,
    JSON.stringify(objBalaList, undefined, 2)
  );
};

export function getUserCBP(userNo) {

  const balaList = join(__dirname, "cbp.json");

  const objBalaList = JSON.parse(readFileSync(balaList,"utf-8"));
  const bala = BigInt(objBalaList[userNo]);

  return bala;
};

export function addCBPToUser(amt, userNo) {

  let bala = getUserCBP(userNo);
  bala += amt;

  setUserCBP(userNo, bala);
};

export function minusCBPFromUser(amt, userNo) {

  let bala = getUserCBP(userNo);
  bala -= amt;

  setUserCBP(userNo, bala);
};

export function transferCBP(from, to, amt) {

  let amtInLee = BigInt(amt) * 10n ** 13n;

  minusCBPFromUser(amtInLee, from);
  addCBPToUser(amtInLee, to);
}

// ==== ETH ====

export function setUserDepo(userNo, bala) {

  const balaList = join(__dirname, "eth.json");

  const objBalaList = JSON.parse(readFileSync(balaList,"utf-8"));
  objBalaList[userNo] = bala.toString();

  writeFileSync(
    balaList,
    JSON.stringify(objBalaList, undefined, 2)
  );
};

export function getUserDepo(userNo) {

  const balaList = join(__dirname, "eth.json");

  const objBalaList = JSON.parse(readFileSync(balaList,"utf-8"));
  const bala = BigInt(objBalaList[userNo]);

  return bala;
};

export function addEthToUser(amt, userNo) {

  let bala = getUserDepo(userNo);
  bala += amt;

  setUserDepo(userNo, bala);
};

function minusEthFromUser(amt, userNo) {

  let bala = getUserDepo(userNo);
  bala -= amt;

  setUserDepo(userNo, bala);
};
  