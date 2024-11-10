// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { getGK, getROA, getGMM, getROS, getROM, } = require("./boox");
const { readContract } = require("../readTool"); 
const { parseTimestamp, increaseTime, Bytes32Zero, now, parseUnits, } = require("./utils");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { printShares } = require("./ros");
const { printMembers } = require("./rom");


async function main() {

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    
    // ==== Create Investment Agreement ====

    await gk.connect(signers[5]).createIA(1);
    const iaList = await roa.getFilesList();
    console.log('iaList:', iaList);

    const IA = iaList[iaList.length - 1];
    const ia = await readContract("InvestmentAgreement", IA);

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    await ia.connect(signers[5]).setRoleAdmin(ATTORNEYS, signers[0].address);
    console.log('GC of IA:', await ia.getRoleAdmin(ATTORNEYS), "\n");

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const createDeal = async (headOfDeal, amt) => {

      await ia.addDeal(codifyHeadOfDeal(headOfDeal), 6, 6, amt * 10 ** 4, amt * 10 ** 4, 100);

      const dealsList = (await ia.getSeqList()).map(v => Number(v));
      const deal = await ia.getDeal(dealsList[dealsList.length - 1]);
      console.log('created deal:', parseDeal(deal), "\n");
    }

    let headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 0,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 8,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    await createDeal(headOfDeal, 10000);    

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 0,
      preSeq: 0,
      classOfShare: 1,
      seqOfShare: 11,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await createDeal(headOfDeal, 95000);

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 0,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 12,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await createDeal(headOfDeal, 9000);

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 0,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 13,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await createDeal(headOfDeal, 20000);

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);
    console.log('IA signing days:', await ia.getSigningDays(), 'closing days:', await ia.getClosingDays(), '\n');

    await ia.addBlank(true, false, 1, 5);
    await ia.addBlank(true, true, 1, 6);

    console.log('Parties of IA:', (await ia.getParties()).map(v=>v.toString()), '\n');

    // ---- Circulate IA ----

    await ia.connect(signers[5]).finalizeIA();
    console.log('IA is finalized ?', await ia.isFinalized(), "\n");

    await gk.connect(signers[5]).circulateIA(ia.address, Bytes32Zero, Bytes32Zero);
    console.log('IA is circulated ?', await ia.circulated(), "\n");

    console.log('IA circulated date:', parseTimestamp(await ia.getCirculateDate()));
    console.log('IA sig Deadline:', parseTimestamp(await ia.getSigDeadline()));
    console.log('IA closing Deadline:', parseTimestamp(await ia.getClosingDeadline()), "\n");

    // ---- Sign IA ----

    await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);
    console.log('IA is signed by User_5 ?', await ia.isSigner(5), "\n");

    await gk.connect(signers[6]).signIA(ia.address, Bytes32Zero);
    console.log('IA is signed by User_6 ?', await ia.isSigner(1), "\n");

    console.log('IA is established ?', await ia.established(), '\n');

    // ==== Exec First Refusal ====

    await increaseTime(86400 * 1);

    for (let i=1; i<=4; i++){
      await gk.execFirstRefusal(513, 1, ia.address, i, ethers.utils.id(signers[0].address));
      await gk.connect(signers[1]).execFirstRefusal(513, 2, ia.address, i, ethers.utils.id(signers[1].address));
      const cls = await roa.getFRClaimsOfDeal(ia.address, i);
      console.log('FR claims of Deal', i, 'are:', cls, '\n');
    }

    // ==== Compute FR Deals ====

    await increaseTime(86400 * 1);

    for (let i=1; i<=4; i++) {
      await gk.computeFirstRefusal(ia.address, i);
    }

    const dealsList = (await ia.getSeqList()).map(v => Number(v));
    console.log('dealsList:', dealsList, '\n');

    console.log('IA is established ?', await ia.established(), '\n');

    // ==== Vote for IA ====

    await increaseTime(86400 * 1);

    const doc = BigInt(ia.address);

    await gk.connect(signers[5]).proposeDocOfGM(doc, 1, 1);

    const gmmList = (await gmm.getSeqList()).map(v => Number(v));
    console.log('obtained GMM List:', gmmList, "\n");

    let seqOfMotion = gmmList[gmmList.length - 1];
    console.log('motion', seqOfMotion, 'is proposed ?', await gmm.isProposed(seqOfMotion), '\n');

    await increaseTime(86400);

    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_3 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 3), '\n');

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    console.log('User_4 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 4), '\n');

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    console.log('Motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');

    // ---- Exec IA ----

    const payOffDeal = async (seqOfDeal) => {

      const centPrice = await gk.getCentPrice();
      const deal = await ia.getDeal(seqOfDeal);
      const paid = deal[1][2];
      const value = 300n * BigInt(paid) / 10000n * BigInt(centPrice) + 500n;
      console.log('centPrice (GWei):', ethers.utils.formatUnits(centPrice.toString(), 9), 'paid', ethers.utils.formatUnits(paid.toString(), 4),  'value:', value, '\n');

      const buyer = Number(deal[1][0]);
  
      await gk.connect(signers[buyer - 1]).payOffApprovedDeal(ia.address, seqOfDeal, {value: value});
      console.log('seqOfDeal', seqOfDeal, 'was paid out \n');
    }

    for (let i=5; i<=dealsList.length; i++) 
        await payOffDeal(i);

    await printShares(ros);
    await printMembers(rom);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
