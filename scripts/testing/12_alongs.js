// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
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

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROA, getGMM, getROS, getRC, getCashier, } = require("./boox");
const { readContract } = require("../readTool"); 
const { increaseTime, Bytes32Zero, now, } = require("./utils");
const { codifyHeadOfDeal, parseDeal, getDealValue } = require("./roa");
const { printShares } = require("./ros");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");
const { depositOfUsers } = require("./gk");
const { transferCBP } = require("./saveTool");
const { generateAuth } = require("./sigTools");

async function main() {


    console.log('\n');
    console.log('************************************');
    console.log('**    12 Drag/Tag Alongs in USDC  **');
    console.log('************************************');
    console.log('\n');


	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    // const usdc = await getUSDC();
    const cashier = await getCashier();
    // const usdROAKeeper = await getUsdROAKeeper();
    // const usdKeeper = await getUsdKeeper();

    // ==== Create Investment Agreement ====

    let tx = await gk.createIA(1);

    let Addr = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.createIA().");

    transferCBP("1", "8", 58n);

    let ia = await readContract("InvestmentAgreement", Addr);

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const headOfDeal = {
      typeOfDeal: 3,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 1,
      seqOfShare: 1,
      seller: 1,
      priceOfPaid: 2.8,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 5, 5, 95000 * 10 ** 4, 95000 * 10 ** 4, 100);

    let deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 5,
      groupOfBuyer: 5, 
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

    await ia.addBlank(true, false, 1, 1);
    await ia.addBlank(true, true, 1, 5);

    // ---- Circulate IA ----

    await ia.finalizeIA();
    tx = await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.circulateIA().");

    transferCBP("1", "8", 36n);

    expect(await ia.circulated()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----

    tx = await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("5", "8", 36n);

    tx = await gk.signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("1", "8", 36n);

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA() & ia.established(). \n");    

    // ==== Exec TagAlong ====

    await increaseTime(86400 * 2);

    tx = await gk.connect(signers[3]).execTagAlong(ia.address, 1, 3, 20000 * 10 ** 4, 20000 * 10 ** 4, ethers.utils.id(signers[3].address));

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 88n, "gk.execTagAlong().");

    transferCBP("3", "8", 88n);

    await expect(tx).to.emit(roa, "ExecAlongRight");
    console.log(" \u2714 Passed Event Test for roa.ExecAlongRight(). \n");

    tx = await gk.execDragAlong(ia.address, 1, 4, 9000 * 10 ** 4, 9000 * 10 ** 4, ethers.utils.id(signers[0].address));

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 88n, "gk.execDragAlong().");

    transferCBP("1", "8", 88n);

    await expect(tx).to.emit(roa, "ExecAlongRight");
    console.log(" \u2714 Passed Event Test for roa.ExecAlongRight(). \n");

    // ==== Accept Alongs ====
    await increaseTime(86400);

    await expect(gk.connect(signers[1]).acceptAlongDeal(ia.address, 1, ethers.utils.id(signers[5].address))).to.be.revertedWith("SHAK.AAD: not buyer");
    console.log(" \u2714 Passed Access Control Test for gk.acceptAlongDeal(). \n");

    const doc = BigInt(ia.address);

    await expect(gk.proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: Claims outstanding");
    console.log(" \u2714 Passed Procedure Control Test for gk.proposeDocOfGM(). ClaimsOutStandingBlock \n");

    tx = await gk.connect(signers[5]).acceptAlongDeal(ia.address, 1, ethers.utils.id(signers[5].address));

    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 36n, "gk.acceptAlongDeal().");

    transferCBP("5", "8", 36n);

    await expect(tx).to.emit(ia, "RegDeal").withArgs(2);
    await expect(tx).to.emit(ia, "RegDeal").withArgs(3);
    console.log(" \u2714 Passed Event Test for ia.RegDeal(). \n ");  
    
    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(BigNumber.from(3), BigNumber.from(20000 * 10 ** 4));
    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(BigNumber.from(4), BigNumber.from(9000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n ");
    
    // ==== Vote for IA ====

    tx = await gk.proposeDocOfGM(doc, 1, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");

    transferCBP("1", "8", 116n);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400);

    tx = await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 72n, "gk.castVoteOfGM().");

    transferCBP("2", "8", 72n);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

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

      auth = await generateAuth(signers[5], cashier.address, value);
      tx = await gk.connect(signers[5]).payOffApprovedDeal(auth, ia.address, seqOfDeal, signers[numOfSigner].address);

      transferCBP("5", "8", 58n);

      if (numOfSigner > 0) {
        transferCBP(numOfSigner.toString(), "8", 18n);
      } else {
        transferCBP("1", "8", 18n);
      }
    }

    // let value = 280n * 95000n * BigInt(centPrice);

    // await expect(gk.connect(signers[5]).payOffApprovedDeal(ia.address, 1)).to.be.revertedWith("ROAK.shareTransfer: Along Deal Open");
    // console.log(" \u2714 Passed Procedural Control Test for gk.shareTransfer(). \n");
     
    await payOffDeal(3, 3);
    await payOffDeal(2, 4);
    await payOffDeal(1, 0);

    console.log(" \u2714 Passed All Tests for Alongs. \n");

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);
    // await depositOfUsers(rc, gk);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
