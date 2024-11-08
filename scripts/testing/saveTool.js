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
  

module.exports = {
    saveBooxAddr,
};
  