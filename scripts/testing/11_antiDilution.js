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
const { obtainNewShare, getLatestShare } = require("./ros");
const { royaltyTest } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");


async function main() {

    console.log('\n********************************');
    console.log('**     11. Anti-Dilution      **');
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
      typeOfDeal: 1,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1.2,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 5, 5, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    const deal = parseDeal(await ia.getDeal(1));

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

    console.log(" \u2714 Passed Result Verify Test for ia.addDeal(). \n");

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);

    expect(await ia.getSigningDays()).to.equal(1);
    expect(await ia.getClosingDays()).to.equal(90);

    console.log(" \u2714 Passed Result Verify Test for ia.setTiming(). \n");

    await ia.addBlank(true, false, 1, 1);

    expect(await ia.isParty(1)).to.equal(true);
    expect(await ia.isSeller(true, 1)).to.equal(true);
    expect(await ia.isBuyer(true, 1)).to.equal(false);

    await ia.addBlank(true, true, 1, 5);

    expect(await ia.isParty(5)).to.equal(true);
    expect(await ia.isSeller(true, 5)).to.equal(false);
    expect(await ia.isBuyer(true, 5)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Circulate IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    await expect(gk.connect(signers[3]).execAntiDilution(ia.address, 1, 3, Bytes32Zero)).to.be.revertedWith("SHAK.execAD: wrong file state");
    console.log(" \u2714 Passed IA State Control Test for gk.execAntiDilution(). \n ");

    tx = await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.circulateIA().");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 2);
    console.log(" \u2714 Passed Event Test for roa.UpdateStateOfFile(). \n");

    expect(await ia.circulated()).to.equal(true);

    let circulateDate = await ia.getCirculateDate();
    expect(await ia.getSigDeadline()).to.equal(circulateDate + 86400);
    expect(await ia.getClosingDeadline()).to.equal(circulateDate + 86400 * 90);

    console.log(" \u2714 Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Exec AntiDilution ----

    await expect(gk.connect(signers[1]).execAntiDilution(ia.address, 1, 3, Bytes32Zero)).to.be.revertedWith("SHAK.execAD: not shareholder");
    console.log(" \u2714 Passed Access Control Test for gk.execAntiDilution(). ShareholderOnly \n ");

    // ---- User_3 ----

    tx = await gk.connect(signers[3]).execAntiDilution(ia.address, 1, 3, Bytes32Zero);
    
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 88n, "gk.execAntiDilution().");    
    
    await expect(tx).to.emit(ia, "RegDeal").withArgs(2);
    console.log(" \u2714 Passed Event Test for ia.RegDeal(). \n ");    

    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(BigNumber.from(2), BigNumber.from(10000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n ");    
    
    // ---- User_4 ----

    tx = await gk.connect(signers[4]).execAntiDilution(ia.address, 1, 4, Bytes32Zero);

    await royaltyTest(rc.address, signers[4].address, gk.address, tx, 88n, "gk.execAntiDilution().");
    
    await expect(tx).to.emit(ia, "RegDeal").withArgs(3);
    console.log(" \u2714 Passed Event Test for ia.RegDeal(). \n ");    

    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(BigNumber.from(2), BigNumber.from(5000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n ");

    // ---- Sign IA ----

    await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);
    await gk.signIA(ia.address, Bytes32Zero);

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Voting For IA ====

    await increaseTime(86400 * 3);
    
    const doc = BigInt(ia.address);

    await gk.proposeDocOfGM(doc, 1, 1);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400*2);

    await gk.voteCountingOfGM(seqOfMotion);
    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.voteCounting(). \n");

    // ---- Exec IA ----

    tx = await gk.issueNewShare(ia.address, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.issueNewShare().");

    await expect(tx).to.emit(ros, "IssueShare");
    console.log(" \u2714 Passed Evet Test for ros.IssueShare(). \n");

    let share = await obtainNewShare(tx);

    expect(share.head.seqOfShare).to.equal(9);
    expect(share.head.shareholder).to.equal(5);
    expect(share.head.priceOfPaid).to.equal('1.2');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.closeDeal(). \n');
    
    // ---- Take Gift Share ----

    await expect(gk.connect(signers[1]).takeGiftShares(ia.address, 2)).to.be.revertedWith("caller is not buyer");
    console.log(" \u2714 Passed Access Control Test for gk.takeGiftShares(). \n");

    tx = await gk.connect(signers[3]).takeGiftShares(ia.address, 2);
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.takeGiftShares().");

    await expect(tx).to.emit(ia, "CloseDeal").withArgs(BigNumber.from(2), "0");
    console.log(" \u2714 Passed Event Control Test for ia.CloseDeal(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(2), BigNumber.from(10000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.increaseCleanPaid(). \n");

    await expect(tx).to.emit(ros, "SubAmountFromShare").withArgs(BigNumber.from(2), BigNumber.from(10000 * 10 ** 4), BigNumber.from(10000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.SubAmountFromShare(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(10), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(10);
    expect(share.head.shareholder).to.equal(3);
    expect(share.head.priceOfPaid).to.equal('1.2');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.takeGiftShares(). \n'); 

    tx = await gk.connect(signers[4]).takeGiftShares(ia.address, 3);

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(ia.address, BigNumber.from(6));
    console.log(" \u2714 Passed Event Test for roa.UpdateStateOfFile(). User_3 \n");

    share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(11);
    expect(share.head.shareholder).to.equal(4);
    expect(share.head.priceOfPaid).to.equal('1.2');
    expect(share.body.paid).to.equal('5,000.0');

    console.log(' \u2714 Passed Result Verify Test for gk.takeGiftShares(). User_4 \n'); 

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
