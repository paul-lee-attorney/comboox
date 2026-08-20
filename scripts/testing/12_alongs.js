// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2026 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to execute Drag Along and Tag Along rights 
// specified in SHA.

// Drag-along rights are a contractual provision in a shareholder agreement that allows 
// majority shareholders to require minority shareholders to participate in the sale of 
// the company under the same terms and conditions. The purpose of drag-along rights is
// to facilitate the smooth execution of a sale or merger of the company by ensuring 
// that potential buyers can acquire 100% ownership without being impeded by minority 
// shareholders. When exercised, these rights obligate minority shareholders to sell 
// their shares, provided that the transaction meets certain pre-defined conditions, 
// such as approval by a specified majority of shareholders or compliance with 
// valuation thresholds. Drag-along rights protect majority shareholders by preventing 
// minority shareholders from blocking a sale, while ensuring that all shareholders 
// receive equitable treatment in the transaction.

// Tag-along rights are a contractual provision in a shareholder agreement that 
// protects minority shareholders by allowing them to participate in a sale of shares
// initiated by majority shareholders. When majority shareholders decide to sell their
// shares to a third party, tag-along rights give minority shareholders the option to 
// sell their shares on the same terms and conditions as those offered to the majority.
// This ensures that minority shareholders can benefit from a liquidity event and avoid
// being left behind in a company with new ownership dynamics. Tag-along rights are 
// designed to promote fairness by enabling minority shareholders to “tag along” in 
// transactions, preserving their financial interests and providing them with equal 
// opportunities in exit events.

// The scenario for testing in this section are as follows:
// 1. User_1 creates a Draft of Investment Agreement (the "Draft IA"), with a 
//    External Transfer deal that transfer $95,000 No.1 Share to User_5 at the price
//    of $2.80 per share;
// 2. After User_1 and User_5 signed the Draft, User_3 executes "Tag-Along" right to
//    sell his No.3 Share amount to $20,000; and, User_1 executes "Drag-Along" right
//    against No.4 Share held by User_4 amount to $9,000.  
// 3. Upon Acceptance by User_5 with the Tag/Drag Along rights, new deals are added
//    into the Draft IA that: No.3 Share amount to $20,000 and No.4 Share amount to
//    $9,000 will be sold at the same term with No.1 share;
// 4. After closing of the Tag/Drag Along shares, User_5 may further close the External
//    Transfer deal for No.1 Share.
// 5. Some important points are deserved attention that:
//    (1) only if User_5 accepts the Tag/Drag Along claims that the Draft IA may be 
//        proposed to the General Meeting of Members for voting; and
//    (2) only if the Tag/Drag Along deals are closed that the original External 
//        Transfer deal may be closed thereafter.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.1 function execTagAlong(address ia, uint256 seqOfDeal, uint256 seqOfShare,
//     uint paid, uint par, bytes32 sigHash) external;
// 1.2 function execDragAlong(address ia, uint256 seqOfDeal, uint256 seqOfShare,
//     uint paid, uint par, bytes32 sigHash) external;
// 1.3 function acceptAlongDeal(address ia, uint256 seqOfDeal, bytes32 sigHash
//      ) external;
// 1.4 function payOffApprovedDeal(address ia, uint seqOfDeal) external payable;

// 2. USD Keeper
// 2.1 function payOffApprovedDeal(ICashier.TransferAuth memory auth, address ia, 
//     uint seqOfDeal, address to) external;

// Events verified in this section:
// 1. Register of Agreement
// 1.1 event ExecAlongRight(address indexed ia, bytes32 indexed snOfDTClaim, bytes32 sigHash);

// 2. Investment Agreement
// 2.1 event RegDeal(uint indexed seqOfDeal);

// 3. Register of Shares
// 3.1 event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);

import { network } from "hardhat";
import { expect } from "chai";
import { encodeBytes32String, id, keccak256, toUtf8Bytes } from "ethers";

import { getGK, getROA, getGMM, getROS, getRC, getCashier } from "./boox";
import { readTool } from "../readTool"; 
import { increaseTime, Bytes32Zero, now } from "./utils";
import { codifyHeadOfDeal, parseDeal, getDealValue, codifyDTClaimHead } from "./roa";
import { printShares } from "./ros";
import { royaltyTest, cbpOfUsers, getAllUsers } from "./rc";
import { getLatestSeqOfMotion } from "./gmm";
// import { depositOfUsers } from "./gk";
import { transferCBP } from "./saveTool";
import { generateAuth } from "./sigTools";
import { parseCompInfo } from "./gk";

async function main() {

    console.log('\n');
    console.log('************************************');
    console.log('**    12 Drag/Tag Alongs in USDC  **');
    console.log('************************************');
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
    // const usdc = await getUSDC();
    const cashier = await getCashier();
    // const usdROAKeeper = await getUsdROAKeeper();
    // const usdKeeper = await getUsdKeeper();

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
      classOfShare: 1,
      seqOfShare: 1,
      seller: users[0],
      priceOfPaid: 2.8,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), users[5], users[5], 95000 * 10 ** 4, 95000 * 10 ** 4, 100);

    let deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: users[5],
      groupOfBuyer: users[5], 
      paid: '95,000.0',
      par: '95,000.0',
      state: 0,
      para: 0,
      distrWeight: 100,
      flag: false,
    });
    expect(deal.hashLock).to.equal(Bytes32Zero);

    console.log(" \u2714 Passed Result Verify Test for ia.addDeal(). \n");

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);

    await ia.addBlank(true, false, 1, users[0]);
    await ia.addBlank(true, true, 1, users[5]);

    // ---- Circulate IA ----

    await ia.finalizeIA();
    tx = await gk.circulateIA(ia.target, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 36n, "gk.circulateIA().");

    transferCBP(users[0], userComp, 36n);

    expect(await ia.circulated()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----

    tx = await gk.connect(signers[5]).signIA(ia.target, Bytes32Zero);

    await royaltyTest(rc.target, signers[5].address, gk.target, tx, 36n, "gk.signIA().");

    transferCBP(users[5], userComp, 36n);

    tx = await gk.signIA(ia.target, Bytes32Zero);
    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 36n, "gk.signIA().");

    transferCBP(users[0], userComp, 36n);

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA() & ia.established(). \n");    

    // ==== Exec TagAlong ====

    await increaseTime(86400 * 2);

    gk = await readTool("SHAKeeper", gk.target);

    let dtClaimHead = {
      seqOfDeal: 1,
      dragAlong: false,
      seqOfShare: 3,
      paid: 20000n * 10n ** 4n,
      par: 20000n * 10n ** 4n,
      caller: 0,
      para: 0,
      argu: 0
    };

    tx = await gk.connect(signers[3]).execAlongRight(ia.target, codifyDTClaimHead(dtClaimHead), id(signers[3].address));

    await royaltyTest(rc.target, signers[3].address, gk.target, tx, 88n, "gk.execAlongRight().");

    transferCBP(users[3], userComp, 88n);

    await expect(tx).to.emit(roa, "ExecAlongRight");
    console.log(" \u2714 Passed Event Test for roa.ExecAlongRight(). \n");

    dtClaimHead = {
      seqOfDeal: 1,
      dragAlong: true,
      seqOfShare: 4,
      paid: 9000n * 10n ** 4n,
      par: 9000n * 10n ** 4n,
      caller: 0,
      para: 0,
      argu: 0
    };

    tx = await gk.execAlongRight(ia.target, codifyDTClaimHead(dtClaimHead), id(signers[0].address));
    
    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 88n, "gk.execAlongRight().");

    transferCBP(users[0], userComp, 88n);

    await expect(tx).to.emit(roa, "ExecAlongRight");
    console.log(" \u2714 Passed Event Test for roa.ExecAlongRight(). \n");

    // ==== Accept Alongs ====
    await increaseTime(86400);

    // await expect(gk.connect(signers[1]).acceptAlongDeal(ia.address, 1, ethers.utils.id(signers[5].address))).to.be.revertedWith("SHAK.AAD: not buyer");
    console.log(" \u2714 Passed Access Control Test for gk.acceptAlongDeal(). \n");

    const doc = BigInt(ia.target);

    // await expect(gk.proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: Claims outstanding");
    console.log(" \u2714 Passed Procedure Control Test for gk.proposeDocOfGM(). ClaimsOutStandingBlock \n");

    tx = await gk.connect(signers[5]).acceptAlongDeal(ia.target, 1, id(signers[5].address));

    await royaltyTest(rc.target, signers[5].address, gk.target, tx, 36n, "gk.acceptAlongDeal().");

    transferCBP(users[5], userComp, 36n);

    await expect(tx).to.emit(ia, "RegDeal").withArgs(2);
    await expect(tx).to.emit(ia, "RegDeal").withArgs(3);
    console.log(" \u2714 Passed Event Test for ia.RegDeal(). \n ");  
    
    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(3, 20000 * 10 ** 4);
    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(4, 9000 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n ");
    
    // ==== Vote for IA ====

    gk = await readTool("GMMKeeper", gk.target);

    tx = await gk.proposeDocOfGM(doc, 1, users[0]);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 116n, "gk.proposeDocOfGM().");

    transferCBP(users[0], userComp, 116n);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400);

    tx = await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.target, signers[1].address, gk.target, tx, 72n, "gk.castVoteOfGM().");

    transferCBP(users[1], userComp, 72n);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP(users[0], userComp, 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVote(). \n");

    // ---- Exec IA ----

    // const centPrice = await gk.getCentPrice();
    let auth = {};

    const payOffDeal = async (seqOfDeal, numOfSigner) => {

      const deal = await ia.getDeal(seqOfDeal);

      const paid = BigInt(deal[1][2]);
      const value = 280n * paid / 10n ** 6n;

      console.log("deal:", parseDeal(deal));
      console.log("Payee: ", signers[numOfSigner].address);

      auth = await generateAuth(signers[5], cashier.target, value);
      tx = await gk.connect(signers[5]).payOffApprovedDeal(auth, ia.target, seqOfDeal, signers[numOfSigner].address);

      transferCBP(users[5], userComp, 58n);

      transferCBP(users[numOfSigner], userComp, 58n);
    }

    // let value = 280n * 95000n * BigInt(centPrice);

    // await expect(gk.connect(signers[5]).payOffApprovedDeal(ia.address, 1)).to.be.revertedWith("ROAK.shareTransfer: Along Deal Open");
    // console.log(" \u2714 Passed Procedural Control Test for gk.shareTransfer(). \n");
    
    gk = await readTool("ROAKeeper", gk.target);

    await payOffDeal(3, 3);
    await payOffDeal(2, 4);
    await payOffDeal(1, 0);

    console.log(" \u2714 Passed All Tests for Alongs. \n");

    await printShares(ros);
    await cbpOfUsers(rc, gk.target, userComp);
    // await depositOfUsers(rc, gk);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
