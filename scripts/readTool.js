// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { artifacts, network } from "hardhat";

export async function readTool(targetName, targetAddr) {

  const { ethers } = await network.connect();

  const art = await artifacts.readArtifact(targetName);
  const target = await ethers.getContractAt(art.abi, targetAddr);
  console.log("Abtained ", targetName, "at address:", target.target, "\n");

  return target;
};

export async function getContractWithSigner(targetName, targetAddr, signer) {

  const { ethers } = await network.connect();

  const art = await artifacts.readArtifact(targetName);
  const target = new ethers.Contract(targetAddr, art.abi, signer);
  console.log("Abtained ", targetName, "at address:", target.target, "\n");

  return target;
};


