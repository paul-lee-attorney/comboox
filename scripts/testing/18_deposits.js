// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { getGK, getROM, getLOO, getROS, getFT, getRC, getGMM, } = require("./boox");
const { parseShare } = require("./ros");
const { now, increaseTime } = require("./utils");
const { getLatestSeqOfMotion, parseMotion, allSupportMotion } = require("./gmm");

async function main() {

    console.log('********************************');
    console.log('**         Deposits           **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const ft = await getFT();
    const gk = await getGK();
    const gmm = await getGMM() ;
    const ros = await getROS();
    const rom = await getROM();

    // ==== Events Liseners ====

    gk.on("SaveToCoffer", (acct, value, reason) => {
      console.log('ETH amount to', ethers.utils.formatUnits(value.toString(), 18), 'deposit to account of User', acct.toString(), 'for reason of', ethers.utils.parseBytes32String(reason), '\n');
    });

    gk.on("DistributeProfits", (amt, expireDate, seqOfMotion) => {
      console.log('ETH amount to', ethers.utils.formatUnits(amt.toString(), 18), 'distributed to Members. \n');
    });

    gk.on("PickupDeposit", (to, caller, amt)=>{
      console.log("ETH amount to", ethers.utils.formatUnits(amt.toString(), 18), 'is picked up by User', caller, 'to its Account', to, "\n");
    });

    // ==== ETH of Comp ====

    const getEthOfComp = async () => {
      let balaOfGK = await ethers.provider.getBalance(gk.address);
      let balaOfFT = await ethers.provider.getBalance(ft.address);
      let totalDeposits = await gk.totalDeposits();
      let ethOfComp = BigInt(balaOfGK) + BigInt(balaOfFT) - BigInt(totalDeposits);
      // console.log('ETH of Comp:', ethOfComp, '\n');
      console.log('ETH of Company:', ethers.utils.formatUnits(ethOfComp.toString(), 18), '\n');
      return ethOfComp;
    }

    await getEthOfComp();

    // ==== Pay In Capital ====
    const centPrice = await gk.getCentPrice();
    let value = 100n * 8000n * BigInt(centPrice) + 100n;

    console.log('paid of Share No. 4 before:', parseShare(await ros.getShare(4)).body.paid, '\n');
    await gk.connect(signers[4]).payInCapital(4, 8000 * 10 ** 4, {value: value});
    console.log('pay in capital by 8000 \n');
    console.log('paid of Share No. 4 after:', parseShare(await ros.getShare(4)).body.paid, '\n');

    // ==== Propose Distribution ====
    const today = await now();
    const expireDate = today + 86400 * 10;

    const ethOfComp = await getEthOfComp();
    const distAmt = ethOfComp / 20n;

    await gk.proposeToDistributeProfits(distAmt, expireDate, 10, 1);

    // ==== Vote for Distribution Motion ====

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));
    console.log('Distribution Motion:', motion, '\n');

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    console.log('latest motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');

    // ==== Distribute ====

    await gk.distributeProfits(distAmt, expireDate, seqOfMotion);

    await getEthOfComp()
    // ==== Pickup Deposits ====

    for (let i=0; i<7; i++) {

      if (i == 2) continue;

      const userNo = await rc.connect(signers[i]).getMyUserNo();
      const bala = await gk.connect(signers[i]).depositOfMine(userNo);

      console.log('User', userNo, 'ETH Balance before:', ethers.utils.formatUnits((await ethers.provider.getBalance(signers[i].address)).toString(), 18), '\n');

      await gk.connect(signers[i]).pickupDeposit();

      console.log('User', userNo, 'deposit balance', ethers.utils.formatUnits(bala.toString(), 18), 'is picked up. \n');

      console.log('User', userNo, 'ETH Balance after:', ethers.utils.formatUnits((await ethers.provider.getBalance(signers[i].address)).toString(), 18), '\n');

    }

    // ==== Release Events Liseners ====

    gk.off("SaveToCoffer");

    gk.off("DistributeProfits");

    gk.off("PickupDeposit");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
