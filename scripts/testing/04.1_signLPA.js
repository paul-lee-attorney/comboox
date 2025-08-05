// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to create and initiate the Limited Partnership
// Agreement (the "LPA") for the Fund registered in ComBoox. As the
// constitutional document, LPA regulates almost all important governance 
// matters for the fund. 

// We defined the governance rules of a LPA as Rules and Terms. Rules define
// the simple matters and Terms define the complicated matters. Please see 
// the White Paper of ComBoox for detailed explanation.

// The scenario for testing included in this section:
// (1) User_1, as the GP / AM, creates the Draft of LPA (the “Draft”);
// (2) User_1 (as Owner of the Draft) appoints itself as the General Counsel 
//     to the Draft, so that it may have the role of "Attorney" to the Draft;
// (3) User_1 (as Attorney to the Draft) creates and sets all Rules and Terms;
// (4) User_1 (as Attorney) sets signing days and closing days of the Draft;
// (5) User_1 (as Attorney) sets itself as the only party to the Draft;
// (6) User_1 (as Owner to the Draft) circulates the Draft;
// (7) User_1 as the GP of the LP sign the Draft;
// (8) As the GP of the Fund, User_1 activates the Draft. After the activation, 
//     the Draft goes into forces as governing LPA to the Fund. 

// Three types of distribution rule are listed as follows:
// (1) interests front rule: 
//        (a) numOfTiers: number of tiers with interests front distribution;
//        (b) isCumulative: wether calculate the interests in a cumulative way;
//        (c) refundPrincipal: whether refund principal with balance amount;
//        (d) tiers array: seq of classes consisting the waterfalls;
//        (e) rates array: interest rate of the class concerned;
//        (f) zero rate: allocate all rest balance to the tier concerned;
// (2) principal front rule: 
//        (a) numOfTiers: number of tiers with principal front distribution;
//        (b) isCumulative: wether calculate the interests in a cumulative way;
//        (d) tiers array: seq of classes consisting the waterfalls;
//        (e) rates array: interest rate of the class concerned;
//        (f) zero rate: allocate all rest balance to the tier concerned;
// (3) hurdle carry rule: 
//        (a) numOfTiers: number of calculation times for carry of AM;
//        (b) tiers[0]: seq of class representing the owner's risks;
//        (c) tiers[1]: always 10000 representing allocation all income to investors
//                      before reaching hurdle rate;
//        (d) tiers[2-(2+numOfTiers)]: allocation ratio to investors;
//        (e) rates array: interest rate to calculate hurdle and carry;
//        (f) zero rate: allocate all rest balance to the tier concerned;

// Write APIs tested in this section:
// 1. FundKeeper
// 1.1 function createSHA(uint version) external;
// 1.2 function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external;
// 1.3 function signSHA(address sha, bytes32 sigHash) external;
// 1.4 function activateSHA(address body) external;

// 2. DraftControl
// 2.1 function setRoleAdmin(bytes32 role, address acct) external;

// 3. ShareholdersAgreement
// 3.1 function addRule(uint seqOfRule, bytes32 rule) external;
// 3.2 function removeRule(uint256 seq) external;
// 3.3 function createTerm(uint title, uint version) external;
// 3.4 function finalizeSHA() external;

// 4. SigPage
// 4.1 function setTiming(bool initPage, uint signingDays, uint closingDays) external;
// 4.2 function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256 acct)
//     external;
// 4.3 function removeBlank(bool initPage, uint256 seqOfDeal, uint256 acct) external;

// 6. LockUp
// 6.1 function setLocker(uint256 seqOfShare, uint dueDate) external;

// Events verified in this section:
// 1. Register of Constitution
// 1.1 event UpdateStateOfFile(address indexed body, uint indexed state);

// 2. Draft Control
// 2.1 event SetRoleAdmin(bytes32 indexed role, address indexed acct);   
// 2.2 event LockContents();

// 3. SigPage
// 3.1 event CirculateDoc();

const { expect } = require("chai");
const { BigNumber, ethers } = require("ethers");
const { readContract } = require("../readTool"); 
const { Bytes32Zero, now } = require('./utils');
const { getROC, getRC, getROD, getROS, getFK } = require("./boox");
const { grParser, grCodifier, vrParser, vrCodifier, prParser, prCodifier, lrParser, lrCodifier, drParser, drCodifier, } = require("./sha");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { printShares } = require("./ros");
const { transferCBP, saveBooxAddr } = require("./saveTool");

async function main() {

    console.log('\n');
    console.log('**************************');
    console.log('**    04.1 Sign LPA     **');
    console.log('**************************');
    console.log('\n');

    // ==== Get Instances ====

	  const signers = await hre.ethers.getSigners();
    const rc = await getRC();
    const gk = await getFK();
    const roc = await getROC();
    const rod = await getROD();
    const ros = await getROS();

    // ==== Create SHA ====

    await expect(gk.connect(signers[5]).createSHA(1) ).to.be.revertedWith("MR.memberExist: not");
    console.log(" \u2714 Passed Access Control Test of rocKeeper.createSHA() for OnlyMember. \n");

    let latest = await rc.counterOfVersions(22);

    let tx = await gk.createSHA(latest);

    let SHA = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.createSHA().");

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.createSHA().");
    console.log(" \u2714 Passed Royalty Check Test for gk.createSHA(). \n");

    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(roc, "UpdateStateOfFile").withArgs(SHA, 1);
    console.log(" \u2714 Passed Event Test for roc.UpdateStateOfFile(). \n");
    
    const shaList = await roc.getFilesList();
    expect(shaList[shaList.length - 1]).to.equal(SHA);
    console.log(" \u2714 Passed Result Verify Test for roc.regFile(). \n");

    const sha = await readContract("ShareholdersAgreement", SHA);

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");

    await expect(sha.connect(signers[1]).setRoleAdmin(ATTORNEYS, signers[0].address)).to.be.revertedWith("O.onlyOwner: NOT");
    console.log(" \u2714 Passed Access Control Test for sha.setRoleAdmin(). \n");
    
    tx = await sha.setRoleAdmin(ATTORNEYS, signers[0].address);

    await expect(tx).to.emit(sha, "SetRoleAdmin").withArgs(ATTORNEYS, signers[0].address);
    console.log(" \u2714 Passed Event Test for sha.SetRoleAdmin(). \n");
    
    expect(await sha.getRoleAdmin(ATTORNEYS)).to.equal(signers[0].address);
    console.log(" \u2714 Passed Result Verify Test for sha.setRoleAdmin(). \n");

    // ---- Set Rules and Terms ----

    // ---- Governance Rule ----

    const estDate = (new Date('2023-11-08')).getTime()/1000;

    let gr = grParser(await sha.getRule(0));

    gr.maxNumOfDirectors = '1';
    gr.establishedDate = estDate;
    gr.businessTermInYears = 99;
    gr.fundApprovalThreshold = '500000';
    gr.typeOfComp = '18';

    await expect(sha.connect(signers[1]).addRule(0, grCodifier(gr))).to.be.revertedWith("AC.onlyAttorney: NOT");
    console.log(" \u2714 Passed Access Control Test for sha.addRule().OnlyAttorney(). \n");

    tx = await sha.addRule(0, grCodifier(gr));

    const newGR = grParser(await sha.getRule(0));
    console.log('newGR:', newGR);

    expect(newGR).to.deep.equal(gr);
    console.log(" \u2714 Passed Result Verify Test for sha.addRule() with Governance Rule. \n");

    // ---- Voting Rule ----

    for (let i=1; i<13; i++) {
      const vr = vrParser(await sha.getRule(i));

      if (i<8 ) {
        vr.amountRatio = '75.00';
        vr.class = '1';
      } else if (i == 8) {
        vr.vetoers[0] = '1';
      } else if (i == 9) {
        vr.class = '1';
      } else if (i == 10) {
        vr.class = '2';
      }

      vr.frExecDays = '0';
      vr.dtExecDays = '0';
      vr.dtConfirmDays = '0';
      vr.execDaysForPutOpt = '0';

      vr.invExitDays = '0';
      vr.votePrepareDays = '0';
      vr.votingDays = '1';

      await sha.addRule(vr.seqOfRule, vrCodifier(vr, i));

      const newVR = vrParser(await sha.getRule(i));
      expect(newVR).to.deep.equal(vr);
      console.log(" \u2714 Passed Result Verify Test for sha.addRule() with Voting Rule No.", i, ". \n");
    }

    // ---- Position Rule ----

    const verifyPR = async (seq, pr) => {
      const newPR = prParser(await sha.getRule(seq));
      expect(newPR).to.deep.equal(pr);
      console.log(" \u2714 Passed Result Verify Test for sha.addRule() with Position Rule No.", seq, ". \n");
    }

    // ---- Fund Manager / Director ----

    let pr = prParser(await sha.getRule(256));
    
    const endDate = (new Date("2026-12-31")).getTime()/1000;

    pr.seqOfRule = 256;
    pr.qtyOfSubRule = 1;
    pr.seqOfSubRule = 1;
    pr.removePos = false;
    pr.seqOfPos = 1; // Asset Manager
    pr.titleOfPos = 5; // Director represent fund manager
    pr.nominator = 1;
    pr.titleOfNominator = 1;
    pr.seqOfVR = 9; // sole decided by the GP
    pr.endDate = endDate;
    
    await sha.addRule(256, prCodifier(pr, 256));
    await verifyPR(256, pr);

    // ---- Listing Rule ----

    const verifyLR = async (seq, lr) => {
      const newLR = lrParser(await sha.getRule(seq));
      expect(newLR).to.deep.equal(lr);
      console.log(" \u2714 Passed Result Verify Test for sha.addRule() with Listing Rule No.", seq, ". \n");
    }

    let lr = lrParser(await sha.getRule(1024));

    lr.seqOfRule = 1024;
    lr.titleOfIssuer = 1;
    lr.classOfShare = 2;
    lr.maxTotalPar = 22000; // 22000 USD
    lr.titleOfVerifier = 1;
    lr.maxQtyOfInvestors = 0;
    lr.votingWeight = 100;
    lr.distrWeight = 100;

    await sha.addRule(1024, lrCodifier(lr, 1024));
    await verifyLR(1024, lr);
    
    // ---- Distr Rule ----

    const verifyDR = async (seq, dr) => {
      const newDR = drParser(await sha.getRule(seq));
      expect(newDR).to.deep.equal(dr);
      console.log(" \u2714 Passed Result Verify Test for sha.addRule() with Distribution Rule No.", seq, ". \n");
    }

    let dr = drParser (await sha.getRule(1280));

    // ---- waterfall profits distribution rule ----

    dr.typeOfDistr = 1;
    dr.numOfTiers = 4;
    dr.isCumulative = true;
    dr.refundPrincipal = false;
    dr.tiers[0] = 2;
    dr.tiers[1] = 3;
    dr.tiers[2] = 4;
    dr.tiers[3] = 5;
    dr.tiers[4] = 0;
    dr.tiers[5] = 0;
    dr.rates[0] = 500;
    dr.rates[1] = 700;
    dr.rates[2] = 1000;
    dr.rates[3] = 0;
    dr.rates[4] = 0;
    dr.rates[5] = 0;

    await sha.addRule(1280, drCodifier(dr));
    await verifyDR(1280, dr);

    // ---- principal front distribution rule ----

    dr.typeOfDistr = 2;
    dr.numOfTiers = 3;
    dr.isCumulative = true;
    dr.refundPrincipal = true;
    dr.tiers[0] = 2;
    dr.tiers[1] = 3;
    dr.tiers[2] = 4;
    dr.tiers[3] = 0;
    dr.tiers[4] = 0;
    dr.tiers[5] = 0;
    dr.rates[0] = 500;
    dr.rates[1] = 700;
    dr.rates[2] = 1000;
    dr.rates[3] = 0;
    dr.rates[4] = 0;
    dr.rates[5] = 0;

    await sha.addRule(1281, drCodifier(dr, 1281));
    await verifyDR(1281, dr);

    // ---- huddle carry distribution rule ----

    dr.typeOfDistr = 3;
    dr.numOfTiers = 2;
    dr.isCumulative = true;
    dr.refundPrincipal = true;
    dr.tiers[0] = 5;
    dr.tiers[1] = 10000;
    dr.tiers[2] = 8000;
    dr.tiers[3] = 2000;
    dr.tiers[4] = 0;
    dr.tiers[5] = 0;
    dr.rates[0] = 800;
    dr.rates[1] = 1000;
    dr.rates[2] = 0;
    dr.rates[3] = 0;
    dr.rates[4] = 0;
    dr.rates[5] = 0;

    await sha.addRule(1282, drCodifier(dr));
    await verifyDR(1282, dr);    

    // ---- Lockup ----

    await sha.createTerm(2, 1);

    const LU = await sha.getTerm(2);
    const lu = await readContract("LockUp", LU);

    const expDate = (await now()) + 86400 * 365 * 5; // 5 years

    // Lock Share_1 till expDate;
    await lu.setLocker(1, expDate);
    expect(await lu.isLocked(1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for lu.setLocker(). \n");
    
    const locker = await lu.getLocker(1);

    expect(locker[0]).to.equal(BigNumber.from(expDate));
    console.log(" \u2714 Passed Result Verify Test for lu.setLocker() and lu.addKeyholder(). \n");

    // ---- Config SigPage of SHA ----

    await sha.setTiming(true, 1, 90);
    
    expect(await sha.getSigningDays()).to.equal(1);
    expect(await sha.getClosingDays()).to.equal(90);

    console.log(" \u2714 Passed Result Verify Test for sha.setTiming(). \n");

    await sha.addBlank(true, false, 1, 1);
    expect(await sha.isParty(1)).to.equal(true);
    expect(await sha.isSeller(true, 1)).to.equal(true);
    expect(await sha.isBuyer(true, 1)).to.equal(false);

    console.log(" \u2714 Passed Result Verify Test for sha.addBlank(). \n");

    await sha.removeBlank(true, 1, 1);
    expect(await sha.isParty(1)).to.equal(false);

    console.log(" \u2714 Passed Result Verify Test for sha.removeBlank(). \n");

    await sha.addBlank(true, false, 1, 1);

    const parties = (await sha.getParties()).map(v=> parseInt(v.toString()));
    expect(parties).to.deep.equal([1]);

    console.log(" \u2714 Passed Result Verify Test for Parties of SHA. \n");

    // ==== Circulate SHA ====

    await expect(gk.circulateSHA(sha.address, Bytes32Zero, Bytes32Zero)).to.be.revertedWith("BOHK.CSHA: SHA not finalized");
    console.log(" \u2714 Passed State Control Test for gk.circulateSHA(). \n");  

    tx = await sha.finalizeSHA();

    await expect(tx).to.emit(sha, "LockContents");
    console.log(" \u2714 Passed Event Test for sha.LockContents(). \n");

    expect(await sha.isFinalized()).to.equal(true);
    expect(await lu.isFinalized()).to.equal(true);
    
    console.log(" \u2714 Passed Resutl Verify Test for sha.finalizeSHA(). \n");    

    await expect(gk.connect(signers[5]).circulateSHA(sha.address, Bytes32Zero, Bytes32Zero)).to.be.revertedWith("MR.memberExist: not");
    console.log(" \u2714 Passed Access Control Test for gk.circulateSHA().OnlyParty(). \n ");

    await expect(gk.signSHA(sha.address, Bytes32Zero)).to.be.revertedWith("SHA not in Circulated State");
    console.log(" \u2714 Passed State Control Test for gk.signSHA(). \n ");


    tx = await gk.circulateSHA(sha.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.createSHA().");

    transferCBP("1", "8", 18n);

    expect(tx).to.emit(roc, "UpdateStateOfFile").withArgs(sha.address, 2);
    console.log(" \u2714 Passed Event Test for roc.UpdateStateOfFile().\n");

    expect(tx).to.emit(sha, "CirculateDoc");
    console.log(" \u2714 Passed Event Test for sha.CirculateDoc().\n");    

    expect(await sha.circulated()).to.equal(true);

    let circulateDate = await sha.getCirculateDate();
    expect(await sha.getSigDeadline()).to.equal(circulateDate + 86400);
    expect(await sha.getClosingDeadline()).to.equal(circulateDate + 86400 * 90);

    console.log(" \u2714 Passed Result Verify Test for gk.circulateSHA().\n");

    // ==== Sign SHA ====

    await expect(gk.connect(signers[5]).signSHA(sha.address, Bytes32Zero)).to.be.revertedWith("NOT Party of Doc");
    console.log(" \u2714 Passed Access Control Test for gk.signSHA().OnlyParty(). \n ");

    tx = await gk.signSHA(sha.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.signSHA().");

    transferCBP("1", "8", 18n);

    expect(await sha.isSigner(1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signSHA().\n");

    expect(await sha.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for all gk.signSHA().\n");

    // ==== Enactivate SHA ====

    await expect(gk.connect(signers[5]).activateSHA(sha.address)).to.be.revertedWith("NOT Party of Doc");
    console.log(" \u2714 Passed Access Control Test for gk.activateSHA().OnlyParty(). \n ");

    tx = await gk.activateSHA(sha.address);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.activateSHA().");

    transferCBP("1", "8", 58n);

    expect(tx).to.emit(roc, "UpdateStateOfFile").withArgs(sha.address, 6);
    console.log(" \u2714 Passed Event Test for roc.UpdateStateOfFile().\n");

    expect(tx).to.emit(rod, "AddPosition");
    console.log(" \u2714 Passed Event Test for rod.AddPosition().\n");

    const governingSHA = await roc.pointer();

    expect(governingSHA).to.equal(sha.address);
    console.log(" \u2714 Passed Result Verify Test for gk.activateSHA().\n");

    // ==== save to boox ====

    saveBooxAddr("SHA", governingSHA);

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
