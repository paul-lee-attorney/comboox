// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to nominate and elect directors and officers.

// Nomination rights for the positions of Directors and Officers are allocated
// among the Members in accordance with the Position Rules in the Shareholders'
// Agreement, which also stipulates the Voting Rules for the approval of the
// relevant nominated candidates.

// In the SHA activated in the section 4, the Position Rules are set out as
// follows:

// ________________________________________________________________
// |     SN of Rule       |	    256     |     257 	 |     258    |
// |    SN of Position    |	     1      |	     2     |      3     |
// |   Title of Position  |  Chairman   |	    CEO    |   Manager  |
// |     Nominator        |	    1       |	     0     |      0     |
// |  Title of Nominator  | Shareholder |  Chairman  |     CEO    |
// |   SN of Voting Rule  |	    9	      |     11	   |     11     |
// | End Date of Position |	2026-12-31	| 2026-12-31 | 2026-12-31 |
// ----------------------------------------------------------------

// The above Position Rules mean that:
// (1) Chairman shall be nominated by User_1 as Member and approved by the GMM
//     pursuant to the Voting Rule No. 9 (Simple Majority);
// (2) CEO shall be nominated by Chairman and approved by the Board pursuant to
//     the Voting Rule No. 11 (Simple Majority);
// (3) Manager shall be nominated by CEO and approved by the Board pursuant to 
//     the Voting Rule No. 11 too.

// The scenario for testing included in this section is as follows:
// (1) User_1 nominates himself as the candidate for Chairman as per the SHA;
// (2) All Members vote "for" the motion of Chairman nomination;
// (3) User_1 counts the voting result and takes the seat of Chairman;

// (4) User_1 creates and proposes the motion to remove itself from the Chairman 
//     position;
// (5) All Members vote “for” the motion to remove Chairman;
// (6) User_1 counts the voting result and remove itself from the position of 
//     Chairman;
// (7) User_1 creates and proposes motion itself as Chairman;
// (8) All Members vote “for” the motion to nomination of Chairman;
// (9) User_1 counts the voting result and take the seat of Chairman;
// (10) User_1 (as the Chairman) nominates User_2 as the candidate for CEO;
// (11) User_1 (as the only Director on Board) proposes and votes "for" the motion
//      of CEO nomination;
// (12) User_1 counts the voting result;
// (13) User_2 takes the position of CEO;
// (14) User_2 (as CEO) nominates User_3 as the candidate for Manager;
// (15) User_1 (as the only Director) proposes and votes “for” the motion of 
//      Manager nomination;
// (16) User_1 counts the voting result of the Board Meeting;
// (17) User_3 takes the position of Manager.
// (18) User_3 quits from the position of Manager;
// (19) User_2 nominates User_3 as candidate for Manager;
// (20) User_1 proposes and votes “for” the nomination;
// (21) User_1 counts the vote result;
// (22) User_3 take the position of Manager.


// Write APIs tested in this section:
// 1. GeneralKeeper
// 1.1 function nominateDirector(uint256 seqOfPos, uint candidate) external;
// 1.2 function createMotionToRemoveDirector(uint256 seqOfPos) external;
// 1.3 function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external;
// 1.4 function castVoteOfGM(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;
// 1.5 function voteCountingOfGM(uint256 seqOfMotion) external;
// 1.6 function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external;
// 1.7 function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external;
// 1.8 function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external;
// 1.9 function removeOfficer (uint256 seqOfMotion, uint256 seqOfPos) external;
// 1.10 function quitPosition(uint256 seqOfPos) external;
// 1.11 function nominateOfficer(uint256 seqOfPos, uint candidate) external;
// 1.12 function createMotionToRemoveOfficer(uint256 seqOfPos) external;
// 1.13 function proposeMotionToBoard (uint seqOfMotion) external;
// 1.14 function castVote(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;
// 1.15 function voteCounting(uint256 seqOfMotion) external;

// Events verified in this section:
// 1. General Meeting Minutes
// 1.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);
// 1.2 event ProposeMotionToGeneralMeeting(uint256 indexed seqOfMotion, uint256 indexed proposer);
// 1.3 event CastVoteInGeneralMeeting(uint256 indexed seqOfMotion, 
//     uint256 indexed caller, uint indexed attitude, bytes32 sigHash);
// 1.4 event VoteCounting(uint256 indexed seqOfMotion, uint8 indexed result);
// 1.5 event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);
// 1.6 event ProposeMotionToBoard(uint256 indexed seqOfMotion, uint256 indexed proposer);
// 1.7 event CastVoteInBoardMeeting(uint256 indexed seqOfMotion, uint256 indexed caller, 
//     uint indexed attitude, bytes32 sigHash);

// 2. Register of Directors
// 2.1 event TakePosition(uint256 indexed seqOfPos, uint256 indexed caller);
// 2.2 event RemoveOfficer(uint256 indexed seqOfPos);
// 2.3 event QuitPosition(uint256 indexed seqOfPos, uint256 indexed caller);


const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { getGK, getBMM, getGMM, getROD, getRC, getROS } = require('./boox');
const { positionParser } = require('./sha');
const { Bytes32Zero, increaseTime, parseTimestamp, now } = require('./utils');
const { royaltyTest, cbpOfUsers } = require("./rc");
const { motionSnParser, getLatestSeqOfMotion } = require("./gmm");
const { printShares } = require("./ros");
const { depositOfUsers } = require("./gk");
const { transferCBP } = require("./saveTool");

async function main() {

    console.log('\n********************************');
    console.log('**    05. Elect Officers      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const bmm = await getBMM();
    const gmm = await getGMM();
    const rod = await getROD();
    const ros = await getROS();
    
    // ==== Chairman ====

    // ---- Nominate Chairman ----

    await expect(gk.connect(signers[1]).nominateDirector(1, 1)).to.be.revertedWith("GMMK: has no right");
    console.log(" \u2714 Passed Access Control Test for gk.nominateDirector(). \n");

    let tx = await gk.nominateDirector(1, 1);

    let receipt = await tx.wait();
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 72n, "gk.nominateDirector().");

    transferCBP("1", "8", 72n);
    
    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    let headOfMotion = motionSnParser(receipt.logs[2].topics[1]);
    let contents = parseInt(receipt.logs[2].topics[2].toString());

    expect(headOfMotion.typeOfMotion).to.equal(1); // typeOfMotion: ElectOfficer
    expect(headOfMotion.creator).to.equal(1); // creator user no.
    expect(headOfMotion.executor).to.equal(1); // candidate user no.
    expect(headOfMotion.seqOfVR).to.equal(9); // voting rule no.
    expect(contents).to.equal(1); // position no.

    console.log(" \u2714 Passed Result Verify Test for gk.nominateDirector(). \n");

    // ---- Propose Nomination of Chairman ----

    let seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(gk.connect(signers[5]).proposeMotionToGeneralMeeting(seqOfMotion)).to.be.revertedWith("MR.PMTGM: has no proposalRight");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToGeneralMeeting() \n");

    tx = await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 72n, "gk.proposeMotionToGeneralMeeting()");

    transferCBP("1", "8", 72n);

    await expect(tx).to.emit(gmm, "ProposeMotionToGeneralMeeting").withArgs(seqOfMotion, 1);
    console.log(" \u2714 Passed Event Test for gmm.ProposeMotionToGeneralMeeting() \n");

    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify for gk.ProposeMotionToGeneralMeeting() \n");

    // ---- Cast Vote for Chairman ----

    await expect(gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("Checkpoints: block not yet mined");
    console.log(" \u2714 Passed Procedure Test for gk.castVoteOfGM(). \n");

    await increaseTime(86400);

    await expect(gk.connect(signers[5]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("MR.castVoteInGM: not Member");
    console.log(" \u2714 Passed Access Control Test for gk.castVoteOfGM(). \n");

    tx = await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 72n, "gk.castVoteOfGM().");

    transferCBP("1", "8", 72n);

    await expect(tx).to.emit(gmm, "CastVoteInGeneralMeeting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1), BigNumber.from(1), Bytes32Zero);
    console.log(" \u2714 Passed Event Control Test for gmm.CastVoteInGeneralMeeting(). \n");

    expect(await gmm.isVotedFor(seqOfMotion, 1, 1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM(). \n");

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("2", "8", 72n);

    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("3", "8", 72n);

    await expect(gk.voteCountingOfGM(seqOfMotion)).to.be.revertedWith("MR.VT: vote not ended yet");
    console.log(" \u2714 Passed Procedure Control Test for gmm.voteCountingOfGM(). \n");

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("4", "8", 72n);

    // ---- Vote Counting for Chairman ----    

    tx = await gk.voteCountingOfGM(seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 88n, "gk.voteCountingOfGM().");

    transferCBP("1", "8", 88n);

    await expect(tx).to.emit(gmm, "VoteCounting").withArgs(BigNumber.from(seqOfMotion), 3);
    console.log(" \u2714 Passed Event Control Test for gmm.VoteCounting(). \n");

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.voteCountingOfGM(). \n");

    // ---- Chairman Take Position ----

    await expect(gk.connect(signers[1]).takeSeat(seqOfMotion, 1)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.takeSeat(). \n");
        
    tx = await gk.takeSeat(seqOfMotion, 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.takeSeat().");

    transferCBP("1", "8", 36n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Control Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "TakePosition").withArgs(BigNumber.from(1), BigNumber.from(1));
    console.log(" \u2714 Passed Event Control Test for rod.TakePosition(). \n");

    let pos = positionParser(await rod.getPosition(1));

    expect(pos.nominator).to.equal(1);
    expect(pos.titleOfNominator).to.equal(1);
    expect(pos.acct).to.equal(1);
    console.log(" \u2714 Passed Result Verify Test for gk.takeSeat(). \n");
    
    // ---- Propose to Remove Chairman ----

    await expect(gk.connect(signers[1]).createMotionToRemoveDirector(1)).to.be.revertedWith("GMMK: has no right");
    
    tx = await gk.createMotionToRemoveDirector(1);

    receipt = await tx.wait();

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 116n, "gk.createMotionToRemoveDirector().");

    transferCBP("1", "8", 116n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
    
    headOfMotion = motionSnParser(receipt.logs[2].topics[1]);
    contents = parseInt(receipt.logs[2].topics[2].toString());

    expect(headOfMotion.typeOfMotion).to.equal(2); // typeOfMotion: RemoveOfficer
    expect(headOfMotion.creator).to.equal(1); // creator user no.
    expect(headOfMotion.executor).to.equal(1); // candidate user no.
    expect(headOfMotion.seqOfVR).to.equal(9); // voting rule no.
    expect(contents).to.equal(1); // position no.

    console.log(" \u2714 Passed Result Verify Test for gk.createMotionToRemoveDirector(). \n");

    // ---- Propose, Vote and Exec Motion to Remove Chairman ----

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP("1", "8", 72n);

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("1", "8", 72n);
    transferCBP("2", "8", 72n);
    transferCBP("3", "8", 72n);
    transferCBP("4", "8", 72n);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    await expect(gk.connect(signers[1]).removeDirector(seqOfMotion, 1)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.removeDirector(). \n");

    tx = await gk.removeDirector(seqOfMotion, 1);
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.removeDirector().");

    transferCBP("1", "8", 58n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "RemoveOfficer").withArgs(BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for rod.RemoveOfficer(). \n");

    expect(await rod.isOccupied(1)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for gk.removeDirector(). \n");

    // ---- Reposition of Chairman ----

    await gk.nominateDirector(1, 1);

    transferCBP("1", "8", 72n);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP("1", "8", 72n);

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("1", "8", 72n);
    transferCBP("2", "8", 72n);
    transferCBP("3", "8", 72n);
    transferCBP("4", "8", 72n);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    await gk.takeSeat(seqOfMotion, 1);

    transferCBP("1", "8", 36n);

    // ==== CEO ====

    // ---- Nominate ----

    await expect(gk.connect(signers[1]).nominateOfficer(2, 2)).to.be.revertedWith("BMMKeeper.nominateOfficer: no rights");
    console.log(" \u2714 Passed Access Control Test for gk.nominateOfficer(). \n");

    tx = await gk.nominateOfficer(2, 2);

    receipt = await tx.wait();
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.nominateOfficer().");

    transferCBP("1", "8", 36n);

    await expect(tx).to.emit(bmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for bmm.CreateMotion(). \n");

    headOfMotion = motionSnParser(receipt.logs[2].topics[1]);
    contents = parseInt(receipt.logs[2].topics[2].toString());

    expect(headOfMotion.typeOfMotion).to.equal(1);
    expect(headOfMotion.creator).to.equal(1);
    expect(headOfMotion.executor).to.equal(2);
    expect(headOfMotion.seqOfVR).to.equal(11);
    expect(contents).to.equal(2); 

    console.log(" \u2714 Passed Result Verify Test for gk.nominateOfficer(). \n");

    // ---- Propose ---

    let bmmList = (await bmm.getSeqList()).map(v => Number(v));
    seqOfMotion = bmmList[bmmList.length - 1];

    await expect(gk.connect(signers[1]).proposeMotionToBoard(seqOfMotion)).to.be.revertedWith("BMMK: not director");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToBoard(). \n");

    tx = await gk.proposeMotionToBoard(seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.proposeMotionToBoard().");

    transferCBP("1", "8", 36n);

    await expect(tx).to.be.emit(bmm, "ProposeMotionToBoard").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for bmm.ProposeMotionToBoard(). \n");

    expect(await bmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeMotionToBoard(). \n");

    // ---- Cast Vote ----

    await expect(gk.connect(signers[1]).castVote(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("MR.CVBM: not Director");
    console.log(" \u2714 Passed Access Control Test for gk.castVote(). \n");

    tx = await gk.castVote(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.castVote().");

    transferCBP("1", "8", 36n);

    await expect(tx).to.emit(bmm, "CastVoteInBoardMeeting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1), BigNumber.from(1), Bytes32Zero);
    console.log(" \u2714 Passed Event Test for bmm.CastVoteInBoardMeeting(). \n");

    expect(await bmm.isVoted(seqOfMotion, 1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVote(). \n");

    // ---- Take Position ----

    tx = await gk.voteCounting(seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.voteCounting().");

    transferCBP("1", "8", 58n);

    await expect(tx).to.emit(bmm, "VoteCounting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for bmm.VoteCounting(). \n");

    expect(await bmm.isPassed(seqOfMotion)).to.equal(true);

    tx = await gk.connect(signers[1]).takePosition(seqOfMotion, 2);

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 36n, "gk.takePosition().");

    transferCBP("2", "8", 36n);

    await expect(tx).to.emit(bmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(2));
    console.log(" \u2714 Passed Event Control Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "TakePosition").withArgs(BigNumber.from(2), BigNumber.from(2));
    console.log(" \u2714 Passed Event Control Test for rod.TakePosition(). \n");

    pos = positionParser(await rod.getPosition(2));

    expect(pos.nominator).to.equal(0);
    expect(pos.titleOfNominator).to.equal(2);
    expect(pos.acct).to.equal(2);
    console.log(" \u2714 Passed Result Verify Test for gk.takePosition(). \n");
        
    // ==== Manager ====

    await gk.connect(signers[1]).nominateOfficer(3, 3);
    bmmList = (await bmm.getSeqList()).map(v => Number(v));
    seqOfMotion = bmmList[bmmList.length - 1];

    transferCBP("2", "8", 36n);

    await gk.proposeMotionToBoard(seqOfMotion);

    transferCBP("1", "8", 36n);

    await gk.castVote(seqOfMotion, 1, Bytes32Zero);

    transferCBP("1", "8", 36n);

    await gk.voteCounting(seqOfMotion);

    transferCBP("1", "8", 58n);

    await gk.connect(signers[3]).takePosition(seqOfMotion, 3);

    transferCBP("3", "8", 36n);

    pos = positionParser(await rod.getPosition(3));

    expect(pos.nominator).to.equal(0);
    expect(pos.titleOfNominator).to.equal(6);
    expect(pos.acct).to.equal(3);
    console.log(" \u2714 Passed Result Verify Test for gk.takePosition(). witht the title of Manager \n");

    // ---- Quit ----

    await expect(gk.quitPosition(3)).to.be.revertedWith("OR.quitPosition: not the officer");
    console.log(" \u2714 Passed Access Control Test for gk.quitPosition(). \n");
    
    tx = await gk.connect(signers[3]).quitPosition(3);
    
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 18n, "gk.quitPosition().");
  
    transferCBP("3", "8", 18n);

    await expect(tx).to.emit(rod, "QuitPosition").withArgs(BigNumber.from(3), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for rod.quitPosition(). \n");

    expect(await rod.isOccupied(3)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for gk.quitPosition(). \n");

    // ---- Reposition of Manager ----

    await gk.connect(signers[1]).nominateOfficer(3, 3);
    bmmList = (await bmm.getSeqList()).map(v => Number(v));
    seqOfMotion = bmmList[bmmList.length - 1];

    transferCBP("2", "8", 36n);

    await gk.proposeMotionToBoard(seqOfMotion);

    transferCBP("1", "8", 36n);

    await gk.castVote(seqOfMotion, 1, Bytes32Zero);

    transferCBP("1", "8", 36n);

    await gk.voteCounting(seqOfMotion);

    transferCBP("1", "8", 58n);

    await gk.connect(signers[3]).takePosition(seqOfMotion, 3);

    transferCBP("3", "8", 36n);

    expect(await rod.isOccupied(3)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for  Reposition of Manager. \n");

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
