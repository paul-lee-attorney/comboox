// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to distribute profits of the DAO, and how to 
// check USDC balance and pickup the same from the deposit account in Cashier.

// The scenario for testing in this section are as follows:
// 1. User_1 proposes a Motion to the General Meeting of Members (the "GMM") to 
//    distribute 5% of the total USDC of the DAO to Members as per the distribution
//    powers thereof;
// 2. Upon approval of the GMM, User_1 as the executor of the Motion, executes
//    the Motion to distribute the predefined amount of USDC to Members;
// 3. User_1 to User_6 as Members and Sellers of listed shares, query the balance
//    USDC in their deposit account and pickup the same from the Cashier.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.2 function createActionOfGM(uint seqOfVR, address[] memory targets, uint256[] memory values, 
//     bytes[] memory params, bytes32 desHash, uint executor) external;
// 1.3 function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external;
// 1.4 function castVoteOfGM(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;
// 1.5 function voteCountingOfGM(uint256 seqOfMotion) external;
// 1.6 function execActionOfGM(uint seqOfVR, address[] memory targets, uint256[] memory values, 
//     bytes[] memory params, bytes32 desHash, uint256 seqOfMotion) external;

// 2. Cashier
// 2.1 function distributeUsd(uint amt) external;
// 2.2 function depositOfMine(uint user) external view returns(uint);
// 2.3 function pickupUsd() external; 

// Events verified in this section:
// 1. General Meeting Minutes
// 1.1 event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);

// 2. General Keeper
// 2.1  event ExecAction(uint256 indexed contents);

// 3. GMMKeeper
// 3.1  event ExecAction(uint256 indexed contents);

const { expect } = require("chai");
const { BigNumber, ethers } = require("ethers");

const { getGK, getROM, getRC, getGMM, getROS, getGMMKeeper, getCashier, getUSDC, } = require("./boox");
const { increaseTime, now } = require("./utils");
const { getLatestSeqOfMotion, parseMotion, allSupportMotion } = require("./gmm");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { printShares } = require("./ros");
const { depositOfUsers } = require("./gk");
const { transferCBP } = require("./saveTool");
const { artifacts } = require("hardhat");

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**      18 USD Deposits       **');
    console.log('********************************');
    console.log('\n');

	  const signers = await hre.ethers.getSigners();

    const cashier = await getCashier();
    const usdc = await getUSDC();
    const rc = await getRC();
    const gk = await getGK();
    const gmm = await getGMM();
    const rom = await getROM();
    const ros = await getROS();

    // ==== Propose Distribution ====

    const seqOfVR = 9n;
    const seqOfDR = 1280n;
    const usdOfComp = BigInt((await cashier.balanceOfComp()).toString());
    const distAmt = usdOfComp / 20n;
    // const desHash = ethers.utils.formatBytes32String("DistributeUSDC");
    const executor = await rc.getMyUserNo();

    // const Cashier = artifacts.readArtifactSync("Cashier");
    // const iface = new ethers.utils.Interface(Cashier.abi);
    // const data = iface.encodeFunctionData('distributeUsd', [distAmt]);

    // let tx = await gk.createActionOfGM(seqOfVR, [cashier.address], [0n], [data], desHash, executor);
    // await royaltyTest(rc.address, signers[0].address, gk.address, tx, 99n, "gk.createActionOfGM().");
    // transferCBP("1", "8", 99n);

    let today = await now();
    let expireDate = today + 86400 * 3;

    let tx = await gk.proposeToDistributeUsd(distAmt, expireDate, seqOfVR, seqOfDR, 0, executor);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 68n, "gk.proposeToDistributeUsd().");
    transferCBP("1", "8", 68n);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
    
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Distribute Profits");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(1);
    expect(motion.body.proposer).to.equal(1);

    console.log(" \u2714 Passed Result Verify Test for gk.proposeMotionToGeneralMeeting(). \n");

    // ==== Vote for Distribution Motion ====

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(' \u2714 Passed Result Verify Test for motion voting. \n');

    // ==== Distribute ====

    await expect(gk.connect(signers[1]).distributeProfits(distAmt, expireDate, seqOfDR, seqOfMotion)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.execAction(). \n");

    let balaBefore = await cashier.balanceOfComp();

    tx = await gk.distributeProfits(distAmt, expireDate, seqOfDR, seqOfMotion);
    // console.log("distribution tx:", tx);

    let balaAfter = await cashier.balanceOfComp();

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.distributeUsd().");
    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(cashier, "DistrProfits").withArgs(distAmt, seqOfDR, 1);
    console.log(" \u2714 Passed Event Test for cashier.DistrProfits(). \n");

    let diff = balaBefore - balaAfter;

    expect(diff).to.equal(distAmt);
    console.log(" \u2714 Passed Result Verify Test for gk.execActionOfGM(). \n");

    // ==== Pickup Deposits ====

    for (let i=0; i<5; i++) {

      if (i == 2) continue;

      const userNo = await rc.connect(signers[i]).getMyUserNo();
      const depo = await cashier.connect(signers[i]).depositOfMine(userNo);

      balaBefore = await usdc.balanceOf(signers[i].address);
      tx = await cashier.connect(signers[i]).pickupUsd();
      balaAfter = await usdc.balanceOf(signers[i].address);
      
      await royaltyTest(rc.address, signers[i].address, gk.address, tx, 18n, "cashier.pickupUsd().");

      transferCBP(userNo.toString(), "8", 18n);

      await expect(tx).to.emit(cashier, "PickupUsd").withArgs(signers[i].address, userNo, depo);
      console.log(" \u2714 Passed Event Test for cashier.PickupUsd(). \n");
      
      diff = balaAfter - balaBefore;

      expect(diff).to.equal(BigInt(depo.toString()));

      console.log(" \u2714 Passed Result Verify Test for cashier.pickupUsd(). for User", parseInt(userNo.toString()), " \n");

    }

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
