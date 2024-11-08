// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { parseTimestamp } = require("./utils");
const { getGK, getLOO } = require("./boox");

async function main() {

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const loo = await getLOO();
    
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
