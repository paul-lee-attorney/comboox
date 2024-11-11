// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { readContract } = require("../readTool"); 
const { parseTimestamp, Bytes32Zero, now } = require('./utils');
const { getROC, getGK } = require("./boox");
const { grParser, grCodifier, vrParser, vrCodifier, prParser, prCodifier, lrParser, lrCodifier, alongRuleCodifier, alongRuleParser } = require("./sha");
const { codifyHeadOfOption, codifyCond, parseOption } = require("./roo");

async function main() {

    console.log('********************************');
    console.log('**        Create SHA          **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const roc = await getROC();

    // ==== Create SHA ====

    await gk.createSHA(1);
    const shaList = await roc.getFilesList();
    console.log('shaList:', shaList);

    const SHA = shaList[shaList.length - 1];
    const sha = await readContract("ShareholdersAgreement", SHA);

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    await sha.setRoleAdmin(ATTORNEYS, signers[0].address);
    console.log('GC of SHA:', await sha.getRoleAdmin(ATTORNEYS), "\n");

    // ---- Set Rules and Terms ----

    // ---- Governance Rule ----

    const estDate = (new Date('2023-11-08')).getTime()/1000;

    let gr = grParser(await sha.getRule(0));
    // console.log("Default GovernanceRule:", gr, "\n");

    gr.establishedDate = estDate;
    gr.businessTermInYears = 99;
    await sha.addRule(grCodifier(gr));

    gr = grParser(await sha.getRule(0));
    console.log("Updated GovernanceRule:", gr, "\n");

    // ---- Voting Rule ----

    for (let i=1; i<13; i++) {
      let vr = vrParser(await sha.getRule(i));
      // console.log("Default VotingRule", i, ":", vr, "\n");

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
      vr = vrParser(await sha.getRule(i));
      console.log("Updated VotingRule", i, ":", vr, "\n");
    }

    // ---- Position Rule ----

    const getPR = async (seq) => {
      const pr = prParser(await sha.getRule(seq));
      console.log("PositionAllocationRule", seq, ":", pr, "\n"); 
      return pr;
    }

    let pr = await getPR(256);
    
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
    await getPR(256);

    pr = await getPR(257);
    
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
    await getPR(257);

    pr = await getPR(258);
    
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
    await getPR(258);

    // ---- Listing Rule ----

    const getLR = async (seq) => {
      const lr = lrParser(await sha.getRule(seq));
      console.log("ListRule", seq, ":", lr, "\n"); 
      return lr;
    }

    let lr = await getLR(1024);

    lr.seqOfRule = 1024;
    lr.titleOfIssuer = 2;
    lr.classOfShare = 2;
    lr.maxTotalPar = 10000000;
    lr.titleOfVerifier = 2;
    lr.maxQtyOfInvestors = 0;
    lr.votingWeight = 100;
    lr.distrWeight = 100;

    await sha.addRule(lrCodifier(lr, 1024));
    await getLR(1024);

    // ---- AntiDilution ----
    
    await sha.createTerm(1, 1);

    const AD = await sha.getTerm(1);
    const ad = await readContract("AntiDilution", AD);
    
    await ad.addBenchmark(2, 15000);
    const floor = await ad.getFloorPriceOfClass(2);
    console.log('Floor Price of Class 2:', ethers.utils.formatUnits(floor, 4));
    
    await ad.addObligor(2, 1);
    await ad.addObligor(2, 2);
    const obligors = await ad.getObligorsOfAD(2);
    console.log('Obligors:', obligors.map(v => Number(v)), "\n");

    // ---- Lockup ----

    await sha.createTerm(2, 1);

    const LU = await sha.getTerm(2);
    const lu = await readContract("LockUp", LU);

    const expDate = Math.floor((new Date()).getTime()/1000) + 86400 * 60;

    await lu.setLocker(1, expDate);
    console.log('shares locked:', (await lu.lockedShares()).map(v => v.toString()), '\n');

    await lu.addKeyholder(1, 3);
    await lu.addKeyholder(1, 4);
    const locker = await lu.getLocker(1);
    console.log('expDate:', parseTimestamp(locker[0]));
    console.log('keyHolders:', locker[1].map(v => v.toString()));

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
    console.log('Along Rule Dragged by User_1:', alongRuleParser(await da.getLinkRule(1)), "\n");

    await da.addFollower(1, 3);
    await da.addFollower(1, 4);   
    console.log('User_1 may drag the followers:', (await da.getFollowers(1)).map(v => v.toString()), "\n");

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
    console.log('Along Rule Tagged to User_1:', alongRuleParser(await ta.getLinkRule(1)), "\n");

    await ta.addFollower(1, 3);
    await ta.addFollower(1, 4);   
    console.log('User_1 tagged by the followers:', (await ta.getFollowers(1)).map(v => v.toString()), "\n");

    // ---- Call / Put Option ----

    await sha.createTerm(5, 1);
    const OP = await sha.getTerm(5);
    const op = await readContract("Options", OP);


    const today = await now();
    const triggerDate = today + 86400 * 10;
    
    let headOfOpt = {
        seqOfOpt: 0,
        typeOfOpt: 4,
        classOfShare: 2,
        rate: 1.1,
        issueDate: today,
        triggerDate: triggerDate,
        execDays: 55,
        closingDays: 3,
        obligor: 3,
    };

    let cond = {
      seqOfCond: 0,
      logicOpr: 2,
      compOpr1: 4,
      para1: 1000,
      compOpr2: 4,
      para2: 100,
      compOpr3: 0,
      para3: 0,
    };

    await op.createOption(codifyHeadOfOption(headOfOpt), codifyCond(cond), 2, 500 * 10 ** 4, 500 * 10 ** 4);
    console.log('create Opt:', parseOption(await op.getOption(1)), '\n');
    
    headOfOpt = {
      seqOfOpt: 0,
      typeOfOpt: 5,
      classOfShare: 2,
      rate: 1.8,
      issueDate: today,
      triggerDate: triggerDate,
      execDays: 55,
      closingDays: 3,
      obligor: 2,
    };

    cond = {
      seqOfCond: 0,
      logicOpr: 1,
      compOpr1: 3,
      para1: 5000,
      compOpr2: 3,
      para2: 500,
      compOpr3: 0,
      para3: 0,
    };

    await op.createOption(codifyHeadOfOption(headOfOpt), codifyCond(cond), 3, 500 * 10 ** 4, 500 * 10 ** 4);
    console.log('create Opt:', parseOption(await op.getOption(2)), '\n');
    
    // ---- Config SigPage of SHA ----

    await sha.setTiming(true, 1, 90);
    console.log('SHA signing days:', await sha.getSigningDays(), 'closing days:', await sha.getClosingDays(), '\n');

    await sha.addBlank(true, false, 1, 1);
    await sha.addBlank(true, false, 1, 2);
    await sha.addBlank(true, true, 1, 3);
    await sha.addBlank(true, true, 1, 4);

    console.log('Parties of SHA:', (await sha.getParties()).map(v=>v.toString()), '\n');

    // ---- Sign SHA ----

    await sha.lockContents();
    console.log('SHA is finalized ?', await sha.isFinalized(), "\n");

    await gk.circulateSHA(sha.address, Bytes32Zero, Bytes32Zero);
    console.log('SHA is circulated ?', await sha.circulated(), "\n");

    console.log('SHA circulated date:', parseTimestamp(await sha.getCirculateDate()));
    console.log('SHA sig Deadline:', parseTimestamp(await sha.getSigDeadline()));
    console.log('SHA closing Deadline:', parseTimestamp(await sha.getClosingDeadline()), "\n");

    await gk.signSHA(sha.address, Bytes32Zero);
    console.log('SHA is signed by User_1 ?', await sha.isSigner(1), "\n");

    await gk.connect(signers[1]).signSHA(sha.address, Bytes32Zero);
    console.log('SHA is signed by User_2 ?', await sha.isSigner(2), "\n");

    await gk.connect(signers[3]).signSHA(sha.address, Bytes32Zero);
    console.log('SHA is signed by User_3 ?', await sha.isSigner(3), "\n");

    await gk.connect(signers[4]).signSHA(sha.address, Bytes32Zero);
    console.log('SHA is signed by User_4 ?', await sha.isSigner(4), "\n");

    console.log('SHA is established ?', await sha.established(), '\n');

    await gk.activateSHA(sha.address);
    console.log('Governing SHA:', await gk.getSHA());
    console.log('Address of SHA:', sha.address, "\n");

}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
