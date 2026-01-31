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
// to the General Partner (the “GP”) for approval.  

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
// (4) User_3 as Seller and Member circulates the Draft to Buyer (User_3);
// (5) User_3 and User_2 sign the Draft to make it "established" in law;
// (6) User_3 proposes the IA to the GP for approving;
// (7) User_1 approves the proposed IA;
// (8) After counting the vote results, User_3 triggers the 
//     "payOffApprovedDeal()" API to directly close the deal by paying USDC;

// The Write APIs tested in this section:
// 1. Fund Keeper
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

// 6. Fund Keeper
// 6.1 event SaveToCoffer(uint indexed acct, uint256 indexed value, bytes32 indexed reason);

import { network } from "hardhat";
import { encodeBytes32String } from "ethers";
import { expect } from "chai";

import { getROA, getGMM, getROS, getROM, getRC, getCashier, getUSDC, getFK } from "./boox";
import { readTool } from "../readTool"; 
import { increaseTime, Bytes32Zero, now } from "./utils";
import { codifyHeadOfDeal, parseDeal } from "./roa";
import { getLatestShare, printShares } from "./ros";
import { royaltyTest, cbpOfUsers } from "./rc";
import { getLatestSeqOfMotion } from "./gmm";
import { usdOfUsers } from "./gk";
import { transferCBP } from "./saveTool";
import { generateAuth } from "./sigTools";

async function main() {

    console.log('\n');
    console.log('**************************************');
    console.log('**  10.1 Internal Transfer In USDC  **');
    console.log('**************************************');
    console.log('\n');

    const {ethers} = await network.connect();
	  const signers = await ethers.getSigners();

    const rc = await getRC();
    const gk = await getFK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    const usdc = await getUSDC();
    const cashier = await getCashier();
    const addrCashier = await cashier.getAddress();
    const addrRC = await rc.getAddress();
    const addrGK = await gk.getAddress();
    const addrAM = await signers[0].getAddress();
    
    // ==== Create Investment Agreement ====

    let tx = await gk.createIA(1);

    let Addr = await royaltyTest(addrRC, addrAM, addrGK, tx, 58n, "gk.createIA().");

    transferCBP("1", "8", 58n);

    let ia = await readTool("InvestmentAgreement", Addr);

    // ---- Set GC ----

    const ATTORNEYS = encodeBytes32String("Attorneys");
    await ia.setRoleAdmin(ATTORNEYS, addrAM);

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const headOfDeal = {
      typeOfDeal: 3,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 3,
      seqOfShare: 3,
      seller: 3,
      priceOfPaid: 2,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 2, 2, 3000 * 10 ** 4, 3000 * 10 ** 4, 100);

    const deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 2,
      groupOfBuyer: 2, 
      paid: '3,000.0',
      par: '3,000.0',
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

    await ia.addBlank(true, false, 1, 3);

    expect(await ia.isParty(3)).to.equal(true);
    expect(await ia.isSeller(true, 3)).to.equal(true);
    expect(await ia.isBuyer(true, 3)).to.equal(false);

    await ia.addBlank(true, true, 1, 2);
    expect(await ia.isParty(2)).to.equal(true);
    expect(await ia.isSeller(true, 2)).to.equal(false);
    expect(await ia.isBuyer(true, 2)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    tx = await gk.connect(signers[3]).circulateIA(await ia.getAddress(), Bytes32Zero, Bytes32Zero);
    
    await royaltyTest(addrRC, await signers[3].getAddress(), addrGK, tx, 36n, "gk.circulateIA().");

    transferCBP("3", "8", 36n);

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 2);
    console.log(" \u2714 Passed Event Test for roa.UpdateStateOfFile(). \n");

    expect(await ia.circulated()).to.equal(true);

    let circulateDate = await ia.getCirculateDate();
    expect(await ia.getSigDeadline()).to.equal(circulateDate + 86400n);
    expect(await ia.getClosingDeadline()).to.equal(circulateDate + 86400n * 90n);

    console.log(" \u2714 Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----

    // await expect(gk.connect(signers[5]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK.md.OPO: NOT Party");
    console.log(" \u2714 Passed Access Control Test for gk.signIA(). \n ");

    tx = await gk.connect(signers[3]).signIA(await ia.getAddress(), Bytes32Zero);
    await royaltyTest(addrRC, await signers[3].getAddress(), addrGK, tx, 36n, "gk.signIA().");

    transferCBP("3", "8", 36n);

    expect(await ia.isSigner(3)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA(). by User_3 \n ");

    const doc = BigInt(await ia.getAddress());

    // await expect(gk.connect(signers[3]).proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: not established");
    console.log(" \u2714 Passed Procedure Control Test for gk.proposeDocOfGM(). \n ");

    tx = await gk.connect(signers[1]).signIA(await ia.getAddress(), Bytes32Zero);

    await royaltyTest(addrRC, await signers[1].getAddress(), addrGK, tx, 36n, "gk.signIA().");

    transferCBP("2", "8", 36n);

    expect(await ia.isSigner(2)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA(). by User_2 \n ");

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Voting For IA ====

    await increaseTime(86400);
    
    tx = await gk.connect(signers[3]).proposeDocOfGM(doc, 3, 6);

    await royaltyTest(addrRC, await signers[3].getAddress(), addrGK, tx, 116n, "gk.proposeDocOfGM().");
    
    transferCBP("3", "8", 116n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Evet Test for gmm.CreateMotion(). \n");

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("1", "8", 72n);

    expect(await gmm.isVoted(seqOfMotion, 1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM(). with User_1 \n");

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.voteCounting(). \n");

    // ==== PayOffApprovedDeal() ====

    let auth = await generateAuth(signers[1], addrCashier, 6000);
    tx = await gk.connect(signers[1]).payOffApprovedDeal(auth, await ia.getAddress(), 1, await signers[3].getAddress());

    await royaltyTest(addrRC, await signers[1].getAddress(), addrGK, tx, 58n, "gk.payOffApprovedDeal().");

    transferCBP("2", "8", 58n);

    await royaltyTest(addrRC, await signers[3].getAddress(), addrGK, tx, 18n, "gk.payOffApprovedDeal().");
    transferCBP("3", "8", 18n);

    await expect(tx).to.emit(ia, "PayOffApprovedDeal").withArgs(1, 6000n * 10n ** 6n);
    console.log(" \u2714 Passed Event Test for ia.PayOffApprovedDeal(). \n");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(await ia.getAddress(), 6);
    console.log(" \u2714 Passed Event Test for roa.execFile(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(3, 3000 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.increaseCleanPaid(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(11, 2);
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    let share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(11);
    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('2.0');
    expect(share.body.paid).to.equal('3,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.transferTargetShare(). \n'); 

    await printShares(ros);
    await cbpOfUsers(rc, addrGK);
    await usdOfUsers(usdc, addrCashier);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
