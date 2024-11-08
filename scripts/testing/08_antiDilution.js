// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const path = require("path");
const fs = require("fs");
const tempsDir = path.join(__dirname, "..", "..", "server", "src", "contracts");

const { readContract } = require("../readTool"); 
const { parseTimestamp, codifyHeadOfDeal, increaseTime, Bytes32Zero, now, parseShare } = require("./utils");

async function main() {

    const fileNameOfTemps = path.join(tempsDir, "contracts-address.json");
    const Temps = JSON.parse(fs.readFileSync(fileNameOfTemps,"utf-8"));

    const fileNameOfBoox = path.join(__dirname, "boox.json");
    const Boox = JSON.parse(fs.readFileSync(fileNameOfBoox));

	  const signers = await hre.ethers.getSigners();

    const gk = await readContract("GeneralKeeper", Boox.GK);
    const roa = await readContract("RegisterOfAgreements", Boox.ROA);
    const gmm = await readContract("MeetingMinutes", Boox.GMM);
    const ros = await readContract("RegisterOfShares", Boox.ROS);
    const rom = await readContract("RegisterOfMembers", Boox.ROM);
    
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
      typeOfDeal: 1,
      seqOfDeal: 0,
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

    const deal = await ia.getDeal(1);
    console.log('created deal:', deal);

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);
    console.log('IA signing days:', await ia.getSigningDays(), 'closing days:', await ia.getClosingDays(), '\n');

    await ia.addBlank(true, false, 1, 1);
    await ia.addBlank(true, true, 1, 5);

    console.log('Parties of IA:', (await ia.getParties()).map(v=>v.toString()), '\n');

    // ---- Circulate IA ----

    await ia.finalizeIA();
    console.log('IA is finalized ?', await ia.isFinalized(), "\n");

    await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);
    console.log('IA is circulated ?', await ia.circulated(), "\n");

    console.log('IA circulated date:', parseTimestamp(await ia.getCirculateDate()));
    console.log('IA sig Deadline:', parseTimestamp(await ia.getSigDeadline()));
    console.log('IA closing Deadline:', parseTimestamp(await ia.getClosingDeadline()), "\n");

    // ---- Exec AntiDilution ----

    await gk.connect(signers[3]).execAntiDilution(ia.address, 1, 3, Bytes32Zero);
    let deals = (await ia.getSeqList()).map(v => Number(v));    
    const adDealOfUser3 = deals[deals.length - 1];
    console.log("adDeal of User_3:", adDealOfUser3, "\n");

    await gk.connect(signers[4]).execAntiDilution(ia.address, 1, 4, Bytes32Zero);
    deals = (await ia.getSeqList()).map(v => Number(v));
    const adDealOfUser4 = deals[deals.length - 1];
    console.log("adDeal of User_4:", adDealOfUser4, "\n");

    // ---- Sign IA ----

    await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);
    console.log('IA is signed by User_5 ?', await ia.isSigner(5), "\n");

    await gk.signIA(ia.address, Bytes32Zero);
    console.log('IA is signed by User_1 ?', await ia.isSigner(1), "\n");

    console.log('IA is established ?', await ia.established(), '\n');

    // ==== Voting For IA ====

    await increaseTime(86400 * 3);
    
    const doc = BigInt(ia.address);

    await gk.proposeDocOfGM(doc, 1, 1);

    const gmmList = (await gmm.getSeqList()).map(v => Number(v));
    console.log('obtained GMM List:', gmmList, "\n");

    let seqOfMotion = gmmList[gmmList.length - 1];
    console.log('motion', seqOfMotion, 'is proposed ?', await gmm.isProposed(seqOfMotion), '\n');

    await increaseTime(86400);

    // await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    // console.log('User_2 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 2), '\n');

    // await gk.connect(signers[3]).entrustDelegaterForGeneralMeeting(seqOfMotion, 4);
    // console.log('User_3 entrusted User', await gmm.getDelegateOf(seqOfMotion, 3), 'as its proxy \n');

    // await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);
    // console.log('User_4 has voted for Motion', seqOfMotion, '?', await gmm.isVoted(seqOfMotion, 4), '\n');

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    console.log('Motion', seqOfMotion, 'is passed ?', await gmm.isPassed(seqOfMotion), '\n');

    // ---- Exec IA ----

    await gk.issueNewShare(ia.address, 1);

    const getSharesOfComp = async () => {
      const shares = (await ros.getSharesList()).map(v => parseShare(v));
      console.log('Shares of the Comp:', shares);
  
      const members = (await rom.membersList()).map(v => v.toString());
      console.log('Members of the Comp:', members);  
    }

    await getSharesOfComp();

    // ---- Take Gift Share ----

    await gk.connect(signers[3]).takeGiftShares(ia.address, adDealOfUser3);
    console.log("User_3 Took AD gift shares")

    await gk.connect(signers[4]).takeGiftShares(ia.address, adDealOfUser4);
    console.log("User_4 Took AD gift shares")
    
    await getSharesOfComp();

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
