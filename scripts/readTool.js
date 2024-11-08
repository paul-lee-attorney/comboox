// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

async function readContract(targetName, targetAddr) {

  const art = hre.artifacts.readArtifactSync(targetName);
  const target = await hre.ethers.getContractAt(art.abi, targetAddr);
  console.log("Abtained ", targetName, "at address:", target.address, "\n");

  return target;
};

module.exports = {
  readContract,
};
