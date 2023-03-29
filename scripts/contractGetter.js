// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */


const hre = require("hardhat");
const path = require("path");

async function contractGetter(targetName) {

  const artOfTarget = getArtifactsOfContract(targetName);

  const target = await hre.ethers.getContractAt(artOfTarget.abi, artOfTarget.address);

  console.log("getContract: ", targetName, "from address: ", artOfTarget.address);

  return target;
};

function getArtifactsOfContract(targetName) {
  const fs = require("fs");
  const contractsDir = path.join(__dirname, "..", "client", "src", "contracts");

  const fileNameOfTargetArtifacts = path.join(contractsDir, targetName + ".json");
 
  let artOfTarget = JSON.parse(fs.readFileSync(fileNameOfTargetArtifacts,"utf-8"));

  return artOfTarget;
};

module.exports = {
  contractGetter
};
