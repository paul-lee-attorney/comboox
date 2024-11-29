// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to exercise the Anti-Dilution rights stipulated in SHA. 

// Anti-Dilution rights refer to a contractual mechanism designed to protect investors from 
// the adverse effects of a subsequent issuance of equity at a valuation lower than the 
// original subscription price paid by the investor. These rights enable the investor (the
// right holder) to maintain their economic position in the company by compensating for the
// dilution of their ownership and investment value.

// In practice, Anti-Dilution provisions typically entitle the investor to request the
// transfer of additional equity shares from the operating and controlling Member of the
// company (the obligor) at no additional cost (zero consideration). 

// This adjustment effectively reduces the investor’s average per-share investment cost,
// aligning it with the lower issuance price of the newly issued equity. Anti-dilution
// rights are triggered when the issuance price of new shares falls below a predefined
// threshold set forth in the original subscription agreement.

// The scenario for testing in this section are as follows:
// (1) User_1 creates a Draft of Investment Agreement (the "Draft IA"), with a Capital
//     Increase deal that issue $10,000 equity shares to User_5 at the price of $1.20 per
//     share;
// (2) After User_1 circulates the Draft, User_3 and User_4 execute their "Anti-Dilution"
//     rights as per the Shareholder Agreement (the "SHA"). The threshold price of Class_2
//     shares is set out as $1.50 per share in the SHA;
// (3) As consequences of the execution of Anti-Dilution rights, new deals are added into
//     the Draft IA that: $10,000 and $5,000 shares will be given for free to User_3 and
//     User_4 so as to lower their average investment cost down to $1.20 per share;
// (4) After closing of the Capital Increase deal, User_3 and User_4 take the gift
//     shares by calling the API of gk.takeGiftShares().


// The Write APIs tested in this section include:
// 1. General Keper
// 1.1 function issueNewShare(address ia, uint256 seqOfDeal) external;
// 1.2 function execAntiDilution(address ia, uint256 seqOfDeal, uint256 seqOfShare,
//     bytes32 sigHash) external;
// 1.3 function takeGiftShares(address ia, uint256 seqOfDeal) external;

// Events verified in this section:
// 1. Register of Agreement
// 1.1 event UpdateStateOfFile(address indexed body, uint indexed state);

// 2. Register of Shares
// 2.1 event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par);
// 2.2 event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.3 event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.4 event SubAmountFromShare(uint256 indexed seqOfShare, uint indexed paid, uint indexed par);

// 3. General Meeting Minutes
// 3.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);

// 4. Investment Agreement
// 4.1 event RegDeal(uint indexed seqOfDeal);
// 4.2 event CloseDeal(uint256 indexed seq, string indexed hashKey);

// 5. Register of Members
// 5.1 event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROA, getGMM, getROS, getROM, getRC, } = require("./boox");
const { readContract } = require("../readTool"); 
const { increaseTime, Bytes32Zero, now, } = require("./utils");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { obtainNewShare, getLatestShare, printShares } = require("./ros");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");
const { depositOfUsers } = require("./gk");
const { minusCBPFromUser, addCBPToUser, transferCBP } = require("./saveTool");

async function main() {

    console.log('\n********************************');
    console.log('**     11. Anti-Dilution      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    
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
      typeOfDeal: 1,
      seqOfDeal: 1,
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

    const deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 5,
      groupOfBuyer: 5, 
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

    await ia.addBlank(true, false, 1, 1);

    expect(await ia.isParty(1)).to.equal(true);
    expect(await ia.isSeller(true, 1)).to.equal(true);
    expect(await ia.isBuyer(true, 1)).to.equal(false);

    await ia.addBlank(true, true, 1, 5);

    expect(await ia.isParty(5)).to.equal(true);
    expect(await ia.isSeller(true, 5)).to.equal(false);
    expect(await ia.isBuyer(true, 5)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Circulate IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    await expect(gk.connect(signers[3]).execAntiDilution(ia.address, 1, 3, Bytes32Zero)).to.be.revertedWith("SHAK.execAD: wrong file state");
    console.log(" \u2714 Passed IA State Control Test for gk.execAntiDilution(). \n ");

    tx = await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.circulateIA().");

    transferCBP("1", "8", 36n);

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 2);
    console.log(" \u2714 Passed Event Test for roa.UpdateStateOfFile(). \n");

    expect(await ia.circulated()).to.equal(true);

    let circulateDate = await ia.getCirculateDate();
    expect(await ia.getSigDeadline()).to.equal(circulateDate + 86400);
    expect(await ia.getClosingDeadline()).to.equal(circulateDate + 86400 * 90);

    console.log(" \u2714 Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Exec AntiDilution ----

    await expect(gk.connect(signers[1]).execAntiDilution(ia.address, 1, 3, Bytes32Zero)).to.be.revertedWith("SHAK.execAD: not shareholder");
    console.log(" \u2714 Passed Access Control Test for gk.execAntiDilution(). ShareholderOnly \n ");

    // ---- User_3 ----

    tx = await gk.connect(signers[3]).execAntiDilution(ia.address, 1, 3, Bytes32Zero);
    
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 88n, "gk.execAntiDilution().");    
    
    transferCBP("3", "8", 88n);

    await expect(tx).to.emit(ia, "RegDeal").withArgs(2);
    console.log(" \u2714 Passed Event Test for ia.RegDeal(). \n ");    

    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(BigNumber.from(2), BigNumber.from(10000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n ");    
    
    // ---- User_4 ----

    tx = await gk.connect(signers[4]).execAntiDilution(ia.address, 1, 4, Bytes32Zero);

    await royaltyTest(rc.address, signers[4].address, gk.address, tx, 88n, "gk.execAntiDilution().");
    
    transferCBP("4", "8", 88n);

    await expect(tx).to.emit(ia, "RegDeal").withArgs(3);
    console.log(" \u2714 Passed Event Test for ia.RegDeal(). \n ");    

    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(BigNumber.from(2), BigNumber.from(5000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n ");

    // ---- Sign IA ----

    tx = await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("5", "8", 36n);

    tx = await gk.signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("1", "8", 36n);

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Voting For IA ====

    await increaseTime(86400 * 3);
    
    const doc = BigInt(ia.address);

    await gk.proposeDocOfGM(doc, 1, 1);

    transferCBP("1", "8", 116n);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400*2);

    await gk.voteCountingOfGM(seqOfMotion);

    minusCBPFromUser(88n * 10n ** 13n, "1");
    addCBPToUser(88n * 10n ** 13n, "8");

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.voteCounting(). \n");

    // ---- Exec IA ----

    tx = await gk.issueNewShare(ia.address, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.issueNewShare().");

    minusCBPFromUser(58n * 10n ** 13n, "1");
    addCBPToUser(58n * 10n ** 13n, "8");

    await expect(tx).to.emit(ros, "IssueShare");
    console.log(" \u2714 Passed Evet Test for ros.IssueShare(). \n");

    let share = await obtainNewShare(tx);

    expect(share.head.seqOfShare).to.equal(10);
    expect(share.head.shareholder).to.equal(5);
    expect(share.head.priceOfPaid).to.equal('1.2');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.closeDeal(). \n');
    
    // ---- Take Gift Share ----

    await expect(gk.connect(signers[1]).takeGiftShares(ia.address, 2)).to.be.revertedWith("caller is not buyer");
    console.log(" \u2714 Passed Access Control Test for gk.takeGiftShares(). \n");

    tx = await gk.connect(signers[3]).takeGiftShares(ia.address, 2);
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.takeGiftShares().");

    minusCBPFromUser(58n * 10n ** 13n, "3");
    addCBPToUser(58n * 10n ** 13n, "8");

    await expect(tx).to.emit(ia, "CloseDeal").withArgs(BigNumber.from(2), "0");
    console.log(" \u2714 Passed Event Control Test for ia.CloseDeal(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(2), BigNumber.from(10000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.increaseCleanPaid(). \n");

    await expect(tx).to.emit(ros, "SubAmountFromShare").withArgs(BigNumber.from(2), BigNumber.from(10000 * 10 ** 4), BigNumber.from(10000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.SubAmountFromShare(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(11), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(11);
    expect(share.head.shareholder).to.equal(3);
    expect(share.head.priceOfPaid).to.equal('1.2');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.takeGiftShares(). \n'); 

    tx = await gk.connect(signers[4]).takeGiftShares(ia.address, 3);

    minusCBPFromUser(58n * 10n ** 13n, "4");
    addCBPToUser(58n * 10n ** 13n, "8");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(ia.address, BigNumber.from(6));
    console.log(" \u2714 Passed Event Test for roa.UpdateStateOfFile(). User_3 \n");

    share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(12);
    expect(share.head.shareholder).to.equal(4);
    expect(share.head.priceOfPaid).to.equal('1.2');
    expect(share.body.paid).to.equal('5,000.0');

    console.log(' \u2714 Passed Result Verify Test for gk.takeGiftShares(). User_4 \n'); 

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
