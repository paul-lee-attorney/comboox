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
// 2.2 event DistributeProfits(uint indexed amt, uint indexed expireDate, 
//     uint indexed seqOfMotion);

// 3. GMM Keeper
// 3.1 event DistributeProfits(uint256 indexed sum, uint indexed seqOfMotion, 
//     uint indexed caller);


const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROM, getFT, getRC, getGMM, getROS, getGMMKeeper, } = require("./boox");
const { now, increaseTime } = require("./utils");
const { getLatestSeqOfMotion, parseMotion, allSupportMotion } = require("./gmm");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { printShares } = require("./ros");
const { depositOfUsers } = require("./gk");
const { transferCBP, minusEthFromUser, addEthToUser } = require("./saveTool");

async function main() {

    console.log('\n********************************');
    console.log('**      18. Deposits          **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const ft = await getFT();
    const gk = await getGK();
    const gmm = await getGMM();
    const rom = await getROM();
    const ros = await getROS();
    const gmmKeeper = await getGMMKeeper();

    // ==== ETH of Comp ====

    const getEthOfComp = async () => {
      let balaOfGK = await ethers.provider.getBalance(gk.address);
      let balaOfFT = await ethers.provider.getBalance(ft.address);
      let totalDeposits = await gk.totalDeposits();
      let ethOfComp = BigInt(balaOfGK) + BigInt(balaOfFT) - BigInt(totalDeposits);

      return ethOfComp;
    }

    // ==== Distribute Profits ====

    const distributeProfits = async (amt) => {

      const totalPts = BigInt((await rom.ownersPoints())[4]);
      let sum = 0n;

      const members = (await rom.membersList()).map(v => Number(v));

      let len = members.length;

      while (len > 1) {
        const member = members[len - 1];
        const ptsOfMember = BigInt((await rom.pointsOfMember(member))[4]);

        const val = ptsOfMember * amt / totalPts;

        addEthToUser(val, member.toString());
        sum += val;

        len--;
      }

      addEthToUser(amt - sum, members[0].toString());
    }

    // ==== Propose Distribution ====

    const today = await now();
    const expireDate = today + 86400 * 10;

    const ethOfComp = await getEthOfComp();
    const distAmt = ethOfComp / 20n;

    let tx = await gk.proposeToDistributeProfits(distAmt, expireDate, 10, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 68n, "gk.proposeToDistributeProfits().");

    transferCBP("1", "8", 68n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
    
    let seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "ProposeMotionToGeneralMeeting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Distribute Profits");
    expect(motion.head.seqOfVR).to.equal(10);
    expect(motion.head.creator).to.equal(1);
    expect(motion.body.proposer).to.equal(1);

    console.log(" \u2714 Passed Result Verify Test for gk.proposeToDistributeProfits(). \n");

    // ==== Vote for Distribution Motion ====

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(' \u2714 Passed Result Verify Test for motion voting. \n');

    // ==== Distribute ====

    await expect(gk.connect(signers[1]).distributeProfits(distAmt, expireDate, seqOfMotion)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.distributeProfits(). \n");
    
    let balaBefore = await getEthOfComp();    
    tx = await gk.distributeProfits(distAmt, expireDate, seqOfMotion);

    minusEthFromUser(distAmt, "8");
    await distributeProfits(distAmt);

    let balaAfter = await getEthOfComp();

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.distributeProfits().");

    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(gk, "DistributeProfits").withArgs(BigNumber.from(distAmt.toString()), BigNumber.from(expireDate), BigNumber.from(seqOfMotion));
    console.log(" \u2714 Passed Event Test for gk.DistributeProfits(). \n");

    await expect(tx).to.emit(gmmKeeper, "DistributeProfits").withArgs(BigNumber.from(distAmt.toString()), BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmmKeeper.DistributeProfits(). \n");

    let diff = balaBefore - balaAfter;

    expect(diff).to.equal(distAmt);
    console.log(" \u2714 Passed Result Verify Test for gk.distributeProfits(). \n");

    // ==== Pickup Deposits ====

    for (let i=0; i<7; i++) {

      if (i == 2) continue;

      const userNo = await rc.connect(signers[i]).getMyUserNo();
      const depo = await gk.connect(signers[i]).depositOfMine(userNo);

      balaBefore = BigInt((await ethers.provider.getBalance(signers[i].address)).toString());
      tx = await gk.connect(signers[i]).pickupDeposit();

      minusEthFromUser(BigInt(depo.toString()), userNo.toString());

      balaAfter = BigInt((await ethers.provider.getBalance(signers[i].address)).toString());
      
      await royaltyTest(rc.address, signers[i].address, gk.address, tx, 18n, "gk.pickupDeposit().");

      transferCBP(userNo.toString(), "8", 18n);

      await expect(tx).to.emit(gk, "PickupDeposit").withArgs(signers[i].address, userNo, depo);
      console.log(" \u2714 Passed Event Test for gk.PickupDeposit(). \n");

      const reciept = await tx.wait();

      let gas = BigInt(reciept.gasUsed.mul(tx.gasPrice).toString());
      
      diff = balaAfter + gas - balaBefore;

      expect(diff).to.equal(BigInt(depo.toString()));

      console.log(" \u2714 Passed Result Verify Test for gk.pickupDeposit(). for User", parseInt(userNo.toString()), " \n");

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
