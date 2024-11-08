// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { pfrCodifier, pfrParser } = require('./rc');
const { getRC } = require("./boox");

async function main() {

	  const signers = await hre.ethers.getSigners();
    console.log('Acct_1:', signers[0].address, "Acct_2:", signers[1].address, "\n");

    const rc = await getRC();

    // ==== Set Platform Rule ====

    let pfr = pfrParser(await rc.getPlatformRule());
    console.log("Obtained PlatformRule:", pfr);

    pfr.eoaRewards = "0.018";
    await rc.setPlatformRule(pfrCodifier(pfr));
    pfr = pfrParser(await rc.getPlatformRule());
    console.log("Updated PlatformRule:", pfr, "\n");

    // ==== Reg Users ====

    await rc.mint(signers[0].address, 8n * 10n ** 18n);
    await rc.mint(signers[1].address, 8n * 10n ** 18n);

    for (let i = 3; i<7; i++) {
      await rc.connect(signers[i]).regUser();
      console.log('RegUser:', await rc.connect(signers[i]).getMyUserNo());
      console.log('Balance Of CBP:', ethers.utils.formatUnits((await rc.balanceOf(signers[i].address)), 18), "\n");
    }
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
  
