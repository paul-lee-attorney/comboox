// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to distribute profits of the DAO, and how to 
// check ETH balance and pickup the same from the deposit account in General
// Keeper. 

// The scenario for testing in this section are as follows:
// 1. User_1 proposes a Motion to the General Meeting of Members (the "GMM") to 
//    distribute 5% of the total ETH of the DAO to Members as per the distribution
//    powers thereof;
// 2. Upon approval of the GMM, User_1 as the executor of the Motion, executes
//    the Motion to distribute the predefined amount of ETH to Members;
// 3. User_1 to User_6 as Members and Sellers of listed shares, query the balance
//    ETH in their deposit account and pickup the same from the General Keeper.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.2 function proposeToDistributeProfits(uint amt, uint expireDate, uint seqOfVR,
//     uint executor) external;
// 1.3 function distributeProfits(uint amt, uint expireDate, uint seqOfMotion) external; 
// 1.4 function pickupDeposit() external;

// Events verified in this section:
// 1. General Meeting Minutes
// 1.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);
// 1.2 event ProposeMotionToGeneralMeeting(uint256 indexed seqOfMotion,
//     uint256 indexed proposer);
// 1.3 event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);

// 2. General Keeper
// 2.1 event PickupDeposit(address indexed to, uint indexed caller, uint indexed amt);
// 2.2 event DistributeProfits(uint indexed amt, uint indexed expireDate, uint indexed seqOfMotion);

// 3. GMM Keeper
// 3.1 event DistributeProfits(uint256 indexed sum, uint indexed seqOfMotion, uint indexed caller);


const { expect } = require("chai");
const { BigNumber, ethers } = require("ethers");

const { getGK, getROM, getFT, getRC, getGMM, getROS, getGMMKeeper, getCashier, getUSDC, } = require("./boox");
const { increaseTime } = require("./utils");
const { getLatestSeqOfMotion, parseMotion, allSupportMotion } = require("./gmm");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { printShares } = require("./ros");
const { depositOfUsers } = require("./gk");
const { transferCBP, minusEthFromUser, addEthToUser } = require("./saveTool");
const { artifacts } = require("hardhat");

async function main() {

    console.log('\n********************************');
    console.log('**    18.1 USD Deposits       **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const cashier = await getCashier();
    const usdc = await getUSDC();
    const rc = await getRC();
    const gk = await getGK();
    const gmm = await getGMM();
    const rom = await getROM();
    const ros = await getROS();
    const gmmKeeper = await getGMMKeeper();

    // ==== Propose Distribution ====

    const seqOfVR = 9n;
    const usdOfComp = BigInt((await cashier.balanceOfComp()).toString());
    const distAmt = usdOfComp / 20n;
    const desHash = ethers.utils.formatBytes32String("DistributeUSDC");
    const executor = await rc.getMyUserNo();

    const Cashier = artifacts.readArtifactSync("Cashier");
    const iface = new ethers.utils.Interface(Cashier.abi);
    const data = iface.encodeFunctionData('distributeUsd', [distAmt]);

    let tx = await gk.createActionOfGM(seqOfVR, [cashier.address], [0n], [data], desHash, executor);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 99n, "gk.createActionOfGM().");
    transferCBP("1", "8", 99n);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    tx = await gk.proposeMotionToGeneralMeeting(seqOfMotion);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 72n, "gk.proposeMotionToGeneralMeeting().");
    transferCBP("1", "8", 72n);
    
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Approve Action");
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

    await expect(gk.connect(signers[1]).execActionOfGM(seqOfVR, [cashier.address], [0n], [data], desHash, seqOfMotion)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.execAction(). \n");
    
    let balaBefore = await cashier.balanceOfComp();
    tx = await gk.execActionOfGM(seqOfVR, [cashier.address], [0n], [data], desHash, seqOfMotion);

    let balaAfter = await cashier.balanceOfComp();

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.execAction().");

    transferCBP("1", "8", 36n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(gk, "ExecAction");
    console.log(" \u2714 Passed Event Test for gk.ExecAtion(). \n");

    await expect(tx).to.emit(gmmKeeper, "ExecAction");
    console.log(" \u2714 Passed Event Test for gmmKeeper.ExecAtion(). \n");

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
    await depositOfUsers(rc, gk);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
