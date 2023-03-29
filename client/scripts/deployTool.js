// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */


const { ethers } = require("ethers");
const path = require("path");

async function deployTool(signer, targetName, libraries) {

  let options = {signer: signer};
  
  if (libraries != undefined) {
    options.libraries = libraries;
  }

  const Target = await ethers.getContractFactory(targetName, options);
  const target = await Target.deploy();
  await target.deployed();

  console.log("Deployed ", targetName, "at address:", target.address);

  saveFrontendFiles(targetName, target);

  return target;
};

function saveFrontendFiles(targetName, target) {
  const fs = require("fs");
  const contractsDir = path.join(__dirname, "..", "client", "src", "contracts");

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  const fileNameOfContractAddrList = path.join(contractsDir, "contract-address.json");

  let objContractAddrList = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));
  objContractAddrList[targetName] = target.address;

  fs.writeFileSync(
    fileNameOfContractAddrList,
    JSON.stringify(objContractAddrList, undefined, 2)
  );

  let TargetArtifact = hre.artifacts.readArtifactSync(targetName);
  TargetArtifact.address = target.address;

  let fileNameOfTargetArtifact = targetName + ".json";

  fs.writeFileSync(
    path.join(contractsDir, fileNameOfTargetArtifact),
    JSON.stringify(TargetArtifact, null, 2)
  );
};

module.exports = {
  deployTool
};
