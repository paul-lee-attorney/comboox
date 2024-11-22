// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to create and initiate the Shareholders
// Agreement (the "SHA") for the company registered in ComBoox. As the
// constitutional document, SHA regulates almost all important governance 
// matters for a company. 

// We defined the governance rules of a SHA as Rules and Terms. Rules define
// the simple matters and Terms define the complicated matters. Please see 
// the White Paper of ComBoox for detailed explanation.

// The scenario for testing included in this section:
// (1) User_1 creates the Draft of SHA (the “Draft”);
// (2) User_1 (as Owner of the Draft) appoints itself as the General Counsel 
//     to the Draft, so that it may have the role of "Attorney" to the Draft;
// (3) User_1 (as Attorney to the Draft) creates and sets all Rules and Terms;
// (4) User_1 (as Attorney) sets signing days and closing days of the Draft;
// (5) User_1 (as Attorney) sets parties to the Draft;
// (6) User_1 (as Owner to the Draft) circulates the Draft to Members;
// (7) Members of the DAO sign the Draft;
// (8) After all Members signed the Draft, User_1 (as Member and Party thereof)
//     activates the Draft. After the activation, the Draft goes into forces as
//     governing SHA to the DAO. 

// Write APIs tested in this section:
// 1. GeneralKeeper
// 1.1 function createSHA(uint version) external;
// 1.2 function circulateSHA(address body, bytes32 docUrl, bytes32 docHash) external;
// 1.3 function signSHA(address sha, bytes32 sigHash) external;
// 1.4 function activateSHA(address body) external;

// 2. DraftControl
// 2.1 function setRoleAdmin(bytes32 role, address acct) external;

// 3. ShareholdersAgreement
// 3.1 function addRule(bytes32 rule) external;
// 3.2 function removeRule(uint256 seq) external;
// 3.3 function createTerm(uint title, uint version) external;
// 3.4 function finalizeSHA() external;

// 4. SigPage
// 4.1 function setTiming(bool initPage, uint signingDays, uint closingDays) external;
// 4.2 function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256 acct)
//     external;
// 4.3 function removeBlank(bool initPage, uint256 seqOfDeal, uint256 acct) external;

// 5. AntiDilution
// 5.1 function addBenchmark(uint256 class, uint price) external;
// 5.2 function removeBenchmark(uint256 class) external;
// 5.3 function addObligor(uint256 class, uint256 obligor) external;
// 5.4 function removeObligor(uint256 class, uint256 obligor) external;

// 6. LockUp
// 6.1 function setLocker(uint256 seqOfShare, uint dueDate) external;
// 6.2 function delLocker(uint256 seqOfShare) external;
// 6.3 function addKeyholder(uint256 seqOfShare, uint256 keyholder) external;
// 6.4 function removeKeyholder(uint256 seqOfShare, uint256 keyholder) external;

// 7. Alongs
// 7.1 function addDragger(bytes32 rule, uint256 dragger) external;
// 7.2 function removeDragger(uint256 dragger) external;
// 7.3 function addFollower(uint256 dragger, uint256 follower) external;
// 7.4 function removeFollower(uint256 dragger, uint256 follower) external;

// 8. Options 
// 8.1 function createOption(bytes32 snOfOpt, bytes32 snOfCond, uint rightholder,
//     uint paid, uint par) external
// 8.2 function delOption(uint256 seqOfOpt) external returns(bool flag);
// 8.3 function addObligorIntoOpt(uint256 seqOfOpt, uint256 obligor) external;
// 8.4 function removeObligorFromOpt(uint256 seqOfOpt, uint256 obligor) external

const { expect } = require("chai");
const { BigNumber, ethers } = require("ethers");
const { readContract } = require("../readTool"); 
const { Bytes32Zero, now } = require('./utils');
const { getROC, getGK, getRC, getROO, getROD } = require("./boox");
const { grParser, grCodifier, vrParser, vrCodifier, prParser, prCodifier, lrParser, lrCodifier, alongRuleCodifier, alongRuleParser } = require("./sha");
const { codifyHeadOfOption, codifyCond, parseOption } = require("./roo");
const { royaltyTest } = require("./rc");

async function main() {

    console.log('\n********************************');
    console.log('**    04. Create SHA          **');
    console.log('********************************\n');

    // ==== Get Instances ====

	  const signers = await hre.ethers.getSigners();
    const rc = await getRC();
    const gk = await getGK();
    const roc = await getROC();
    const roo = await getROO();
    const rod = await getROD();

    // ==== Create SHA ====

    await expect(gk.connect(signers[5]).createSHA(1) ).to.be.revertedWith("not MEMBER");
    console.log(" \u2714 Passed Access Control Test of rocKeeper.createSHA() for OnlyMember. \n");

    let tx = await gk.createSHA(1);

    let SHA = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.createSHA().");

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

    await tx.wait();

    await expect(tx).to.emit(sha, "SetRoleAdmin").withArgs(ATTORNEYS, signers[0].address);
    console.log(" \u2714 Passed Event Test for sha.SetRoleAdmin(). \n");
    
    expect(await sha.getRoleAdmin(ATTORNEYS)).to.equal(signers[0].address);
    console.log(" \u2714 Passed Result Verify Test for sha.setRoleAdmin(). \n");

    // ---- Set Rules and Terms ----

    // ---- Governance Rule ----

    const estDate = (new Date('2023-11-08')).getTime()/1000;

    let gr = grParser(await sha.getRule(0));

    gr.establishedDate = estDate;
    gr.businessTermInYears = 99;

    await expect(sha.connect(signers[1]).addRule(grCodifier(gr))).to.be.revertedWith("AC.onlyAttorney: NOT");
    console.log(" \u2714 Passed Access Control Test for sha.addRule().OnlyAttorney(). \n");

    await sha.addRule(grCodifier(gr));

    let newGR = grParser(await sha.getRule(0));
    expect(newGR).to.deep.equal(gr);
    console.log(" \u2714 Passed Result Verify Test for sha.addRule() with Governance Rule. \n");

    // ---- Voting Rule ----

    for (let i=1; i<13; i++) {
      const vr = vrParser(await sha.getRule(i));

      if (i<8 ) {
        vr.frExecDays = 1;
        vr.dtExecDays = 1;
        vr.dtConfirmDays = 1;
        vr.execDaysForPutOpt = 1;  
      } 

      vr.invExitDays = 1;
      vr.votePrepareDays = 0;
      vr.votingDays = 1;

      await sha.addRule(vrCodifier(vr, i));

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

    // ---- Chairman ----

    let pr = prParser(await sha.getRule(256));
    
    const endDate = (new Date("2026-12-31")).getTime()/1000;

    pr.seqOfRule = 256;
    pr.qtyOfSubRule = 3;
    pr.seqOfSubRule = 1;
    pr.removePos = false;
    pr.seqOfPos = 1;
    pr.titleOfPos = 2;
    pr.nominator = 1;
    pr.titleOfNominator = 1;
    pr.seqOfVR = 9;
    pr.endDate = endDate;
    
    await sha.addRule(prCodifier(pr, 256));
    await verifyPR(256, pr);

    // ---- CEO ----

    pr = prParser(await sha.getRule(257));
    
    pr.seqOfRule = 257;
    pr.qtyOfSubRule = 3;
    pr.seqOfSubRule = 2;
    pr.removePos = false;
    pr.seqOfPos = 2;
    pr.titleOfPos = 6;
    pr.nominator = 0;
    pr.titleOfNominator = 2;
    pr.seqOfVR = 11;
    pr.endDate = endDate;

    await sha.addRule(prCodifier(pr, 257));
    await verifyPR(257, pr);

    // ---- Manager ----

    pr = prParser(await sha.getRule(258));
    
    pr.seqOfRule = 258;
    pr.qtyOfSubRule = 3;
    pr.seqOfSubRule = 3;
    pr.removePos = false;
    pr.seqOfPos = 3;
    pr.titleOfPos = 14;
    pr.nominator = 0;
    pr.titleOfNominator = 6;
    pr.seqOfVR = 11;
    pr.endDate = endDate;

    await sha.addRule(prCodifier(pr, 258));
    await verifyPR(258, pr);

    // ---- Listing Rule ----

    const verifyLR = async (seq, lr) => {
      const newLR = lrParser(await sha.getRule(seq));
      expect(newLR).to.deep.equal(lr);
      console.log(" \u2714 Passed Result Verify Test for sha.addRule() with Listing Rule No.", seq, ". \n");
    }

    let lr = lrParser(await sha.getRule(1024));

    lr.seqOfRule = 1024;
    lr.titleOfIssuer = 2;
    lr.classOfShare = 2;
    lr.maxTotalPar = 10000000;
    lr.titleOfVerifier = 2;
    lr.maxQtyOfInvestors = 0;
    lr.votingWeight = 100;
    lr.distrWeight = 100;

    await sha.addRule(lrCodifier(lr, 1024));
    await verifyLR(1024, lr);

    // ---- AntiDilution ----
    
    await sha.createTerm(1, 1);

    const AD = await sha.getTerm(1);
    const ad = await readContract("AntiDilution", AD);
    
    // User_2 does not have "Attorney" role, thus, shall be blocked
    // and reverted with error message.

    await expect(ad.connect(signers[1]).addBenchmark(2, 15000)).to.be.revertedWith("AC.onlyAttorney: NOT");
    console.log(" \u2714 Passed Access Control Test for ad.OnlyAttorney(). \n");

    // set floor price of class No.2 as 1.5 USD
    await ad.addBenchmark(2, 15000);            
    let floor = await ad.getFloorPriceOfClass(2);
    expect(floor).to.equal(15000);
    console.log(' \u2714 Passed Result Verify Test for ad.addBenckmark(). \n');
        
    // set floor price of class No.1 as 1.5 USD.
    await ad.addBenchmark(1, 12000);
    // remove benchmark set for class No.1
    await ad.removeBenchmark(1);
    expect(await ad.isMarked(1)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for ad.removeBenchmark(). \n");

    // add User_2 as obligor under class 2.
    await ad.addObligor(2, 2);
    expect(await ad.isObligor(2, 2)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for ad.addObligor(). \n");

    // add User_1 as obligor under class 2.
    await ad.addObligor(2, 1);
    await ad.removeObligor(2, 1);
    expect(await ad.isObligor(2, 1)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for ad.removeObligor(). \n");
    
    // ---- Lockup ----

    await sha.createTerm(2, 1);

    const LU = await sha.getTerm(2);
    const lu = await readContract("LockUp", LU);

    const expDate = Math.floor((new Date()).getTime()/1000) + 86400 * 60;

    // Lock Share_1 till expDate;
    await lu.setLocker(1, expDate);
    expect(await lu.isLocked(1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for lu.setLocker(). \n");

    await lu.setLocker(2, expDate);
    await lu.delLocker(2);
    expect(await lu.isLocked(2)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for lu.delLocker(). \n");
    
    await lu.addKeyholder(1, 3);
    await lu.addKeyholder(1, 4);

    const locker = await lu.getLocker(1);

    expect(locker[0]).to.equal(BigNumber.from(expDate));
    expect(locker[1]).to.deep.equal([BigNumber.from(3), BigNumber.from(4)]);    
    console.log(" \u2714 Passed Result Verify Test for lu.setLocker() and lu.addKeyholder(). \n");

    // ---- Drag Along ----

    await sha.createTerm(3, 1);

    const DA = await sha.getTerm(3);
    const da = await readContract("Alongs", DA);

    let alongRule = {
        triggerDate: 0,
        effectiveDays: 0,
        triggerType: 2,
        shareRatioThreshold: 30,
        rate: 2,
        proRata: true,
        seq: 0,
        para: 0,
        argu: 0,
        ref: 0,
        data: 0,
    }

    await da.addDragger(alongRuleCodifier(alongRule), 1);
    expect(await da.isDragger(1)).to.equal(true);

    let retAlongRule = alongRuleParser(await da.getLinkRule(1));    
    expect(retAlongRule).to.deep.equal(alongRule);

    console.log(" \u2714 Passed Result Verify Test for ad.addDragger(). \n");

    await da.addDragger(alongRuleCodifier(alongRule), 2);
    expect(await da.isDragger(2)).to.equal(true);

    await da.removeDragger(2);
    expect(await da.isDragger(2)).to.equal(false);
    
    console.log(" \u2714 Passed Result Verify Test for ad.removeDragger(). \n");
    
    await da.addFollower(1, 3);
    expect(await da.isFollower(1, 3)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for ad.addFollower(). \n");
    
    await da.addFollower(1, 4);
    await da.removeFollower(1, 4);
    expect(await da.isFollower(1, 4)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for ad.removeFollower(). \n");

    await da.addFollower(1, 4);

    let draggers = (await da.getDraggers()).map(v => parseInt(v));
    expect(draggers).to.deep.equal([1]);

    let followers = (await da.getFollowers(1)).map(v => parseInt(v));
    expect(followers).to.deep.equal([3, 4]);    
    
    console.log(" \u2714 Passed Result Verify Test for Drag Along. \n");

    // ---- Tag Along ----
    
    await sha.createTerm(4, 1);

    const TA = await sha.getTerm(4);
    const ta = await readContract("Alongs", TA);

    alongRule = {
        triggerDate: 0,
        effectiveDays: 0,
        triggerType: 1,
        shareRatioThreshold: 30,
        rate: 0,
        proRata: true,
        seq: 0,
        para: 0,
        argu: 0,
        ref: 0,
        data: 0,
    }

    await ta.addDragger(alongRuleCodifier(alongRule), 1);

    await ta.addFollower(1, 3);
    await ta.addFollower(1, 4);

    draggers = (await ta.getDraggers()).map(v => parseInt(v));
    expect(draggers).to.deep.equal([1]);

    followers = (await ta.getFollowers(1)).map(v => parseInt(v));
    expect(followers).to.deep.equal([3, 4]);    
    
    console.log(" \u2714 Passed Result Verify Test for Tag Along. \n");

    // ---- Call / Put Option ----

    await sha.createTerm(5, 1);
    const OP = await sha.getTerm(5);
    const op = await readContract("Options", OP);

    let today = await now();
    const triggerDate = today + 86400 * 10;
    
    let headOfOpt = {
        seqOfOpt: 1,
        typeOfOpt: 4,
        classOfShare: 2,
        rate: 1.1,
        issueDate: today,
        triggerDate: triggerDate,
        execDays: 90,
        closingDays: 3,
        obligor: 3,
    };

    let cond = {
      seqOfCond: 1,
      logicOpr: 2, // ||
      compOpr1: 4, // <
      para1: 1000,
      compOpr2: 4, // <
      para2: 100,
      compOpr3: 0,
      para3: 0,
    };

    await op.createOption(codifyHeadOfOption(headOfOpt), codifyCond(cond), 2, 500 * 10 ** 4, 500 * 10 ** 4);

    let retOpt = parseOption(await op.getOption(1));
    expect(retOpt.head).to.deep.equal(headOfOpt);
    expect(retOpt.cond).to.deep.equal(cond);
    expect(retOpt.body.rightholder).to.equal(2);
    expect(retOpt.body.paid).to.equal(500);
    expect(retOpt.body.par).to.equal(500);
    expect(retOpt.body.closingDeadline).to.equal(triggerDate + 86400 * (93));
    expect(retOpt.body.state).to.equal("Pending");
    
    console.log(" \u2714 Passed Result Verify Test for op.createOption(). \n");

    await op.createOption(codifyHeadOfOption(headOfOpt), codifyCond(cond), 2, 500 * 10 ** 4, 500 * 10 ** 4);
    expect(await op.isOption(2)).to.equal(true);
    
    await op.delOption(2);
    expect(await op.isOption(2)).to.equal(false);
    
    console.log(" \u2714 Passed Result Verify Test for op.delOption(). \n");
        
    headOfOpt = {
      seqOfOpt: 2,
      typeOfOpt: 5,
      classOfShare: 2,
      rate: 1.8,
      issueDate: today,
      triggerDate: triggerDate,
      execDays: 90,
      closingDays: 3,
      obligor: 2,
    };

    cond = {
      seqOfCond: 0,
      logicOpr: 1, // &
      compOpr1: 3, // >
      para1: 5000,
      compOpr2: 3,
      para2: 500,
      compOpr3: 0,
      para3: 0,
    };

    await op.createOption(codifyHeadOfOption(headOfOpt), codifyCond(cond), 3, 500 * 10 ** 4, 500 * 10 ** 4);

    await op.addObligorIntoOpt(3, 1);
    expect(await op.isObligor(3, 1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for op.addObligorIntoOpt(). \n");
    
    await op.removeObligorFromOpt(3, 1);
    expect(await op.isObligor(3, 1)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for op.removeObligorFromOpt(). \n");
    
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
    await sha.addBlank(true, false, 1, 2);
    await sha.addBlank(true, true, 1, 3);
    await sha.addBlank(true, true, 1, 4);

    const parties = (await sha.getParties()).map(v=> parseInt(v.toString()));
    expect(parties).to.deep.equal([3, 4, 1, 2]);

    console.log(" \u2714 Passed Result Verify Test for Parties of SHA. \n");

    // ==== Circulate SHA ====

    await expect(gk.circulateSHA(sha.address, Bytes32Zero, Bytes32Zero)).to.be.revertedWith("BOHK.CSHA: SHA not finalized");
    console.log(" \u2714 Passed State Control Test for gk.circulateSHA(). \n");  

    await sha.finalizeSHA();

    expect(await sha.isFinalized()).to.equal(true);
    expect(await ad.isFinalized()).to.equal(true);
    expect(await lu.isFinalized()).to.equal(true);
    expect(await da.isFinalized()).to.equal(true);
    expect(await ta.isFinalized()).to.equal(true);
    expect(await op.isFinalized()).to.equal(true);
    
    console.log(" \u2714 Passed Resutl Verify Test for sha.finalizeSHA(). \n");    

    await expect(gk.connect(signers[5]).circulateSHA(sha.address, Bytes32Zero, Bytes32Zero)).to.be.revertedWith("NOT Party of Doc");
    console.log(" \u2714 Passed Access Control Test for gk.circulateSHA().OnlyParty(). \n ");

    await expect(gk.signSHA(sha.address, Bytes32Zero)).to.be.revertedWith("SHA not in Circulated State");
    console.log(" \u2714 Passed State Control Test for gk.signSHA(). \n ");


    tx = await gk.circulateSHA(sha.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.createSHA().");

    expect(tx).to.emit(roc, "UpdateStateOfFile").withArgs(sha.address, 2);
    console.log(" \u2714 Passed Event Test for roc.UpdateStateOfFile().\n");

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

    expect(await sha.isSigner(1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signSHA().\n");

    await gk.connect(signers[1]).signSHA(sha.address, Bytes32Zero);
    await gk.connect(signers[3]).signSHA(sha.address, Bytes32Zero);
    await gk.connect(signers[4]).signSHA(sha.address, Bytes32Zero);

    expect(await sha.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for all gk.signSHA().\n");

    // ==== Enactivate SHA ====

    await expect(gk.connect(signers[5]).activateSHA(sha.address)).to.be.revertedWith("NOT Party of Doc");
    console.log(" \u2714 Passed Access Control Test for gk.activateSHA().OnlyParty(). \n ");

    tx = await gk.activateSHA(sha.address);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.activateSHA().");

    expect(tx).to.emit(roc, "UpdateStateOfFile").withArgs(sha.address, 6);
    console.log(" \u2714 Passed Event Test for roc.UpdateStateOfFile().\n");

    expect(tx).to.emit(roo, "CreateOpt");
    console.log(" \u2714 Passed Event Test for roo.CreateOpt().\n");

    expect(tx).to.emit(rod, "AddPosition");
    console.log(" \u2714 Passed Event Test for rod.AddPosition().\n");

    const governingSHA = await gk.getSHA();
    expect(governingSHA).to.equal(sha.address);
    console.log(" \u2714 Passed Result Verify Test for gk.activateSHA().\n");

}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
