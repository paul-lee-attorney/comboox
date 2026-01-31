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
  console.log("Abtained ", targetName, "at address:", await target.getAddress(), "\n");

  return target;
};
