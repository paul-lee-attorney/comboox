// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROA, getGMM, getROS, getROM, getRC, } = require("./boox");
const { readContract } = require("../readTool"); 
const { increaseTime, Bytes32Zero, now, longDataParser, } = require("./utils");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { getLatestShare, parseShare } = require("./ros");
const { royaltyTest } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");
const { ethers } = require("hardhat");


async function main() {

    console.log('\n********************************');
    console.log('**       First Refusal        **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    
    // ==== Create Investment Agreement ====

    let tx = await gk.connect(signers[5]).createIA(1);

    let Addr = await royaltyTest(rc.address, signers[5].address, gk.address, tx, 58n, "gk.createIA().");
    let ia = await readContract("InvestmentAgreement", Addr);

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    await ia.connect(signers[5]).setRoleAdmin(ATTORNEYS, signers[0].address);

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const createDeal = async (headOfDeal, amt) => {
      await ia.addDeal(codifyHeadOfDeal(headOfDeal), 6, 6, amt * 10 ** 4, amt * 10 ** 4, 100);
    }

    let headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 9,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    };

    await createDeal(headOfDeal, 10000);    

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 2,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 12,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    };
    
    await createDeal(headOfDeal, 20000);

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 3,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 13,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    };
    
    await createDeal(headOfDeal, 9000);

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 4,
      preSeq: 0,
      classOfShare: 1,
      seqOfShare: 14,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    };
    
    await createDeal(headOfDeal, 95000);

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);
    await ia.addBlank(true, false, 1, 5);
    await ia.addBlank(true, true, 1, 6);

    // ---- Circulate IA ----

    await ia.connect(signers[5]).finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    await gk.connect(signers[5]).circulateIA(ia.address, Bytes32Zero, Bytes32Zero);
    expect(await ia.circulated()).to.equal(true);

    // ---- Sign IA ----

    await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);
    await gk.connect(signers[6]).signIA(ia.address, Bytes32Zero);

    expect(await ia.established()).to.equal(true);
    console.log("Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Exec First Refusal ====

    await increaseTime(86400 * 1);

    for (let i=1; i<=4; i++){
      tx = await gk.execFirstRefusal(513, 1, ia.address, i, ethers.utils.id(signers[0].address));

      await royaltyTest(rc.address, signers[0].address, gk.address, tx, 88n, "gk.execFirstRefusal().");

      await expect(tx).to.emit(roa, "ClaimFirstRefusal").withArgs(ia.address, i, 1);
      await expect(tx).to.emit(ia, "TerminateDeal").withArgs(BigNumber.from(i));

      tx = await gk.connect(signers[1]).execFirstRefusal(513, 2, ia.address, i, ethers.utils.id(signers[1].address));

      const cls = (await roa.getFRClaimsOfDeal(ia.address, i)).map(v => ({seqOfDeal: v[0], claimer: v[1]}));
      expect(cls[0]).to.deep.equal({seqOfDeal:i, claimer:1});
      expect(cls[1]).to.deep.equal({seqOfDeal:i, claimer:2});

      console.log("Passed Result Verify Test for gk.execFirstRefusal(). \n");
    }

    // ==== Compute FR Deals ====

    await increaseTime(86400 * 1);

    for (let i=1; i<=4; i++) {
      await expect(gk.connect(signers[6]).computeFirstRefusal(ia.address, i)).to.be.revertedWith("SHAKeeper.computeFR: not member");
      console.log("Passed Access Control Test for gk.computeFirstRefusal(). \n");

      tx = await gk.computeFirstRefusal(ia.address, i);

      await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.computeFirstRefusal().");

      await expect(tx).to.emit(ia, "RegDeal")
      console.log("Passed Event Test for ia.RegDeal(). \n");

      let deal = parseDeal(await ia.getDeal(3+2*i));
      expect(deal.body.buyer).to.equal(2);
      
      deal = parseDeal(await ia.getDeal(4+2*i));
      expect(deal.body.buyer).to.equal(1);

      console.log("Passed Result Verify Test for gk.computeFirstRefusal(). \n");
    }

    // const dealsList = (await ia.getSeqList()).map(v => Number(v));

    // let len = dealsList.length;
    // while (len > 0) {
    //   const dl = parseDeal(await ia.getDeal(dealsList[len-1]));
    //   console.log("deal:", dl, "\n");
    //   len --;
    // }

    expect(await ia.established()).to.equal(true);
    console.log("Passed Establishment Test for FirstRefusal. \n");
    
    // ==== Vote for IA ====

    await increaseTime(86400 * 1);

    const doc = BigInt(ia.address);

    await gk.connect(signers[5]).proposeDocOfGM(doc, 1, 1);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log("Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400);

    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    console.log("Passed Result Verify Test for gk.castVoteOfGM() & gk.voteAccountingOfGM(). \n");

    // ---- Exec IA ----

    const payOffDeal = async (seqOfDeal) => {

      const centPrice = await gk.getCentPrice();
      const deal = await ia.getDeal(seqOfDeal);
      const paid = deal[1][2];
      const value = 300n * BigInt(paid) / 10000n * BigInt(centPrice) + 500n;

      const buyer = Number(deal[1][0]);
  
      await gk.connect(signers[buyer - 1]).payOffApprovedDeal(ia.address, seqOfDeal, {value: value});

      const share = await getLatestShare(ros);
      
      expect(share.head.shareholder).to.equal(buyer);
      expect(share.body.paid).to.equal(longDataParser(ethers.utils.formatUnits(paid.toString(), 4)));

      console.log("Passed Result Verify Test for First Refusal of Share", share.head.seqOfShare, "\n");
    }

    for (let i=12; i>=9; i--)
        await payOffDeal(i);

    for (let i=8; i>=5; i--)
        await payOffDeal(i);
    
    console.log("Passed All Tests for First Refusal. \n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
