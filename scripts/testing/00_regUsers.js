// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { pfrCodifier, pfrParser } = require('./rc');
const { getRC } = require("./boox");

async function main() {

    console.log('********************************');
    console.log('**         Reg Users          **');
    console.log('********************************\n');

    // obtained signers from hardhat test network
	  const signers = await hre.ethers.getSigners();
    // obtained instance of RegCenter
    const rc = await getRC();

    // ==== Set Platform Rule ====

    let pfr = pfrParser(await rc.getPlatformRule());
    console.log("Obtained PlatformRule:", pfr);

    // set new user awards for EOA account so that new users may create and confit their company boox 
    // for free.
    pfr.eoaRewards = "0.018";
    await rc.setPlatformRule(pfrCodifier(pfr));
    pfr = pfrParser(await rc.getPlatformRule());
    console.log("Updated PlatformRule:", pfr, "\n");

    // ==== Reg Users ====

    // User_1 and User_2 are two special Users registered during the deploying 
    // process of ComBoox, thus, they cannot get new user awards. This "mint"
    // process is to provide enough start up CBP for them to go through this 
    // test process.
    await rc.mint(signers[0].address, 8n * 10n ** 18n);
    await rc.mint(signers[1].address, 8n * 10n ** 18n);

    // From User_3 to User_6 have same registration number with their Hardhat 
    // account number.
    for (let i = 3; i<7; i++) {
      await rc.connect(signers[i]).regUser();
      console.log('RegUser:', await rc.connect(signers[i]).getMyUserNo());
      console.log('Balance Of CBP:', ethers.utils.formatUnits((await rc.balanceOf(signers[i].address)), 18), "\n");
    }

    // Account No 2 of Hardhat is assigned User_7 in ComBoox.
    await rc.connect(signers[2]).regUser();
    console.log('RegUser:', await rc.connect(signers[2]).getMyUserNo());
    console.log('Balance Of CBP:', ethers.utils.formatUnits((await rc.balanceOf(signers[2].address)), 18), "\n");
    
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
