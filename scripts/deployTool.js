// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const path = require("path");
const fs = require("fs");

const tempsDir = path.join(__dirname, "..", "server", "src", "contracts");
const docsDir = path.join(__dirname, "..", "client", "src", "contracts");

async function deployTool(signer, targetName, libraries) {

  let options = {signer: signer};
  
  if (libraries != undefined) {
    options.libraries = libraries;
  }

  const Target = await hre.ethers.getContractFactory(targetName, options);
  const target = await Target.deploy();
  await target.deployed();

  console.log("Deployed ", targetName, "at address:", target.address);

  saveTempAddr(targetName, target);

  return target;
};

function saveTempAddr(targetName, target) {

  const fileNameOfContractAddrList = path.join(tempsDir, "contracts-address.json");

  const objContractAddrList = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));
  objContractAddrList[targetName] = target.address;

  fs.writeFileSync(
    fileNameOfContractAddrList,
    JSON.stringify(objContractAddrList, undefined, 2)
  );

};

function saveGKAddr(seqOfDoc, targetAddr) {

  const fileNameOfContractAddrList = path.join(docsDir, "gk-address.json");

  const objContractAddrList = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));
  objContractAddrList[seqOfDoc] = targetAddr;

  fs.writeFileSync(
    fileNameOfContractAddrList,
    JSON.stringify(objContractAddrList, undefined, 2)
  );
};

module.exports = {
  deployTool,
  saveGKAddr,
  saveTempAddr,
};
