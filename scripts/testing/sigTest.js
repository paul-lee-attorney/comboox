// SPDX-License-Identifier: UNLICENSED

import { getDomainSeparator, generateAuth } from "./sigTools";
import { getUSDC, getCashier, getUsdKeeper } from "./boox";
import { increaseTime } from "./utils";

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */


async function main() {

    console.log('\n******************');
    console.log('**     SigTest    **');
    console.log('********************\n');

    const usdc = await getUSDC();
    const cashier = await getCashier();
    const usdKeeper = await getUsdKeeper();

    let res = await getDomainSeparator();

    console.log("DomainSeparator: ", res);    

	  const signers = await hre.ethers.getSigners();

    // let auth = await generateAuth(signers[4], cashier.address, 50);
    // console.log("auth:", auth);

    // await increaseTime(600);

    // let blk = await  ethers.provider.getBlock();
    // console.log("timestamp: ", blk.timestamp);
  
    // let tx = await usdc.transferWithAuthorization(auth.from, auth.to, auth.value, auth.validAfter, auth.validBefore, auth.nonce, auth.v, auth.r, auth.s);
    // console.log("tx:", tx);

    // let rpt = await tx.wait();
    // console.log("rpt:", rpt);

    let auth = await generateAuth(signers[4], cashier.address, 750);
    console.log("auth:", auth);

    await increaseTime(600);

    let tx = await usdKeeper.connect(signers[4]).payInCapital(auth, 4, 500 * 10 ** 4);
    console.log("tx:", tx);

    let rpt = await tx.wait();
    console.log("rpt:", rpt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
