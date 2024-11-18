// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROA, getGMM, getROS, getROM, getRC, } = require("./boox");
const { readContract } = require("../readTool"); 
const { increaseTime, Bytes32Zero, now, } = require("./utils");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { getLatestShare } = require("./ros");
const { royaltyTest } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");

async function main() {

    console.log('\n********************************');
    console.log('**     Internal Transfer      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    
    // ==== Create Investment Agreement ====

    let tx = await gk.createIA(1);

    let Addr = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.createIA().");
    let ia = await readContract("InvestmentAgreement", Addr);

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const headOfDeal = {
      typeOfDeal: 3,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 7,
      seller: 6,
      priceOfPaid: 2.1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 3, 3, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    const deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 3,
      groupOfBuyer: 3, 
      paid: '10,000.0',
      par: '10,000.0',
      state: 0,
      para: 0,
      distrWeight: 100,
      flag: false,
    });
    expect(deal.hashLock).to.equal(Bytes32Zero);

    console.log("Passed Result Verify Test for ia.addDeal(). \n");

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);
    expect(await ia.getSigningDays()).to.equal(1);
    expect(await ia.getClosingDays()).to.equal(90);

    console.log("Passed Result Verify Test for ia.setTiming(). \n");

    await ia.addBlank(true, false, 1, 6);

    expect(await ia.isParty(6)).to.equal(true);
    expect(await ia.isSeller(true, 6)).to.equal(true);
    expect(await ia.isBuyer(true, 6)).to.equal(false);

    await ia.addBlank(true, true, 1, 3);
    expect(await ia.isParty(3)).to.equal(true);
    expect(await ia.isSeller(true, 3)).to.equal(false);
    expect(await ia.isBuyer(true, 3)).to.equal(true);

    console.log("Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    tx = await gk.connect(signers[6]).circulateIA(ia.address, Bytes32Zero, Bytes32Zero);
    
    await royaltyTest(rc.address, signers[6].address, gk.address, tx, 36n, "gk.circulateIA().");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 2);
    console.log("Passed Event Test for roa.UpdateStateOfFile(). \n");

    expect(await ia.circulated()).to.equal(true);

    let circulateDate = await ia.getCirculateDate();
    expect(await ia.getSigDeadline()).to.equal(circulateDate + 86400);
    expect(await ia.getClosingDeadline()).to.equal(circulateDate + 86400 * 90);

    console.log("Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----

    await expect(gk.connect(signers[1]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK.md.OPO: NOT Party");
    console.log("Parssed Access Control Test for gk.signIA(). \n ");

    tx = await gk.connect(signers[6]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[6].address, gk.address, tx, 36n, "gk.signIA().");
    expect(await ia.isSigner(6)).to.equal(true);
    console.log("Parssed Result Verify Test for gk.signIA(). by User_6 \n ");

    const doc = BigInt(ia.address);

    await expect(gk.connect(signers[6]).proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: not established");
    console.log("Parssed Procedure Control Test for gk.proposeDocOfGM(). \n ");

    tx = await gk.connect(signers[3]).signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 36n, "gk.signIA().");
    expect(await ia.isSigner(3)).to.equal(true);
    console.log("Parssed Result Verify Test for gk.signIA(). by User_3 \n ");

    expect(await ia.established()).to.equal(true);
    console.log("Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Voting For IA ====

    await increaseTime(86400 * 3);
    
    tx = await gk.connect(signers[6]).proposeDocOfGM(doc, 3, 6);

    await royaltyTest(rc.address, signers[6].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");
    
    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log("Passed Evet Test for gmm.CreateMotion(). \n");

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log("Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    expect(await gmm.isVoted(seqOfMotion, 1)).to.equal(true);
    console.log("Passed Result Verify Test for gk.castVoteOfGM(). with User_1 \n");

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    expect(await gmm.isVoted(seqOfMotion, 2)).to.equal(true);
    console.log("Passed Result Verify Test for gk.castVoteOfGM(). with User_2 \n");

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    expect(await gmm.isVoted(seqOfMotion, 4)).to.equal(true);
    console.log("Passed Result Verify Test for gk.castVoteOfGM(). with User_4 \n");

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log("Passed Result Verify Test for gk.voteCounting(). \n");

    const centPrice = await gk.getCentPrice();
    let value = 210n * 8000n * BigInt(centPrice) + 100n;

    await expect(gk.connect(signers[3]).payOffApprovedDeal(ia.address, 1, {value: value})).to.be.revertedWith("ROAK.payApprDeal: insufficient msgValue");
    console.log("Passed Amount Check Test for gk.payOffApprovedDeal(). \n");

    value = 210n * 10000n * BigInt(centPrice) + 100n;

    tx = await gk.connect(signers[3]).payOffApprovedDeal(ia.address, 1, {value: value});

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.payOffApprovedDeal().");

    await expect(tx).to.emit(ia, "PayOffApprovedDeal").withArgs(BigNumber.from(1), BigNumber.from(value));
    console.log("Passed Event Test for ia.PayOffApprovedDeal(). \n");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(ia.address, BigNumber.from(6));
    console.log("Passed Event Test for roa.execFile(). \n");

    await expect(tx).to.emit(gk, "SaveToCoffer");
    console.log("Passed Event Test for gk.SaveToCoffer(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(7), BigNumber.from(10000 * 10 ** 4));
    console.log("Passed Event Test for ros.increaseCleanPaid(). \n");

    await expect(tx).to.emit(rom, "RemoveShareFromMember").withArgs(BigNumber.from(7), BigNumber.from(6));
    console.log("Passed Event Test for rom.RemoveShareFromMember(). \n");

    await expect(tx).to.emit(ros, "DeregisterShare").withArgs(BigNumber.from(7));
    console.log("Passed Event Test for ros.DeregisterShare(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(8), BigNumber.from(3));
    console.log("Passed Event Test for rom.AddShareToMember(). \n");

    let share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(8);
    expect(share.head.shareholder).to.equal(3);
    expect(share.head.priceOfPaid).to.equal('2.1');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log('Passed Result Verify Test for gk.transferTargetShare(). \n'); 

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
