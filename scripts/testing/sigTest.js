// SPDX-License-Identifier: UNLICENSED

const { getDomainSeparator } = require("./sigTools");

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */


async function main() {

    console.log('\n******************');
    console.log('**     SigTest    **');
    console.log('********************\n');

    let res = await getDomainSeparator();

    console.log("DomainSeparator: ", res);    

	  // const signers = await hre.ethers.getSigners();

    // const rc = await getRC();
    // const gk = await getGK();
    // const usdKeeper = await getUsdKeeper();
    // const usdc = await getUSDC();
    // const cashier = await getCashier();
    // const usdLOO = await getUsdLOO();
    // const ros = await getROS();
    // const usdLooKeeper = await getUsdLOOKeeper();

    // // ==== Mint Mock USDC to users ====

    // for (i=0; i<7; i++) {
    //   await usdc.mint(signers[i].address, 10n ** 12n);
    //   let balance = await usdc.balanceOf(signers[i].address);
    //   balance = ethers.utils.formatUnits(balance, 6);
    //   expect(balance).to.equal('1000000.0');
    // }

    // let res = await generateSignature(signers[0], signers[1].address, )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
