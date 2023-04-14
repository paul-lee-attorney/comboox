// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */


const hre = require("hardhat");
const path = require("path");
const fs = require("fs");

async function contractGetter(targetName, addrOfTarget) {

  const artOfTarget = hre.artifacts.readArtifactSync(targetName);

  const target = await hre.ethers.getContractAt(artOfTarget.abi, addrOfTarget);

  console.log("getContract: ", targetName);

  return target;
};

function tempAddrGetter(tempName) {
  const contractsDir = path.join(__dirname, "..", "server", "src", "contracts");

  const fileNameOfContractAddrList = path.join(contractsDir, "contracts-address.json");

  const objContractAddrList = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));

  const addr = objContractAddrList[tempName];

  console.log("obtained template at addr: ", addr);

  return addr;
}

module.exports = {
  contractGetter,
  tempAddrGetter
};
