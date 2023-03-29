// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { ethers } = require("ethers");
const path = require("path");
const fs = require("fs");

const contractsDir = path.join(__dirname, "..", "src", "contracts");

async function contractGetter(targetName, provider) {

  const artOfTarget = getArtifactsOfContract(targetName);
  const addOfTarget = getAddrOfContract(targetName);

  const target = new ethers.Contract(artOfTarget, artOfTarget.abi, provider);

  console.log("getContract: ", targetName, "from address: ", addOfTarget);

  return target;
};

function getArtifactsOfContract(targetName) {

  const fileNameOfTargetArtifacts = path.join(contractsDir, targetName + ".json");
 
  const artOfTarget = JSON.parse(fs.readFileSync(fileNameOfTargetArtifacts, "utf-8"));

  return artOfTarget;
};

function getAddrOfContract(targetName) {
  const fileNameOfContractAddrList = path.join(contractsDir, "contract-address.json");
  
  const objContractAddrList = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));

  return objContractAddrList[targetName];
}

module.exports = {
  contractGetter
};
