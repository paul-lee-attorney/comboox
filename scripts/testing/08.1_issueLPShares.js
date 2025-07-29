// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to draft, circulate, sign, propose, vote and 
// close a LP Shares issuance Deal by way of an Investment Agreement (the "IA"). 
// It's only the GP can confirm that all the conditions precedents to an IA have
// been fully satisfied, thereafter, the subject Deal can be further Closed. 
// Upon Closing, a new share will be issued to the buyer, who will then be 
// included into the Register of Members to become a Limited Partner. 
// The Owners' Equity and Registered Capital will also be updated by increasing
// the same amount. 

// As with other GMM Motions, only Members can propose a motion to the GMM for 
// voting. And in the case of "off-chain" consideration payment, only if the hash 
// lock has been opened by the correct "key" can the relevant share be issued 
// accordingly.

// The scenario for testing included in this section:
// (1) User_1 as the GP creates a draft Investment Agreement (the "Draft") by 
//     cloning the Template；
// (2) User_1 as the Owner of the Draft appoints itself as the General Counsel to 
//     the Draft, so as to enable itself to have the Attorney role to the Draft;
// (3) User_1, as the Attorney to the Draft, creates a Capital Increase Deal and
//     sets up all the necessary attributes of an Investment Agreement (the “IA”),
//     such as Signing Days, Closing Days and Entity Signature Blanks on the
//     Signing Page;
// (4) User_1 finalizes the Draft to prevent any further change to it;
// (5) User_1 circulates the Draft to Parties to the IA;
// (6) User_2 sign the LPA to indicate its acceptance of the terms concerned;
// (7) User_1 and User_2 sign the IA so as to enable it “established" in law;
// (8) User_1, as GP, submits, votes and approves the IA;
// (9) User_1 as GP confirms all conditions precedent fulfilled and input a Hash
//     Lock encrypted by Keccat-256;
// (10) User_2 pays the subscription consideration off-chain and obtains the "Hash
//      Key" to the Hash Lock installed by User_1;
// (11) User_2 inputs the correct ”Hash Key" to close the Deal and obtains the
//      newly issued Share.
// (12) User_3 pay off directly in USDC to close the Deal_2 and obtains the newly 
//      newly issued Share.

// The Write APIs tested in this sction:
// 1. Fund Keeper
// 1.1 function createIA(uint256 snOfIA) external;
// 1.2 function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external;
// 1.3 function signIA(address ia, bytes32 sigHash) external;
// 1.4 function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint
//     closingDeadline) external;
// 1.5 function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey)
//     external;
// 1.6 function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external;
// 1.7 function castVoteOfGM(uint256 seqOfMotion, uint attitude, bytes32 sigHash)
//     external;
// 1.8 function voteCountingOfGM(uint256 seqOfMotion) external;
// 1.9 function payOffApprovedDeal(
//       ICashier.TransferAuth memory auth, address ia, uint seqOfDeal, address to
//     ) external;

// 2. Investment Agreement
// 2.1 function addDeal(bytes32 sn, uint buyer, uint groupOfBuyer, uint paid,
//     uint par, uint distrWeight) external;
// 2.2 function finalizeIA() external; 

// 3. Draft Control
// 3.1 function setRoleAdmin(bytes32 role, address acct) external;

// 4. Sig Page
// 4.1 function setTiming(bool initPage, uint signingDays, uint closingDays) external;
// 4.2 function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256
//     acct)external;

// Events verified in this section:
// 1. Register of Agreements
// 1.1 event UpdateStateOfFile(address indexed body, uint indexed state);

// 2. Investment Agreement (Draft Control)
// 2.1 event SetRoleAdmin(bytes32 indexed role, address indexed acct);
// 2.2 event PayOffApprovedDeal(uint seqOfDeal, uint msgValue);

// 3. General Meeting Minutes
// 3.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);
// 3.2 event ClearDealCP(uint256 indexed seq, bytes32 indexed hashLock,
//     uint indexed closingDeadline);

// 4. Register of Shares
// 4.1 event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par);

// 5. ROAKeeper
// 5.1 event PayOffCIDeal(uint indexed caller, uint indexed valueOfDeal);

// 6. Register of Members
// 6.1 event CapIncrease(uint indexed votingWeight, uint indexed paid, uint indexed par, uint distrWeight);
// 6.2 event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

const { expect } = require("chai");

const { getROA, getGMM, getROS, getROM, getRC, getCashier, getUSDC, getFK, getSHA} = require("./boox");
const { readContract } = require("../readTool"); 
const { increaseTime, Bytes32Zero, now } = require("./utils");
const { obtainNewShare, printShares } = require("./ros");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");
const { usdOfUsers } = require("./gk");
const { transferCBP } = require("./saveTool");
const { generateAuth } = require("./sigTools");
const { parseDrop } = require("./cashier");

async function main() {

    console.log('\n');
    console.log('****************************');
    console.log('**  08.1 Issue LP Shares  **');
    console.log('****************************');
    console.log('\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getFK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    const sha = await getSHA();

    const roaKeeper = await readContract("ROAKeeper", await gk.getKeeper(6));

    const cashier = await getCashier();
    const usdc = await getUSDC();

    // ==== Create Investment Agreement ====

    await expect(gk.connect(signers[5]).createIA(1)).to.be.revertedWith("not MEMBER");
    console.log(" \u2714 Passed Access Control Test for gk.createIA(). \n");

    let tx = await gk.createIA(1);

    let Addr = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.createIA().");

    transferCBP("1", "8", 58n);

    let ia = await readContract("InvestmentAgreement", Addr);

    expect(await ia.getDK()).to.equal(roaKeeper.address);
    console.log(" \u2714 Passed Result Verify Test for ia.initKeepers(). \n");
    
    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 1);
    console.log(" \u2714 Passed Event Test for roa.UpdateStateOfFile(). \n");

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    
    tx = await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    await expect(tx).to.emit(ia, "SetRoleAdmin").withArgs(ATTORNEYS, signers[0].address);
    console.log(" \u2714 Passed Event Test for ia.SetRoleAdmin(). \n");

    expect(await ia.getRoleAdmin(ATTORNEYS)).to.equal(signers[0].address);
    console.log(" \u2714 Passed Result Verify Test for ia.setRoleAdmin(). \n");

    // ---- Create Deal ----
    let closingDeadline = (await now()) + 86400 * 90;

    let headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 2, 2, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    let deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 2,
      groupOfBuyer: 2, 
      paid: '10,000.0',
      par: '10,000.0',
      state: 0,
      para: 0,
      distrWeight: 100,
      flag: false,
    });
    expect(deal.hashLock).to.equal(Bytes32Zero);

    console.log(" \u2714 Passed Result Verify Test for ia.addDeal(). \n");

    // ---- Add Deal No.2 ----

    headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 2,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 3, 3, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    deal = parseDeal(await ia.getDeal(2));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 3,
      groupOfBuyer: 3, 
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

    await ia.addBlank(true, true, 1, 2);
    expect(await ia.isParty(2)).to.equal(true);
    expect(await ia.isSeller(true, 2)).to.equal(false);
    expect(await ia.isBuyer(true, 2)).to.equal(true);

    await ia.addBlank(true, true, 1, 3);
    expect(await ia.isParty(3)).to.equal(true);
    expect(await ia.isSeller(true, 3)).to.equal(false);
    expect(await ia.isBuyer(true, 3)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

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

    // ---- Sign IA ----

    await expect(gk.connect(signers[4]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK.md.OPO: NOT Party");
    console.log(" \u2714 Passed Access Control Test for gk.signIA(). \n ");

    tx = await gk.signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("1", "8", 36n);

    let doc = BigInt(ia.address);

    // ---- Accept LPA By User_2 ----

    await expect(gk.connect(signers[1]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK: buyer not signer of SHA");
    console.log(" \u2714 Passed LPA Acceptance Test for gk.signIA(). \n ");

    tx = await gk.connect(signers[1]).acceptSHA(Bytes32Zero);
    transferCBP("2", "8", 36n);

    let res = await sha.isSigner(2);

    expect(res).to.equal(true);
    console.log(" \u2714 Passed Result Test for GK.acceptSHA(). User_2 \n");

    // ---- Sign IA By User_2 ----

    tx = await gk.connect(signers[1]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("2", "8", 36n);

    // ---- Accept LPA By User_3 ----

    await expect(gk.connect(signers[3]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK: buyer not signer of SHA");
    console.log(" \u2714 Passed LPA Acceptance Test for gk.signIA(). \n ");

    tx = await gk.connect(signers[3]).acceptSHA(Bytes32Zero);
    transferCBP("3", "8", 36n);

    res = await sha.isSigner(3);

    expect(res).to.equal(true);
    console.log(" \u2714 Passed Result Test for GK.acceptSHA(). User_3 \n");

    // ---- Sign IA User_3 ----

    tx = await gk.connect(signers[3]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("3", "8", 36n);

    // ==== Voting For IA ====

    await increaseTime(86400 * 1);
    
    tx = await gk.proposeDocOfGM(doc, 1, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");

    transferCBP("1", "8", 116n);
    
    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    transferCBP("1", "8", 88n);

    let closingDL = (await now()) + 86400;

    await expect(gk.connect(signers[1]).pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL)).to.be.revertedWith("ROAK.PTC: not director or controllor");
    console.log(" \u2714 Passed Access Control Test for gk.pushToCoffer(). \n");

    tx = await gk.pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.pushToCoffer().");

    transferCBP("1", "8", 58n);

    await expect(tx).to.emit(ia, "ClearDealCP").withArgs(1, ethers.utils.id('Today is Friday.'), closingDL);
    console.log(" \u2714 Passed Evet Test for ia.ClearDealCP(). \n");
    
    deal = parseDeal(await ia.getDeal(1));
    expect(deal.body.state).to.equal(2); // Cleared
    console.log(" \u2714 Passed Result Verify Test for ia.ClearDealCP(). \n");
    
    // ---- Close Deal ----

    await expect(gk.closeDeal(ia.address, 1, 'Today is Thirthday.')).to.be.revertedWith("IA.closeDeal: hashKey NOT correct");
    console.log(" \u2714 Passed Access Control Test for ia.closeDeal(). \n");

    // ==== Accept LPA ====    
    
    tx = await gk.closeDeal(ia.address, 1, 'Today is Friday.');

    await expect(tx).to.emit(ros, "IssueShare");
    console.log(" \u2714 Passed Evet Test for ros.IssueShare(). \n");

    let share = await obtainNewShare(tx);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('1.0');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.closeDeal(). \n');

    // ---- Deal No.2 ----
    
    let auth = await generateAuth(signers[3], cashier.address, 10000);
    tx = await gk.connect(signers[3]).payOffApprovedDeal(auth, ia.address, 2, cashier.address);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.payOffApprovedDeal().");

    transferCBP("3", "8", 58n);

    await expect(tx).to.emit(ia, "PayOffApprovedDeal").withArgs(2, 10000n * 10n ** 6n);
    console.log(" \u2714 Passed Event Test for ia.PayOffApprovedDeal(). \n");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(ia.address, 6);
    console.log(" \u2714 Passed Event Test for roa.execFile(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(3, 3);
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    await expect(tx).to.emit(rom, "CapIncrease").withArgs(100, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);
    console.log(" \u2714 Passed Event Test for rom.CapIncrease(). \n");

    await expect(tx).to.emit(ros, "IssueShare");
    console.log(" \u2714 Passed Evet Test for ros.IssueShare(). \n");

    share = await obtainNewShare(tx);

    expect(share.head.shareholder).to.equal(3);
    expect(share.head.priceOfPaid).to.equal('1.0');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.closeDeal(). \n');

    // ==== Class 3 ====

    // ==== Create Investment Agreement ====

    tx = await gk.createIA(1);

    Addr = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.createIA().");
    transferCBP("1", "8", 58n);

    ia = await readContract("InvestmentAgreement", Addr);
    
    // ---- Set GC ----
    
    tx = await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    // ---- Create Deal ----
    closingDeadline = (await now()) + 86400 * 90;

    headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 3,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 2, 2, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 2,
      groupOfBuyer: 2, 
      paid: '10,000.0',
      par: '10,000.0',
      state: 0,
      para: 0,
      distrWeight: 100,
      flag: false,
    });
    expect(deal.hashLock).to.equal(Bytes32Zero);

    console.log(" \u2714 Passed Result Verify Test for ia.addDeal(). \n");

    // ---- Add Deal No.2 ----

    headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 2,
      preSeq: 0,
      classOfShare: 3,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 3, 3, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    deal = parseDeal(await ia.getDeal(2));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 3,
      groupOfBuyer: 3, 
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

    await ia.addBlank(true, false, 1, 1);
    await ia.addBlank(true, true, 1, 2);
    await ia.addBlank(true, true, 1, 3);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();

    tx = await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.circulateIA().");
    transferCBP("1", "8", 36n);

    // ---- Sign IA ----
    tx = await gk.signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("1", "8", 36n);

    doc = BigInt(ia.address);

    tx = await gk.connect(signers[1]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("2", "8", 36n);

    tx = await gk.connect(signers[3]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("3", "8", 36n);

    // ==== Voting For IA ====

    await increaseTime(86400 * 1);
    
    tx = await gk.proposeDocOfGM(doc, 1, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");

    transferCBP("1", "8", 116n);
 
    seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    transferCBP("1", "8", 88n);

    closingDL = (await now()) + 86400;

    tx = await gk.pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.pushToCoffer().");

    transferCBP("1", "8", 58n);
        
    // ---- Close Deal ----
    
    tx = await gk.closeDeal(ia.address, 1, 'Today is Friday.');

    // ---- Deal No.2 ----
    
    auth = await generateAuth(signers[3], cashier.address, 10000);
    tx = await gk.connect(signers[3]).payOffApprovedDeal(auth, ia.address, 2, cashier.address);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.payOffApprovedDeal().");

    transferCBP("3", "8", 58n);

    // ==== Class 4 ====

    // ==== Create Investment Agreement ====

    tx = await gk.createIA(1);

    Addr = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.createIA().");
    transferCBP("1", "8", 58n);

    ia = await readContract("InvestmentAgreement", Addr);
    
    // ---- Set GC ----
    
    tx = await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    // ---- Create Deal ----
    closingDeadline = (await now()) + 86400 * 90;

    headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 4,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 2, 2, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    // ---- Add Deal No.2 ----

    headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 2,
      preSeq: 0,
      classOfShare: 4,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 3, 3, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);

    await ia.addBlank(true, false, 1, 1);
    await ia.addBlank(true, true, 1, 2);
    await ia.addBlank(true, true, 1, 3);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();

    tx = await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.circulateIA().");
    transferCBP("1", "8", 36n);

    circulateDate = await ia.getCirculateDate();
    console.log(" \u2714 Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----
    tx = await gk.signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("1", "8", 36n);

    doc = BigInt(ia.address);

    tx = await gk.connect(signers[1]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("2", "8", 36n);

    tx = await gk.connect(signers[3]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("3", "8", 36n);

    // ==== Voting For IA ====

    await increaseTime(86400 * 1);
    
    tx = await gk.proposeDocOfGM(doc, 1, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");

    transferCBP("1", "8", 116n);
    
    seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    transferCBP("1", "8", 88n);

    closingDL = (await now()) + 86400;

    tx = await gk.pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.pushToCoffer().");

    transferCBP("1", "8", 58n);
        
    // ---- Close Deal ----
    
    tx = await gk.closeDeal(ia.address, 1, 'Today is Friday.');

    // ---- Deal No.2 ----
    
    auth = await generateAuth(signers[3], cashier.address, 10000);
    tx = await gk.connect(signers[3]).payOffApprovedDeal(auth, ia.address, 2, cashier.address);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.payOffApprovedDeal().");

    transferCBP("3", "8", 58n);
  
    // ==== Class 5 ====

    // ==== Create Investment Agreement ====

    tx = await gk.createIA(1);

    Addr = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.createIA().");
    transferCBP("1", "8", 58n);

    ia = await readContract("InvestmentAgreement", Addr);
    
    // ---- Set GC ----
    
    tx = await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    // ---- Create Deal ----
    closingDeadline = (await now()) + 86400 * 90;

    headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 5,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 2, 2, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    // ---- Add Deal No.2 ----

    headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 2,
      preSeq: 0,
      classOfShare: 5,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 3, 3, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);

    await ia.addBlank(true, false, 1, 1);
    await ia.addBlank(true, true, 1, 2);
    await ia.addBlank(true, true, 1, 3);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();

    tx = await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.circulateIA().");
    transferCBP("1", "8", 36n);

    // ---- Sign IA ----
    tx = await gk.signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.signIA().");
    transferCBP("1", "8", 36n);

    doc = BigInt(ia.address);

    tx = await gk.connect(signers[1]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("2", "8", 36n);

    tx = await gk.connect(signers[3]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("3", "8", 36n);

    // ==== Voting For IA ====

    await increaseTime(86400 * 1);
    
    tx = await gk.proposeDocOfGM(doc, 1, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");

    transferCBP("1", "8", 116n);
    
    seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    transferCBP("1", "8", 88n);

    closingDL = (await now()) + 86400;

    tx = await gk.pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.pushToCoffer().");
    transferCBP("1", "8", 58n);
        
    // ---- Close Deal ----
    
    tx = await gk.closeDeal(ia.address, 1, 'Today is Friday.');

    // ---- Deal No.2 ----
    
    auth = await generateAuth(signers[3], cashier.address, 10000);
    tx = await gk.connect(signers[3]).payOffApprovedDeal(auth, ia.address, 2, cashier.address);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.payOffApprovedDeal().");
    transferCBP("3", "8", 58n);


    // ==== Init Classes ====

    await expect(gk.initClass(3)).to.be.revertedWith("AC.onlyDK: not");
    console.log(" \u2714 Passed Access Control Test for gk.initClass(). \n");    

    tx = await gk.connect(signers[1]).initClass(3);

    let classInfo = await ros.getInfoOfClass(3);
    console.log('infoOfClass:', classInfo);

    seaInfo = parseDrop(await cashier.getInitSeaInfo(3));
    console.log('InitSeaInfo_3: ', seaInfo);

    await expect(tx).to.emit(cashier, "InitClass").withArgs(3, 20000 * 10 ** 4, seaInfo.distrDate);
    console.log(" \u2714 Passed Event Test for cashier.InitClass(3). \n");

    tx = await gk.connect(signers[1]).initClass(4);

    classInfo = await ros.getInfoOfClass(4);
    console.log('infoOfClass_4:', classInfo);

    seaInfo = parseDrop(await cashier.getInitSeaInfo(4));
    console.log('InitSeaInfo_4: ', seaInfo);

    await expect(tx).to.emit(cashier, "InitClass").withArgs(4, 20000 * 10 ** 4, seaInfo.distrDate);
    console.log(" \u2714 Passed Event Test for cashier.InitClass(4). \n");

    tx = await gk.connect(signers[1]).initClass(5);

    classInfo = await ros.getInfoOfClass(5);
    console.log('infoOfClass_5:', classInfo);

    seaInfo = parseDrop(await cashier.getInitSeaInfo(5));
    console.log('InitSeaInfo_5: ', seaInfo);

    await expect(tx).to.emit(cashier, "InitClass").withArgs(5, 20000 * 10 ** 4, seaInfo.distrDate);
    console.log(" \u2714 Passed Event Test for cashier.InitClass(5). \n");

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);
    await usdOfUsers(usdc, cashier.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
