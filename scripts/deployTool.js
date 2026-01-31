// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import {network} from"hardhat";
import path from "path";
import fs from "fs";

const __dirname = import.meta.dirname;

const tempsDir = path.join(__dirname, "..", "server", "src", "contracts");
const docsDir = path.join(__dirname, "..", "client", "src", "contracts");

export async function deployTool(signer, targetName, libraries, params) {

  let options = {signer: signer};
  
  if (libraries != undefined) {
    options.libraries = libraries;
  }

  const {ethers} = await network.connect();

  const Target = await ethers.getContractFactory(targetName, options);
  const target = await Target.deploy(...params);
  await target.waitForDeployment();
  const address = await target.getAddress();
  
  console.log("Deployed ", targetName, "at address:", address, "\n");

  saveTempAddr(targetName, address);

  return address;
};

export function saveTempAddr(targetName, targetAddress) {

  const fileNameOfContractAddrList = path.join(tempsDir, "contracts-address.json");

  const objContractAddrList = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));
  objContractAddrList[targetName] = targetAddress;

  fs.writeFileSync(
    fileNameOfContractAddrList,
    JSON.stringify(objContractAddrList, undefined, 2)
  );

};

export function saveGKAddr(seqOfDoc, targetAddr) {

  const fileNameOfContractAddrList = path.join(docsDir, "gk-address.json");

  const objContractAddrList = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));
  objContractAddrList[seqOfDoc] = targetAddr;

  fs.writeFileSync(
    fileNameOfContractAddrList,
    JSON.stringify(objContractAddrList, undefined, 2)
  );
};
