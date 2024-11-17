// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROA, getGMM, getROS, getROM, getRC, } = require("./boox");
const { readContract } = require("../readTool"); 
const { parseTimestamp, increaseTime, Bytes32Zero, now } = require("./utils");
const { printShares, codifyHeadOfShare, parseShare, parseHeadOfShare } = require("./ros");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { printMembers } = require("./rom");
const { royaltyTest } = require("./rc");
const { getLatestSeqOfMotion, parseMotion } = require("./gmm");





async function main() {

    console.log('********************************');
    console.log('**   Capital Increase Deal    **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    const roaKeeper = await readContract("ROAKeeper", await gk.getKeeper(6));

    // ==== Create Investment Agreement ====

    await expect(gk.connect(signers[5]).createIA(1)).to.be.revertedWith("not MEMBER");
    console.log("Passed Access Control Test for gk.createIA(). \n");

    let tx = await gk.createIA(1);

    let Addr = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.createIA().");

    let ia = await readContract("InvestmentAgreement", Addr);

    expect(await ia.getDK()).to.equal(roaKeeper.address);
    console.log("Passed Result Verify Test for ia.initKeepers(). \n");
    
    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, BigNumber.from(1));
    console.log("Passed Event Test for roa.UpdateStateOfFile(). \n");

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    
    tx = await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    await expect(tx).to.emit(ia, "SetRoleAdmin").withArgs(ATTORNEYS, signers[0].address);
    console.log("Passed Event Test for ia.SetRoleAdmin(). \n");

    expect(await ia.getRoleAdmin(ATTORNEYS)).to.equal(signers[0].address);
    console.log("Passed Result Verify Test for ia.setRoleAdmin(). \n");

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1.8,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 5, 5, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    let deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 5,
      groupOfBuyer: 5, 
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

    await ia.addBlank(true, false, 1, 1);
    expect(await ia.isParty(1)).to.equal(true);
    expect(await ia.isSeller(true, 1)).to.equal(true);
    expect(await ia.isBuyer(true, 1)).to.equal(false);

    await ia.addBlank(true, true, 1, 5);
    expect(await ia.isParty(5)).to.equal(true);
    expect(await ia.isSeller(true, 5)).to.equal(false);
    expect(await ia.isBuyer(true, 5)).to.equal(true);

    console.log("Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    tx = await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.circulateIA().");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 2);
    console.log("Passed Event Test for roa.UpdateStateOfFile(). \n");

    expect(await ia.circulated()).to.equal(true);

    let circulateDate = await ia.getCirculateDate();
    expect(await ia.getSigDeadline()).to.equal(circulateDate + 86400);
    expect(await ia.getClosingDeadline()).to.equal(circulateDate + 86400 * 90);

    console.log("Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----

    await expect(gk.connect(signers[3]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK.md.OPO: NOT Party");
    console.log("Parssed Access Control Test for gk.signIA(). \n ");

    tx = await gk.signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.signIA().");
    expect(await ia.isSigner(1)).to.equal(true);
    console.log("Parssed Result Verify Test for gk.signIA(). by User_1 \n ");

    const doc = BigInt(ia.address);

    await expect(gk.proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: not established");
    console.log("Parssed Procedure Control Test for gk.proposeDocOfGM(). \n ");

    tx = await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 36n, "gk.signIA().");
    expect(await ia.isSigner(5)).to.equal(true);
    console.log("Parssed Result Verify Test for gk.signIA(). by User_5 \n ");

    expect(await ia.established()).to.equal(true);
    console.log("Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Voting For IA ====

    await increaseTime(86400 * 3);
    
    await expect(gk.connect(signers[5]).proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: NOT Member");
    console.log("Passed Access Control Test for gk.proposeDocOfGM().OnlyMember() \n");

    await expect(gk.connect(signers[3]).proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: not signer");
    console.log("Passed Access Control Test for gk.proposeDocOfGM().OnlySigner() \n");

    tx = await gk.proposeDocOfGM(doc, 1, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log("Passed Evet Test for gmm.CreateMotion(). \n");
    
    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log("Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400);

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    expect(await gmm.isVoted(seqOfMotion, 2)).to.equal(true);
    console.log("Passed Result Verify Test for gk.castVoteOfGM(). with User_2 \n");


    await gk.connect(signers[4]).entrustDelegaterForGeneralMeeting(seqOfMotion, 3);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    expect(await gmm.isVoted(seqOfMotion, 3)).to.equal(true);
    console.log("Passed Result Verify Test for gk.castVoteOfGM(). with User_3 \n");

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log("Passed Result Verify Test for gk.votingCounting(). \n");

    const closingDL = (await now()) + 86400;

    await expect(gk.connect(signers[1]).pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL)).to.be.revertedWith("ROAK.PTC: not director or controllor");
    console.log("Passed Access Control Test for gk.pushToCoffer(). \n");

    tx = await gk.pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.pushToCoffer().");

    await expect(tx).to.emit(ia, "ClearDealCP").withArgs(1, ethers.utils.id('Today is Friday.'), BigNumber.from(closingDL));
    console.log("Passed Evet Test for ia.ClearDealCP(). \n");
    
    deal = parseDeal(await ia.getDeal(1));
    expect(deal.body.state).to.equal(2); // Cleared
    console.log("Passed Result Verify Test for ia.ClearDealCP(). \n");
    
    // ---- Close Deal ----

    await expect(gk.closeDeal(ia.address, 1, 'Today is Thirthday.')).to.be.revertedWith("IA.closeDeal: hashKey NOT correct");
    console.log("Passed Access Control Test for ia.closeDeal(). \n");
    
    tx = await gk.closeDeal(ia.address, 1, 'Today is Friday.');

    await expect(tx).to.emit(ros, "IssueShare");
    console.log("Passed Evet Test for ros.IssueShare(). \n");

    let receipt = await tx.wait();
    console.log("receipt:", receipt);

    let headOfShare = parseHeadOfShare(receipt.logs[4].topics[1]);
    console.log("headOfShare", headOfShare);

    let share = parseShare(await ros.getShare(headOfShare.seqOfShare));

    expect(share.head.shareholder).to.equal(5);
    expect(share.head.priceOfPaid).to.equal('1.8');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log('Passed Result Verify Test for gk.closeDeal(). \n');

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
