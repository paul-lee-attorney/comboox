// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { getGK, getROA, getGMM, getROS, getROM, } = require("./boox");
const { readContract } = require("../readTool"); 
const { parseTimestamp, increaseTime, Bytes32Zero, now, } = require("./utils");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { printShares } = require("./ros");
const { printMembers } = require("./rom");


async function main() {

    console.log('********************************');
    console.log('**     Internal Transfer      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    
    // ==== Create Investment Agreement ====

    await gk.createIA(1);
    const iaList = await roa.getFilesList();
    console.log('iaList:', iaList);

    const IA = iaList[iaList.length - 1];
    const ia = await readContract("InvestmentAgreement", IA);

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    await ia.setRoleAdmin(ATTORNEYS, signers[0].address);
    console.log('GC of IA:', await ia.getRoleAdmin(ATTORNEYS), "\n");

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const headOfDeal = {
      typeOfDeal: 3,
      seqOfDeal: 0,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 6,
      seller: 6,
      priceOfPaid: 2.1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 3, 3, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    const deal = await ia.getDeal(1);
    console.log('created deal:', parseDeal(deal), "\n");

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);
    console.log('IA signing days:', await ia.getSigningDays(), 'closing days:', await ia.getClosingDays(), '\n');

    await ia.addBlank(true, false, 1, 6);
    await ia.addBlank(true, true, 1, 3);

    console.log('Parties of IA:', (await ia.getParties()).map(v=>v.toString()), '\n');

    // ---- Sign IA ----

    await ia.finalizeIA();
    console.log('IA is finalized ?', await ia.isFinalized(), "\n");

    await gk.connect(signers[6]).circulateIA(ia.address, Bytes32Zero, Bytes32Zero);
    console.log('IA is circulated ?', await ia.circulated(), "\n");

    console.log('IA circulated date:', parseTimestamp(await ia.getCirculateDate()));
    console.log('IA sig Deadline:', parseTimestamp(await ia.getSigDeadline()));
    console.log('IA closing Deadline:', parseTimestamp(await ia.getClosingDeadline()), "\n");

    await gk.connect(signers[6]).signIA(ia.address, Bytes32Zero);
    console.log('IA is signed by User_6 ?', await ia.isSigner(6), "\n");

    await gk.connect(signers[3]).signIA(ia.address, Bytes32Zero);
    console.log('IA is signed by User_3 ?', await ia.isSigner(3), "\n");

    console.log('IA is established ?', await ia.established(), '\n');

    // ==== Voting For IA ====

    await increaseTime(86400 * 3);
    
    const doc = BigInt(ia.address);

    await gk.connect(signers[6]).proposeDocOfGM(doc, 3, 6);

    const gmmList = (await gmm.getSeqList()).map(v => Number(v));
    console.log('obtained GMM List:', gmmList, "\n");

    let seqOfMotion = gmmList[gmmList.length - 1];
    console.log('motion', seqOfMotion, 'is proposed ?', await gmm.isProposed(seqOfMotion), '\n');

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_1 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 1), '\n');

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_2 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 2), '\n');

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_4 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 4), '\n');

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    console.log('Motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');

    const centPrice = await gk.getCentPrice();
    const value = 210n * 10000n * BigInt(centPrice) + 100n;

    await gk.connect(signers[3]).payOffApprovedDeal(ia.address, 1, {value: value});

    await printShares(ros);

    await printMembers(rom);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  