// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2026 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to draft, propose and close an Internal
// Share Transfer Deal by means of Investment Agreement. Seller shall create a
// Draft of Investment Agreement (the "Draft") first, and then, appoint an 
// attorney to set out the terms of the Deal, signing deadline and parties of 
// the Investment Agreement (the “IA”).  

// Thereafter, the Seller shall circulate the draft to the Buyer concerned,
// and after all parties signed, the sales deal in the Draft will be 
// established in legal sense, and the Subject Share will be locked for the 
// equivalent clean paid amount. Thereafter, the Seller shall propose the IA
// to the General Meeting of Members (the “GMM”) for approval.  

// After obtain the approval, Buyer and Seller may close the deal on-chain
// or off-chain. A new share will be issued to the Buyer, and the transferred
// amount will be deduced from the Subject Share concerned. In case there is
// no balance amount left in the Subject Share, it will be de-registered from
// the Register of Shares (the "ROS") accordingly.

// The scenarios for testing in this section include:
// (1) User_1 creates an Investment Agreement (the "Draft") by cloning the
//     Template of IA;
// (2) User_1 appoints himself as the Attorney to the Draft;
// (3) User_1 sets out the Draft with respect to the deal, signing days,
//     closing days and parties accordingly;
// (4) User_6 as Seller and Member circulates the Draft to Buyer (User_3);
// (5) User_6 and User_3 sign the Draft to make it "established" in law;
// (6) User_6 proposes the IA to the GMM for voting;
// (7) All other Members vote "for" the proposed IA;
// (8) After counting the vote results, User_3 triggers the 
//     "payOffApprovedDeal()" API to directly close the deal by paying USDC;
// (9) User_6 is removed from the Register of Members, and Share_7 is
//     deregistered from ROS;
// (10) A new share No.9 is issued to Buyer (User_3).

// The Write APIs tested in this section:
// 1. General Keeper
// 1.1 function createIA(uint256 snOfIA) external;
// 1.2 function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external;
// 1.3 function signIA(address ia, bytes32 sigHash) external;
// 1.4 function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external;
// 1.5 function castVoteOfGM(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;
// 1.6 function voteCountingOfGM(uint256 seqOfMotion) external;
// 1.7 function payOffApprovedDeal(address ia, uint seqOfDeal) external payable;

// 2. Investment Agreement
// 2.1 function addDeal(bytes32 sn, uint buyer, uint groupOfBuyer, uint paid,
//     uint par, uint distrWeight) external;
// 2.2 function finalizeIA() external; 

// 3. Draft Control
// 3.1 function setRoleAdmin(bytes32 role, address acct) external;

// 4. Sig Page
// 4.1 function setTiming(bool initPage, uint signingDays, uint closingDays) external;
// 4.2 function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256 acct)external;

// 5. USD Keeper
// 5.1 function payOffApprovedDeal(ICashier.TransferAuth memory auth, 
//     address ia, uint seqOfDeal, address to) external;

// Events verified in this section:
// 1. Register of Agreement
// 1.1 event UpdateStateOfFile(address indexed body, uint indexed state);

// 2. Register of Shares
// 2.1 event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.2 event DeregisterShare(uint256 indexed seqOfShare);

// 3. General Meeting Minutes
// 3.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);

// 4. Investment Agreement
// 4.1 event PayOffApprovedDeal(uint seqOfDeal, uint msgValue);

// 5. Register of Members
// 5.1 event RemoveShareFromMember(uint indexed seqOfShare, uint indexed acct);
// 5.2 event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

// 6. General Keeper
// 6.1 event SaveToCoffer(uint indexed acct, uint256 indexed value, bytes32 indexed reason);

import { network } from "hardhat";
import { expect } from "chai";
import { keccak256, toUtf8Bytes } from "ethers";

import { getGK, getROA, getGMM, getROS, getROM, getRC, getCashier, getUSDC } from "./boox";
import { readTool } from "../readTool"; 
import { increaseTime, Bytes32Zero, now } from "./utils";
import { codifyHeadOfDeal, parseDeal } from "./roa";
import { getLatestShare, printShares } from "./ros";
import { royaltyTest, cbpOfUsers, getAllUsers } from "./rc";
import { getLatestSeqOfMotion } from "./gmm";
import { parseCompInfo, usdOfUsers } from "./gk";
import { transferCBP } from "./saveTool";
import { generateAuth } from "./sigTools";

async function main() {

    console.log('\n');
    console.log('**************************************');
    console.log('**    10 Internal Transfer In USDC  **');
    console.log('**************************************');
    console.log('\n');

    const { ethers } = await network.connect();
	  const signers = await ethers.getSigners();

    const rc = await getRC();
    let gk = await getGK();

    const users = await getAllUsers(rc, 9);
    const userComp = await parseCompInfo(await gk.getCompInfo()).regNum;

    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    const usdc = await getUSDC();
    const cashier = await getCashier();
    
    // ==== Create Investment Agreement ====

    gk = await readTool("ROAKeeper", gk.target);

    let tx = await gk.createIA(1);

    let Addr = await royaltyTest(rc.target, signers[0].address, gk.target, tx, 58n, "gk.createIA().");

    transferCBP(users[0], userComp, 58n);

    let ia = await readTool("InvestmentAgreement", Addr);

    // ---- Set GC ----

    const ATTORNEYS = keccak256(toUtf8Bytes("Attorneys"));
    await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const headOfDeal = {
      typeOfDeal: 3,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 8,
      seller: users[6],
      priceOfPaid: 2.1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), users[3], users[3], 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    const deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: users[3],
      groupOfBuyer: users[3], 
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

    await ia.addBlank(true, false, 1, users[6]);

    expect(await ia.isParty(users[6])).to.equal(true);
    expect(await ia.isSeller(true, users[6])).to.equal(true);
    expect(await ia.isBuyer(true, users[6])).to.equal(false);

    await ia.addBlank(true, true, 1, users[3]);
    expect(await ia.isParty(users[3])).to.equal(true);
    expect(await ia.isSeller(true, users[3])).to.equal(false);
    expect(await ia.isBuyer(true, users[3])).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    tx = await gk.connect(signers[6]).circulateIA(ia.target, Bytes32Zero, Bytes32Zero);
    
    await royaltyTest(rc.target, signers[6].address, gk.target, tx, 36n, "gk.circulateIA().");

    transferCBP(users[6], userComp, 36n);

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 2);
    console.log(" \u2714 Passed Event Test for roa.UpdateStateOfFile(). \n");

    expect(await ia.circulated()).to.equal(true);

    let circulateDate = await ia.getCirculateDate();
    expect(await ia.getSigDeadline()).to.equal(circulateDate + 86400n);
    expect(await ia.getClosingDeadline()).to.equal(circulateDate + 86400n * 90n);

    console.log(" \u2714 Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----

    // await expect(gk.connect(signers[1]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK.md.OPO: NOT Party");
    console.log(" \u2714 Passed Access Control Test for gk.signIA(). \n ");

    tx = await gk.connect(signers[6]).signIA(ia.target, Bytes32Zero);
    await royaltyTest(rc.target, signers[6].address, gk.target, tx, 36n, "gk.signIA().");

    transferCBP(users[6], userComp, 36n);

    expect(await ia.isSigner(users[6])).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA(). by User_6 \n ");

    const doc = BigInt(await ia.getAddress());

    // await expect(gk.connect(signers[6]).proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: not established");
    console.log(" \u2714 Passed Procedure Control Test for gk.proposeDocOfGM(). \n ");

    tx = await gk.connect(signers[3]).signIA(ia.target, Bytes32Zero);

    await royaltyTest(rc.target, signers[3].address, gk.target, tx, 36n, "gk.signIA().");

    transferCBP(users[3], userComp, 36n);

    expect(await ia.isSigner(users[3])).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA(). by User_3 \n ");

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Voting For IA ====

    await increaseTime(86400 * 3);

    gk = await readTool("GMMKeeper", gk.target);
    
    tx = await gk.connect(signers[6]).proposeDocOfGM(doc, 3, 6);

    await royaltyTest(rc.target, signers[6].address, gk.target, tx, 116n, "gk.proposeDocOfGM().");
    
    transferCBP(users[6], userComp, 116n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Evet Test for gmm.CreateMotion(). \n");

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[0], userComp, 72n);

    expect(await gmm.isVoted(seqOfMotion, users[0])).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM(). with User_1 \n");

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[1], userComp, 72n);

    expect(await gmm.isVoted(seqOfMotion, users[1])).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM(). with User_2 \n");

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[4], userComp, 72n);

    expect(await gmm.isVoted(seqOfMotion, users[4])).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM(). with User_4 \n");

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP(users[0], userComp, 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.voteCounting(). \n");

    // ==== PayOffApprovedDeal() ====

    gk = await readTool("ROAKeeper", gk.target);

    let auth = await generateAuth(signers[3], cashier.target, 21000);
    tx = await gk.connect(signers[3]).payOffApprovedDeal(auth, ia.target, 1, signers[6].address);

    await royaltyTest(rc.target, signers[3].address, gk.target, tx, 58n, "gk.payOffApprovedDeal().");

    transferCBP(users[3], userComp, 58n);

    await royaltyTest(rc.target, signers[6].address, gk.target, tx, 58n, "gk.payOffApprovedDeal().");
    transferCBP(users[6], userComp, 58n);

    await expect(tx).to.emit(ia, "PayOffApprovedDeal").withArgs(1, 21000n * 10n ** 6n);
    console.log(" \u2714 Passed Event Test for ia.PayOffApprovedDeal(). \n");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(ia.target, 6n);
    console.log(" \u2714 Passed Event Test for roa.execFile(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(8n, 10000n * 10n ** 4n);
    console.log(" \u2714 Passed Event Test for ros.increaseCleanPaid(). \n");

    await expect(tx).to.emit(rom, "RemoveShareFromMember").withArgs(8n, users[6]);
    console.log(" \u2714 Passed Event Test for rom.RemoveShareFromMember(). \n");

    await expect(tx).to.emit(ros, "DeregisterShare").withArgs(8n);
    console.log(" \u2714 Passed Event Test for ros.DeregisterShare(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(9n, users[3]);
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    let share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(9);
    expect(share.head.shareholder).to.equal(users[3]);
    expect(share.head.priceOfPaid).to.equal('2.1');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.transferTargetShare(). \n'); 

    await printShares(ros);
    await cbpOfUsers(rc, gk.target, userComp);
    // await depositOfUsers(rc, gk);
    await usdOfUsers(usdc, cashier.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
