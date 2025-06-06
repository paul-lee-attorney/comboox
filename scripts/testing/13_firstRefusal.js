// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to execute First Refusal right specified in SHA.

// First refusal rights are a contractual provision that grants the right holder
// (typically an existing shareholder or investor) the priority to purchase equity
// being offered for sale by another shareholder before it is sold to an external 
// buyer. Under these rights, the selling shareholder must first offer the equity 
// to the right holder on the same terms and conditions as those agreed upon with 
// the potential buyer. The right holder can then choose to accept the offer and 
// purchase the equity, ensuring they have the opportunity to maintain or increase 
// their ownership stake in the company. First refusal rights are designed to 
// protect existing shareholders by giving them the ability to prevent dilution 
// of their ownership or control by external parties.

// The scenario for testing in this section are as follows:
// 1. User_5 creates a Draft of Investment Agreement (the "Draft IA"), with four 
//    External Transfer deals that transfer all its equity shares to User_6 at the
//    price of $3.00 per share;
// 2. After User_5 and User_6 signed the Draft, User_1 and User_2 executes First
//    Refusal right against each of the deals said above. 
// 3. After the expiration of the Frist Refusal period predefined by the Voting Rule
//    concerned, any Member may call the API of gk.computeFirstRefusal() to calculate
//    the First Refusal claims for each of the deals concenered. Then, the original 
//    deals will be automatically terminated and new deals with the claiming Member
//    as buyer will be added with the same price and other terms. 
// 4. After obtaining the voting approval from the General Meeting of Members, User_1
//    and User_2 close the deals by calling gk.payOffApprovedDeal(). 
// 5. Some important points are deserved attention that:
//    (1) First Refusal right does not need acceptance of the original seller;
//    (2) In case more than one rightholder claim to purchase the same deal, the 
//        target share will be allocated to the claimers as per their voting 
//        powers collectively owned through equity shares.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.1 function execFirstRefusal(uint256 seqOfRule, uint256 seqOfRightholder, address ia,
//     uint256 seqOfDeal, bytes32 sigHash) external;
// 1.2 function computeFirstRefusal(address ia, uint256 seqOfDeal) external;

// Events verified in this section:
// 1. Register of Agreement
// 1.1 event ClaimFirstRefusal(address indexed ia, uint256 indexed seqOfDeal, uint256 indexed caller);

// 2. Investment Agreement
// 2.1 event TerminateDeal(uint256 indexed seq);
// 2.2 event RegDeal(uint indexed seqOfDeal);

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROA, getGMM, getROS, getROM, getRC, } = require("./boox");
const { readContract } = require("../readTool"); 
const { increaseTime, Bytes32Zero, now, longDataParser, } = require("./utils");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { getLatestShare, printShares } = require("./ros");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");
const { depositOfUsers } = require("./gk");
const { transferCBP, addEthToUser } = require("./saveTool");

async function main() {

    console.log('\n********************************');
    console.log('**     13. First Refusal      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    
    // ==== Create Investment Agreement ====

    let tx = await gk.connect(signers[5]).createIA(1);

    let Addr = await royaltyTest(rc.address, signers[5].address, gk.address, tx, 58n, "gk.createIA().");

    transferCBP("5", "8", 58n);

    let ia = await readContract("InvestmentAgreement", Addr);

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    await ia.connect(signers[5]).setRoleAdmin(ATTORNEYS, signers[0].address);

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const createDeal = async (headOfDeal, amt) => {
      await ia.addDeal(codifyHeadOfDeal(headOfDeal), 6, 6, amt * 10 ** 4, amt * 10 ** 4, 100);
    }

    let headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 10,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    };

    await createDeal(headOfDeal, 10000);    

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 2,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 13,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    };
    
    await createDeal(headOfDeal, 20000);

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 3,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 14,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    };
    
    await createDeal(headOfDeal, 9000);

    headOfDeal = {
      typeOfDeal: 2,
      seqOfDeal: 4,
      preSeq: 0,
      classOfShare: 1,
      seqOfShare: 15,
      seller: 5,
      priceOfPaid: 3,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    };
    
    await createDeal(headOfDeal, 95000);

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);
    await ia.addBlank(true, false, 1, 5);
    await ia.addBlank(true, true, 1, 6);

    // ---- Circulate IA ----

    await ia.connect(signers[5]).finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    tx = await gk.connect(signers[5]).circulateIA(ia.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 36n, "gk.circulateIA().");

    transferCBP("5", "8", 36n);

    expect(await ia.circulated()).to.equal(true);

    // ---- Sign IA ----

    tx = await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("5", "8", 36n);

    tx = await gk.connect(signers[6]).signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[6].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("6", "8", 36n);

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Exec First Refusal ====

    await increaseTime(86400 * 1);

    for (let i=1; i<=4; i++){
      tx = await gk.execFirstRefusal(513, 1, ia.address, i, ethers.utils.id(signers[0].address));

      await royaltyTest(rc.address, signers[0].address, gk.address, tx, 88n, "gk.execFirstRefusal().");

      transferCBP("1", "8", 88n);

      await expect(tx).to.emit(roa, "ClaimFirstRefusal").withArgs(ia.address, i, 1);
      await expect(tx).to.emit(ia, "TerminateDeal").withArgs(BigNumber.from(i));

      tx = await gk.connect(signers[1]).execFirstRefusal(513, 2, ia.address, i, ethers.utils.id(signers[1].address));

      await royaltyTest(rc.address, signers[1].address, gk.address, tx, 88n, "gk.execFirstRefusal().");

      transferCBP("2", "8", 88n);

      const cls = (await roa.getFRClaimsOfDeal(ia.address, i)).map(v => ({seqOfDeal: v[0], claimer: v[1]}));
      expect(cls[0]).to.deep.equal({seqOfDeal:i, claimer:1});
      expect(cls[1]).to.deep.equal({seqOfDeal:i, claimer:2});

      console.log(" \u2714 Passed Result Verify Test for gk.execFirstRefusal(). \n");
    }

    // ==== Compute FR Deals ====

    await increaseTime(86400 * 1);

    for (let i=1; i<=4; i++) {
      await expect(gk.connect(signers[6]).computeFirstRefusal(ia.address, i)).to.be.revertedWith("SHAKeeper.computeFR: not member");
      console.log(" \u2714 Passed Access Control Test for gk.computeFirstRefusal(). \n");

      tx = await gk.computeFirstRefusal(ia.address, i);

      await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.computeFirstRefusal().");

      transferCBP("1", "8", 18n);

      await expect(tx).to.emit(ia, "RegDeal")
      console.log(" \u2714 Passed Event Test for ia.RegDeal(). \n");

      let deal = parseDeal(await ia.getDeal(3+2*i));
      expect(deal.body.buyer).to.equal(2);
      
      deal = parseDeal(await ia.getDeal(4+2*i));
      expect(deal.body.buyer).to.equal(1);

      console.log(" \u2714 Passed Result Verify Test for gk.computeFirstRefusal(). \n");
    }

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Establishment Test for FirstRefusal. \n");
    
    // ==== Vote for IA ====

    await increaseTime(86400 * 1);

    const doc = BigInt(ia.address);

    tx = await gk.connect(signers[5]).proposeDocOfGM(doc, 1, 1);

    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 116n, "gk.acceptAlongDeal().");

    transferCBP("5", "8", 116n);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400);

    tx = await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 72n, "gk.castVoteOfGM().");

    transferCBP("3", "8", 72n);

    tx = await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.address, signers[4].address, gk.address, tx, 72n, "gk.castVoteOfGM().");

    transferCBP("4", "8", 72n);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM() & gk.voteAccountingOfGM(). \n");

    // ---- Exec IA ----

    const centPrice = await gk.getCentPrice();

    const payOffDeal = async (seqOfDeal) => {

      const deal = await ia.getDeal(seqOfDeal);
      console.log("deal: ", parseDeal(deal), "\n");
      
      const paid = deal[1][2];
      const value = 300n * BigInt(paid) / 10000n * BigInt(centPrice);

      const seller = Number(deal[0][5]);
      const buyer = Number(deal[1][0]);
  
      await gk.connect(signers[buyer - 1]).payOffApprovedDeal(ia.address, seqOfDeal, {value: value + 100n});

      addEthToUser(value, seller.toString());
      addEthToUser(100n, buyer.toString());

      transferCBP((buyer).toString(), "8", 58n);

      const share = await getLatestShare(ros);
      
      expect(share.head.shareholder).to.equal(buyer);
      expect(share.body.paid).to.equal(longDataParser(ethers.utils.formatUnits(paid.toString(), 4)));

      console.log(" \u2714 Passed Result Verify Test for First Refusal of Share", share.head.seqOfShare, "\n");
    }

    for (let i=12; i>=5; i--)
        await payOffDeal(i);
    
    console.log(" \u2714 Passed All Tests for First Refusal. \n");

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);
    await depositOfUsers(rc, gk);
  }

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
