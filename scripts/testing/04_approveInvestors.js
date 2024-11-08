// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const path = require("path");
const fs = require("fs");
const tempsDir = path.join(__dirname, "..", "..", "server", "src", "contracts");

const { readContract } = require("../readTool"); 
const { Bytes32Zero, parseTimestamp } = require("./utils");

async function main() {

    const fileNameOfTemps = path.join(tempsDir, "contracts-address.json");
    const Temps = JSON.parse(fs.readFileSync(fileNameOfTemps,"utf-8"));

    const fileNameOfBoox = path.join(__dirname, "boox.json");
    const Boox = JSON.parse(fs.readFileSync(fileNameOfBoox));

	  const signers = await hre.ethers.getSigners();

    const gk = await readContract("GeneralKeeper", Boox.GK);
    const loo = await readContract("ListOfOrders", Boox.LOO);
    
    // ==== Reg Investors ====

    for (let i=0; i<7; i++) {
      if (i < 2) {
        await gk.connect(signers[i]).regInvestor(i+1, ethers.utils.id(signers[i].address));
        await gk.approveInvestor(i+1, 1024);
      } else if (i == 2) {
        await gk.connect(signers[2]).regInvestor(7, ethers.utils.id(signers[i].address));
        await gk.approveInvestor(7, 1024);
      } else {
        await gk.connect(signers[i]).regInvestor(i, ethers.utils.id(signers[i].address));
        await gk.approveInvestor(i, 1024);
      }
    }

    const list = (await loo.investorList()).map(v=>v.toString());
    console.log('Investors List:', list, '\n');

    const infoList = (await loo.investorInfoList()).map(v => ({
      userNo: v[0].toString(),
      groupRep: v[1].toString(),
      regDate: parseTimestamp(v[2]),
      verifier: v[3].toString(),
      approveDate: parseTimestamp(v[4]),
      approved: (v[6] > 0),
      idHash: v[7],
    }));

    console.log('Investors List:', infoList);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
