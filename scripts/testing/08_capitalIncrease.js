// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROA, getGMM, getROS, getROM, getRC, } = require("./boox");
const { readContract } = require("../readTool"); 
const { increaseTime, Bytes32Zero, now } = require("./utils");
const { obtainNewShare } = require("./ros");
const { codifyHeadOfDeal, parseDeal } = require("./roa");
const { royaltyTest } = require("./rc");
const { getLatestSeqOfMotion } = require("./gmm");

// This section shows how to draft, propose and close a Capital Increase deal
// by an Investment Agreement. Afther approval of the General Meeting, only 
// the controlling Member may confirm all conditions precedents are satisfied, 
// so as to enable the Deal being able to closed. Upon closing, a new share will 
// be issued to the investor, and the investor will be included into the 
// Register of Members to become a Member. The Owners Equity as well as 
// the Registered Capital will also be increased by the same amount. 

// Similar with other motions of the General Meeting, it is only the Members may 
// propose a Motion to the General Meeting for review and voting. And, for "off-chain"
// consideration payment, only if the hashlock was opened by the correct "Key", the 
// subject share may be issued accordingly.

// The scenario for testing include in this section:
// 1. User_1 as the controlling Member create a draft Investment Agreement (the "Draft")
//    by cloning the Template；
// 2. User_1 as the owner of the Draft appoint himself as the General Counsel to the Draft,
//    so as to enable himself can further setting the deals and signing pages of the Draft;
// 3. User_1 as the Attorney to the Draft, craete a Capital Increase Deal and set up
//    all necessar attributes of an Investment Agreement, such as signing days, closing 
//    days and blanks of signing page;
// 4. User_1 finalize the Draft to block any further change of it;
// 5. User_1 circulate the Draft to Parties of the Investment Agreement;
// 6. User_1 and User_5 signed the Investment Agreement, so as to let it “establshied" in legal;
// 7. User_1 submit the Investment Agreement to the General Meeting of Members for voting;
// 8. All rest Members other than User_1 cast "support" vote for the Motion;
// 9. User_1 triggers the Vote Counting function to make the Motion's state turn into "Passed";
// 10. User_1 as the controlling Member confirms all precedent conditions are fulfilled and 
//     input the HashLock encrypted by Keccat-256;
// 11. User_5 pays the subsciption consideration off-chain and obtains the "Hash Key" to the 
//     Hash Lock installed by User_1;
// 12. User_5 input the correct ”Hash Key" to close the Deal and obtained the newly issued
//     Share。


// The Write APIs tested in this sction:
// 1. General Keper
// 1.1 function createIA(uint256 snOfIA) external;
// 1.2 function circulateIA(address body, bytes32 docUrl, bytes32 docHash) external;
// 1.3 function signIA(address ia, bytes32 sigHash) external;
// 1.4 function pushToCoffer(address ia, uint256 seqOfDeal, bytes32 hashLock, uint closingDeadline) external;
// 1.5 function closeDeal(address ia, uint256 seqOfDeal, string memory hashKey) external;
// 1.6 function proposeDocOfGM(uint doc, uint seqOfVR, uint executor) external;
// 1.7 function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external;
// 1.8 function castVoteOfGM(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;
// 1.9 function voteCountingOfGM(uint256 seqOfMotion) external;

// 2. Investment Agreement
// 2.1 function addDeal(bytes32 sn, uint buyer, uint groupOfBuyer, uint paid,
//     uint par, uint distrWeight) external;
// 2.2 function finalizeIA() external; 

// 3. Draft Control
// 3.1 function setRoleAdmin(bytes32 role, address acct) external;

// 4. Sig Page
// 4.1 function setTiming(bool initPage, uint signingDays, uint closingDays) external;
// 4.2 function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256 acct)external;


async function main() {

    console.log('********************************');
    console.log('**   Capital Increase Deal    **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const roa = await getROA();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();
    const roaKeeper = await readContract("ROAKeeper", await gk.getKeeper(6));

    // ==== Create Investment Agreement ====

    await expect(gk.connect(signers[5]).createIA(1)).to.be.revertedWith("not MEMBER");
    console.log("Passed Access Control Test for gk.createIA(). \n");

    let tx = await gk.createIA(1);

    let Addr = await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.createIA().");

    let ia = await readContract("InvestmentAgreement", Addr);

    expect(await ia.getDK()).to.equal(roaKeeper.address);
    console.log("Passed Result Verify Test for ia.initKeepers(). \n");
    
    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, BigNumber.from(1));
    console.log("Passed Event Test for roa.UpdateStateOfFile(). \n");

    // ---- Set GC ----

    const ATTORNEYS = ethers.utils.formatBytes32String("Attorneys");
    
    tx = await ia.setRoleAdmin(ATTORNEYS, signers[0].address);

    await expect(tx).to.emit(ia, "SetRoleAdmin").withArgs(ATTORNEYS, signers[0].address);
    console.log("Passed Event Test for ia.SetRoleAdmin(). \n");

    expect(await ia.getRoleAdmin(ATTORNEYS)).to.equal(signers[0].address);
    console.log("Passed Result Verify Test for ia.setRoleAdmin(). \n");

    // ---- Create Deal ----
    const closingDeadline = (await now()) + 86400 * 90;

    const headOfDeal = {
      typeOfDeal: 1,
      seqOfDeal: 1,
      preSeq: 0,
      classOfShare: 2,
      seqOfShare: 0,
      seller: 0,
      priceOfPaid: 1.8,
      priceOfPar: 0,
      closingDeadline: closingDeadline,
      votingWeight: 100,
    }
    
    await ia.addDeal(codifyHeadOfDeal(headOfDeal), 5, 5, 10000 * 10 ** 4, 10000 * 10 ** 4, 100);

    let deal = parseDeal(await ia.getDeal(1));

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

    console.log("Passed Result Verify Test for ia.addDeal(). \n");

    // ---- Config SigPage of IA ----

    await ia.setTiming(true, 1, 90);

    expect(await ia.getSigningDays()).to.equal(1);
    expect(await ia.getClosingDays()).to.equal(90);

    console.log("Passed Result Verify Test for ia.setTiming(). \n");

    await ia.addBlank(true, false, 1, 1);
    expect(await ia.isParty(1)).to.equal(true);
    expect(await ia.isSeller(true, 1)).to.equal(true);
    expect(await ia.isBuyer(true, 1)).to.equal(false);

    await ia.addBlank(true, true, 1, 5);
    expect(await ia.isParty(5)).to.equal(true);
    expect(await ia.isSeller(true, 5)).to.equal(false);
    expect(await ia.isBuyer(true, 5)).to.equal(true);

    console.log("Passed Result Verify Test for ia.addBlank(). \n");

    // ---- Sign IA ----

    await ia.finalizeIA();
    expect(await ia.isFinalized()).to.equal(true);

    tx = await gk.circulateIA(ia.address, Bytes32Zero, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.circulateIA().");

    await expect(tx).to.emit(roa, "UpdateStateOfFile").withArgs(Addr, 2);
    console.log("Passed Event Test for roa.UpdateStateOfFile(). \n");

    expect(await ia.circulated()).to.equal(true);

    let circulateDate = await ia.getCirculateDate();
    expect(await ia.getSigDeadline()).to.equal(circulateDate + 86400);
    expect(await ia.getClosingDeadline()).to.equal(circulateDate + 86400 * 90);

    console.log("Passed Result Verify Test for gk.circulateIA(). \n");

    // ---- Sign IA ----

    await expect(gk.connect(signers[3]).signIA(ia.address, Bytes32Zero)).to.be.revertedWith("ROAK.md.OPO: NOT Party");
    console.log("Parssed Access Control Test for gk.signIA(). \n ");

    tx = await gk.signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.signIA().");
    expect(await ia.isSigner(1)).to.equal(true);
    console.log("Parssed Result Verify Test for gk.signIA(). by User_1 \n ");

    const doc = BigInt(ia.address);

    await expect(gk.proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: not established");
    console.log("Parssed Procedure Control Test for gk.proposeDocOfGM(). \n ");

    tx = await gk.connect(signers[5]).signIA(ia.address, Bytes32Zero);
    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 36n, "gk.signIA().");
    expect(await ia.isSigner(5)).to.equal(true);
    console.log("Parssed Result Verify Test for gk.signIA(). by User_5 \n ");

    expect(await ia.established()).to.equal(true);
    console.log("Passed Result Verify Test for gk.signIA() & ia.established(). \n");

    // ==== Voting For IA ====

    await increaseTime(86400 * 3);
    
    await expect(gk.connect(signers[5]).proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: NOT Member");
    console.log("Passed Access Control Test for gk.proposeDocOfGM().OnlyMember() \n");

    await expect(gk.connect(signers[3]).proposeDocOfGM(doc, 1, 1)).to.be.revertedWith("GMMK: not signer");
    console.log("Passed Access Control Test for gk.proposeDocOfGM().OnlySigner() \n");

    tx = await gk.proposeDocOfGM(doc, 1, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 116n, "gk.proposeDocOfGM().");

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log("Passed Evet Test for gmm.CreateMotion(). \n");
    
    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    
    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log("Passed Result Verify Test for gk.proposeDocOfGM(). \n");

    await increaseTime(86400);

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    expect(await gmm.isVoted(seqOfMotion, 2)).to.equal(true);
    console.log("Passed Result Verify Test for gk.castVoteOfGM(). with User_2 \n");


    await gk.connect(signers[4]).entrustDelegaterForGeneralMeeting(seqOfMotion, 3);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    expect(await gmm.isVoted(seqOfMotion, 3)).to.equal(true);
    console.log("Passed Result Verify Test for gk.castVoteOfGM(). with User_3 \n");

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log("Passed Result Verify Test for gk.votingCounting(). \n");

    const closingDL = (await now()) + 86400;

    await expect(gk.connect(signers[1]).pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL)).to.be.revertedWith("ROAK.PTC: not director or controllor");
    console.log("Passed Access Control Test for gk.pushToCoffer(). \n");

    tx = await gk.pushToCoffer(ia.address, 1, ethers.utils.id('Today is Friday.'), closingDL);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.pushToCoffer().");

    await expect(tx).to.emit(ia, "ClearDealCP").withArgs(1, ethers.utils.id('Today is Friday.'), BigNumber.from(closingDL));
    console.log("Passed Evet Test for ia.ClearDealCP(). \n");
    
    deal = parseDeal(await ia.getDeal(1));
    expect(deal.body.state).to.equal(2); // Cleared
    console.log("Passed Result Verify Test for ia.ClearDealCP(). \n");
    
    // ---- Close Deal ----

    await expect(gk.closeDeal(ia.address, 1, 'Today is Thirthday.')).to.be.revertedWith("IA.closeDeal: hashKey NOT correct");
    console.log("Passed Access Control Test for ia.closeDeal(). \n");
    
    tx = await gk.closeDeal(ia.address, 1, 'Today is Friday.');

    await expect(tx).to.emit(ros, "IssueShare");
    console.log("Passed Evet Test for ros.IssueShare(). \n");

    let share = await obtainNewShare(tx);

    expect(share.head.seqOfShare).to.equal(6);
    expect(share.head.shareholder).to.equal(5);
    expect(share.head.priceOfPaid).to.equal('1.8');
    expect(share.body.paid).to.equal('10,000.0');
    
    console.log('Passed Result Verify Test for gk.closeDeal(). \n');

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
