// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const path = require("path");
const fs = require("fs");

const contractsDir = path.join(__dirname, "..", "client", "src", "contracts");

async function deployTool(signer, targetName, libraries) {

  let options = {signer: signer};
  
  if (libraries != undefined) {
    options.libraries = libraries;
  }

  const Target = await hre.ethers.getContractFactory(targetName, options);
  const target = await Target.deploy();
  await target.deployed();

  console.log("Deployed ", targetName, "at address:", target.address);

  saveFrontendFiles(targetName, target);

  return target;
};

function saveFrontendFiles(targetName, target) {

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  const fileNameOfContractAddrList = path.join(contractsDir, "contract-address.json");

  const objContractAddrList = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));
  objContractAddrList[targetName] = target.address;

  fs.writeFileSync(
    fileNameOfContractAddrList,
    JSON.stringify(objContractAddrList, undefined, 2)
  );

  copyArtifactsOf(targetName);
};

async function copyArtifactsOf(targetName) {

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  const TargetArtifact = hre.artifacts.readArtifactSync(targetName);
  const fileNameOfTargetArtifact = targetName + ".json";

  fs.writeFileSync(
    path.join(contractsDir, fileNameOfTargetArtifact),
    JSON.stringify(TargetArtifact, null, 2)
  );

  console.log("Copied ", targetName, "'s artifacts to file: ", fileNameOfTargetArtifact, "\n");
};

module.exports = {
  deployTool,
  copyArtifactsOf
};
