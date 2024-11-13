// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { parseTimestamp } = require("./utils");
const { getGK, getLOO, getRC } = require("./boox");
const { parseInvestor } = require("./loo");

async function main() {

    console.log('********************************');
    console.log('**     Approve Investors      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const loo = await getLOO();

    // ==== Reg New Users ==== 

    const regNewUser = async (signerNo) => {
      await rc.connect(signers[signerNo]).regUser();
      console.log('RegUser:', await rc.connect(signers[signerNo]).getMyUserNo());
      console.log('Balance Of CBP:', ethers.utils.formatUnits((await rc.balanceOf(signers[signerNo].address)), 18), "\n");  
    }

    for (let i=7; i<10; i++) {
      await regNewUser(i);
    }
    
    // ==== Reg & Approve Investors ====

    const regAndApproveInvestor = async (signerNo) => {
      const userNo = await rc.connect(signers[signerNo]).getMyUserNo();
      await gk.connect(signers[signerNo]).regInvestor(userNo, ethers.utils.id(signers[signerNo].address));
      await gk.approveInvestor(userNo, 1024);
    }

    for (let i=0; i<10; i++) {
      await regAndApproveInvestor(i);
    }

    // ==== Revoke Investor ====
    
    for (let i=7; i<10; i++) {
      const userNo = await rc.connect(signers[i]).getMyUserNo();
      await gk.revokeInvestor(userNo, 1024);
    }

    const list = (await loo.investorList()).map(v=>v.toString());
    console.log('Investors List:', list, '\n');

    const infoList = (await loo.investorInfoList()).map(v => parseInvestor(v));

    console.log('Investors List:', infoList);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
