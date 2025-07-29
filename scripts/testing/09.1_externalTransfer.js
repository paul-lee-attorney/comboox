// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to draft, propose and close an External
// Share Transfer deal by means of Investment Agreement. Seller shall 
// create a Draft of Invesment Agreement (the "Draft") first, and then,
// appoint an attorney to set up the deal, signing deadline and parties of
// the agreement.  Thereafter, the Seller shall circulate the draft to the Buyer
// concerned, and afther all parties signed, the sales deal in the Draft 
// will be established in leagal sense, and the target shall will be locked for
// for the subject amount. Thereafter, the Seller shall propose the Investment 
// Agreement to GP for approval.  
// After approval, Buyer and Seller may close the deal on-chain or off-chain.
// A new shall will be issued to the Buyer, and the transferred amount will be 
// deduced from the target share concerned. In case there is no balance amount
// left in the target Share, it will be deregistered from the Register of Shares 
// ("ROS") accordingly.

// The scenario for testing in this section are as follows:
// 1. User_1 creates an Investment Agreement (the "Draft") by cloning the Template of IA;
// 2. User_1 appoints itself as the Attorney to the Draft;
// 3. User_1 sets up the Darft with respect to the deal, signing days, closing days and
//    parties to the IA accordingly;
// 4. User_2 as Seller and Member circulate the Draft to Buyer (User_4);
// 5. User_2 and User_4 signed the Draft to make it "established" in law;
// 6. User_2 propose the IA to the GP for voting;
// 7. GP approves the proposed IA;
// 8. After counting the vote results, User_2 triggers the "transferTargetShare" API
//    to directly transfer the target share;

// The Write APIs tested in this section:
// 1. Fund Keeper
// 1.1 function createIA(uint256 snOfIA) external;
// 1.2 function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external;
// 1.3 function signIA(address ia, bytes32 sigHash) external;
// 1.4 function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external;
// 1.6 function castVoteOfGM(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;
// 1.7 function voteCountingOfGM(uint256 seqOfMotion) external;
// 1.8 function transferTargetShare(address ia, uint256 seqOfDeal) external;

// 2. Investment Agreement
// 2.1 function addDeal(bytes32 sn, uint buyer, uint groupOfBuyer, uint paid,
//     uint par, uint distrWeight) external;
// 2.2 function finalizeIA() external; 

// 3. Draft Control
// 3.1 function setRoleAdmin(bytes32 role, address acct) external;

// 4. Sig Page
// 4.1 function setTiming(bool initPage, uint signingDays, uint closingDays) external;
// 4.2 function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256 acct)external;

// Events verified in this section:
// 1. Register of Agreement
// 1.1 event UpdateStateOfFile(address indexed body, uint indexed state);

// 2. Register of Shares
// 2.1 event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.2 event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.3 event DeregisterShare(uint256 indexed seqOfShare);

// 3. General Meeting Minutes
// 3.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);

// 4. Investment Agreement
// 4.1 event CloseDeal(uint256 indexed seq, string indexed hashKey);

// 5. Register of Members
// 5.1 event RemoveShareFromMember(uint indexed seqOfShare, uint indexed acct);
// 5.2 event AddMember(uint256 indexed acct, uint indexed qtyOfMembers);
// 5.3 event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

const { expect } = require("chai");
const { getROA, getGMM, getROS, getROM, getRC, getFK, getSHA, } = require("./boox");
const { readContract } = require("../readTool"); 
const { increaseTime, Bytes32Zero, now, } = require("./utils");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { getLatestShare, printShares } = require("./ros");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");
const { transferCBP } = require("./saveTool");

async function main() {

    console.log('\n');
    console.log('*********************************');
    console.log('**   09.1 External Transfer    **');
    console.log('*********************************');
    console.log('\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getFK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    const sha = await getSHA();
    
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
      typeOfDeal: 2,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 2,
      seller: 2,
      priceOfPaid: 1.5,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 4, 4, 5000 * 10 ** 4, 5000 * 10 ** 4, 100);

    let deal = parseDeal(await ia.getDeal(1));

    expect(deal.head).to.deep.equal(headOfDeal);
    expect(deal.body).to.deep.equal({
      buyer: 4,
      groupOfBuyer: 4, 
      paid: '5,000.0',
      par: '5,000.0',
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

    await ia.addBlank(true, false, 1, 2);

    expect(await ia.isParty(2)).to.equal(true);
    expect(await ia.isSeller(true, 2)).to.equal(true);
    expect(await ia.isBuyer(true, 2)).to.equal(false);

    await ia.addBlank(true, true, 1, 4);
    expect(await ia.isParty(4)).to.equal(true);
    expect(await ia.isSeller(true, 4)).to.equal(false);
    expect(await ia.isBuyer(true, 4)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    tx = await gk.connect(signers[4]).circulateIA(ia.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[4].address, gk.address, tx, 36n, "gk.circulateIA().");

    transferCBP("4", "8", 36n);

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 2);
    console.log(" \u2714 Passed Event Test for roa.UpdateStateOfFile(). \n");

    expect(await ia.circulated()).to.equal(true);

    let circulateDate = await ia.getCirculateDate();
    expect(await ia.getSigDeadline()).to.equal(circulateDate + 86400);
    expect(await ia.getClosingDeadline()).to.equal(circulateDate + 86400 * 90);

    console.log(" \u2714 Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----

    await expect(gk.connect(signers[5]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK.md.OPO: NOT Party");
    console.log(" \u2714 Passed Access Control Test for gk.signIA(). \n ");

    tx = await gk.connect(signers[1]).signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("2", "8", 36n);

    expect(await ia.isSigner(2)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA(). by User_2 \n ");

    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(2, 5000 * 10 ** 4);
    console.log(" \u2714 Passed Evet Test for ros.DecreaseCleanPaid(). \n");

    const doc = BigInt(ia.address);

    await expect(gk.connect(signers[1]).proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: not established");
    console.log(" \u2714 Passed Procedure Control Test for gk.proposeDocOfGM(). \n ");

    // ---- Accept LPA By User_4 ----

    await expect(gk.connect(signers[4]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK: buyer not signer of SHA");
    console.log(" \u2714 Passed LPA Acceptance Test for gk.signIA(). \n ");

    tx = await gk.connect(signers[4]).acceptSHA(Bytes32Zero);
    transferCBP("4", "8", 36n);

    let res = await sha.isSigner(4);

    expect(res).to.equal(true);
    console.log(" \u2714 Passed Result Test for GK.acceptSHA(). User_4 \n");

    // ---- Sign IA by User_4 ----

    tx = await gk.connect(signers[4]).signIA(ia.address, Bytes32Zero);

    await royaltyTest(rc.address, signers[4].address, gk.address, tx, 36n, "gk.signIA().");

    transferCBP("4", "8", 36n);

    expect(await ia.isSigner(4)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA(). by User_4 \n ");

    expect(await ia.established()).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Voting For IA ====

    await increaseTime(86400);
    
    tx = await gk.connect(signers[1]).proposeDocOfGM(doc, 2, 4);

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");

    transferCBP("2", "8", 116n);

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

    // ==== Transfer ====

    await expect(gk.transferTargetShare(ia.address, 1)).to.be.revertedWith("ROAK.TTS: not seller");
    console.log(" \u2714 Passed Access Control Test for gk.transferTargetShare(). \n");

    tx = await gk.connect(signers[1]).transferTargetShare(ia.address, 1);

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 58n, "gk.transferTargetShare().");

    transferCBP("2", "8", 58n);

    await expect(tx).to.emit(ia, "CloseDeal").withArgs(1, "");
    console.log(" \u2714 Passed Event Test for ia.loseDeal(). \n");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(ia.address, 6);
    console.log(" \u2714 Passed Event Test for roa.execFile(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(2, 5000 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.increaseCleanPaid(). \n");

    await expect(tx).to.emit(rom, "AddMember").withArgs(4, 4);
    console.log(" \u2714 Passed Event Test for rom.AddMember(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(10, 4);
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");
  
    let share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(10);
    expect(share.head.shareholder).to.equal(4);
    expect(share.head.priceOfPaid).to.equal('1.5');
    expect(share.body.paid).to.equal('5,000.0');
    
    console.log(' \u2714 Passed Result Verify Test for gk.transferTargetShare(). \n'); 

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
