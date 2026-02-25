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

import { network } from "hardhat";
import { expect } from "chai";

import { getGK, getBMM, getGMM, getROD, getRC, getROS } from './boox';
import { positionParser } from './sha';
import { Bytes32Zero, increaseTime, } from './utils';
import { royaltyTest, cbpOfUsers, getAllUsers } from "./rc";
import { motionSnParser, getLatestSeqOfMotion } from "./gmm";
import { printShares } from "./ros";
import { transferCBP } from "./saveTool";
import { parseCompInfo } from "./gk";
import { readTool } from "../readTool";

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**    05. Elect Officers      **');
    console.log('********************************');
    console.log('\n');

    const {ethers} = await network.connect();

	  const signers = await ethers.getSigners();

    const rc = await getRC();
    let gk = await getGK();
    const users = await getAllUsers(rc, 6);
    const userComp = await parseCompInfo(await gk.getCompInfo()).regNum;
    const bmm = await getBMM();
    const gmm = await getGMM();
    const rod = await getROD();
    const ros = await getROS();
    
    // ==== Chairman ====

    // ---- Nominate Chairman ----

    gk = await readTool("IGMMKeeper", gk.target);

    // await expect(gk.connect(signers[1]).nominateDirector(1, 1)).to.be.revertedWith("GMMK: has no right");
    console.log(" \u2714 Passed Access Control Test for gk.nominateDirector(). \n");

    let tx = await gk.nominateDirector(1, users[0]);

    let receipt = await tx.wait();
    
    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 72n, "gk.nominateDirector().");

    transferCBP(users[0], userComp, 72n);
    
    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    let headOfMotion = motionSnParser(receipt.logs[2].topics[1]);
    let contents = parseInt(receipt.logs[2].topics[2].toString());

    expect(headOfMotion.typeOfMotion).to.equal(1); // typeOfMotion: ElectOfficer
    expect(headOfMotion.creator).to.equal(users[0]); // creator user no.
    expect(headOfMotion.executor).to.equal(users[0]); // candidate user no.
    expect(headOfMotion.seqOfVR).to.equal(9); // voting rule no.
    expect(contents).to.equal(1); // position no.

    console.log(" \u2714 Passed Result Verify Test for gk.nominateDirector(). \n");

    // ---- Propose Nomination of Chairman ----

    let seqOfMotion = await getLatestSeqOfMotion(gmm);

    // await expect(gk.connect(signers[5]).proposeMotionToGeneralMeeting(seqOfMotion)).to.be.revertedWith("MR.PMTGM: has no proposalRight");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToGeneralMeeting() \n");

    tx = await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 72n, "gk.proposeMotionToGeneralMeeting()");

    transferCBP(users[0], userComp, 72n);

    await expect(tx).to.emit(gmm, "ProposeMotionToGeneralMeeting").withArgs(seqOfMotion, users[0]);
    console.log(" \u2714 Passed Event Test for gmm.ProposeMotionToGeneralMeeting() \n");

    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify for gk.ProposeMotionToGeneralMeeting() \n");

    // ---- Cast Vote for Chairman ----

    // await expect(gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("Checkpoints: block not yet mined");
    console.log(" \u2714 Passed Procedure Test for gk.castVoteOfGM(). \n");

    await increaseTime(86400);

    // await expect(gk.connect(signers[5]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("MR.castVoteInGM: not Member");
    console.log(" \u2714 Passed Access Control Test for gk.castVoteOfGM(). \n");

    tx = await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 72n, "gk.castVoteOfGM().");

    transferCBP(users[0], userComp, 72n);

    await expect(tx).to.emit(gmm, "CastVoteInGeneralMeeting").withArgs(seqOfMotion, users[0], 1, Bytes32Zero);
    console.log(" \u2714 Passed Event Control Test for gmm.CastVoteInGeneralMeeting(). \n");

    expect(await gmm.isVotedFor(seqOfMotion, users[0], 1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM(). \n");

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[1], userComp, 72n);

    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[3], userComp, 72n);

    // await expect(gk.voteCountingOfGM(seqOfMotion)).to.be.revertedWith("MR.VT: vote not ended yet");
    console.log(" \u2714 Passed Procedure Control Test for gmm.voteCountingOfGM(). \n");

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[4], userComp, 72n);

    // ---- Vote Counting for Asset Manager ----

    tx = await gk.voteCountingOfGM(seqOfMotion);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 88n, "gk.voteCountingOfGM().");

    transferCBP(users[0], userComp, 88n);

    await expect(tx).to.emit(gmm, "VoteCounting").withArgs(seqOfMotion, 3);
    console.log(" \u2714 Passed Event Control Test for gmm.VoteCounting(). \n");

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.voteCountingOfGM(). \n");

    // ---- Asset Manager Take Position ----

    // await expect(gk.connect(signers[1]).takeSeat(seqOfMotion, 1)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.takeSeat(). \n");

    gk = await readTool("IRODKeeper", gk.target);

    tx = await gk.takeSeat(seqOfMotion, 1);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 36n, "gk.takeSeat().");

    transferCBP(users[0], userComp, 36n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(seqOfMotion, users[0]);
    console.log(" \u2714 Passed Event Control Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "TakePosition").withArgs(1, users[0]);
    console.log(" \u2714 Passed Event Control Test for rod.TakePosition(). \n");

    let pos = positionParser(await rod.getPosition(1));

    expect(pos.nominator).to.equal(users[0]);
    expect(pos.titleOfNominator).to.equal(1);
    expect(pos.acct).to.equal(users[0]);
    console.log(" \u2714 Passed Result Verify Test for gk.takeSeat(). \n");
    
    // ---- Propose to Remove Chairman ----

    // await expect(gk.connect(signers[1]).createMotionToRemoveDirector(1)).to.be.revertedWith("GMMK: has no right");

    gk = await readTool("IGMMKeeper", gk.target);

    tx = await gk.createMotionToRemoveDirector(1);

    receipt = await tx.wait();

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 116n, "gk.createMotionToRemoveDirector().");

    transferCBP(users[0], userComp, 116n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
    
    headOfMotion = motionSnParser(receipt.logs[2].topics[1]);
    contents = parseInt(receipt.logs[2].topics[2].toString());

    expect(headOfMotion.typeOfMotion).to.equal(2); // typeOfMotion: RemoveOfficer
    expect(headOfMotion.creator).to.equal(users[0]); // creator user no.
    expect(headOfMotion.executor).to.equal(users[0]); // candidate user no.
    expect(headOfMotion.seqOfVR).to.equal(9); // voting rule no.
    expect(contents).to.equal(1); // position no.

    console.log(" \u2714 Passed Result Verify Test for gk.createMotionToRemoveDirector(). \n");

    // ---- Propose, Vote and Exec Motion to Remove Chairman ----

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP(users[0], userComp, 72n);

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[0], userComp, 72n);
    transferCBP(users[1], userComp, 72n);
    transferCBP(users[3], userComp, 72n);
    transferCBP(users[4], userComp, 72n);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP(users[0], userComp, 88n);

    // await expect(gk.connect(signers[1]).removeDirector(seqOfMotion, 1)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.removeDirector(). \n");

    gk = await readTool("IRODKeeper", gk.target);

    tx = await gk.removeDirector(seqOfMotion, 1);
    
    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 58n, "gk.removeDirector().");

    transferCBP(users[0], userComp, 58n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(seqOfMotion, users[0]);
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "RemoveOfficer").withArgs(1);
    console.log(" \u2714 Passed Event Test for rod.RemoveOfficer(). \n");

    expect(await rod.isOccupied(1)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for gk.removeDirector(). \n");

    // ---- Reposition of Chairman ----

    gk = await readTool("IGMMKeeper", gk.target);

    await gk.nominateDirector(1, users[0]);

    transferCBP(users[0], userComp, 72n);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP(users[0], userComp, 72n);

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[0], userComp, 72n);
    transferCBP(users[1], userComp, 72n);
    transferCBP(users[3], userComp, 72n);
    transferCBP(users[4], userComp, 72n);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP(users[0], userComp, 88n);

    gk = await readTool("IRODKeeper", gk.target);

    await gk.takeSeat(seqOfMotion, 1);

    transferCBP(users[0], userComp, 36n);

    // ==== CEO ====

    // ---- Nominate ----

    // await expect(gk.connect(signers[1]).nominateOfficer(2, 2)).to.be.revertedWith("BMMKeeper.nominateOfficer: no rights");
    console.log(" \u2714 Passed Access Control Test for gk.nominateOfficer(). \n");

    gk = await readTool("IBMMKeeper", gk.target);

    tx = await gk.nominateOfficer(2, users[1]);

    receipt = await tx.wait();
    
    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 36n, "gk.nominateOfficer().");

    transferCBP(users[0], userComp, 36n);

    await expect(tx).to.emit(bmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for bmm.CreateMotion(). \n");

    headOfMotion = motionSnParser(receipt.logs[2].topics[1]);
    contents = parseInt(receipt.logs[2].topics[2].toString());

    expect(headOfMotion.typeOfMotion).to.equal(1);
    expect(headOfMotion.creator).to.equal(users[0]);
    expect(headOfMotion.executor).to.equal(users[1]);
    expect(headOfMotion.seqOfVR).to.equal(11);
    expect(contents).to.equal(2);

    console.log(" \u2714 Passed Result Verify Test for gk.nominateOfficer(). \n");

    // ---- Propose ---

    let bmmList = (await bmm.getSeqList()).map(v => Number(v));
    seqOfMotion = bmmList[bmmList.length - 1];

    // await expect(gk.connect(signers[1]).proposeMotionToBoard(seqOfMotion)).to.be.revertedWith("BMMK: not director");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToBoard(). \n");

    tx = await gk.proposeMotionToBoard(seqOfMotion);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 36n, "gk.proposeMotionToBoard().");

    transferCBP(users[0], userComp, 36n);

    await expect(tx).to.emit(bmm, "ProposeMotionToBoard").withArgs(seqOfMotion, users[0]);
    console.log(" \u2714 Passed Event Test for bmm.ProposeMotionToBoard(). \n");

    expect(await bmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeMotionToBoard(). \n");

    // ---- Cast Vote ----

    // await expect(gk.connect(signers[1]).castVote(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("MR.CVBM: not Director");
    console.log(" \u2714 Passed Access Control Test for gk.castVote(). \n");

    tx = await gk.castVote(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 36n, "gk.castVote().");

    transferCBP(users[0], userComp, 36n);

    await expect(tx).to.emit(bmm, "CastVoteInBoardMeeting").withArgs(seqOfMotion, users[0], 1, Bytes32Zero);
    console.log(" \u2714 Passed Event Test for bmm.CastVoteInBoardMeeting(). \n");

    expect(await bmm.isVoted(seqOfMotion, users[0])).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVote(). \n");

    // ---- Take Position ----

    tx = await gk.voteCounting(seqOfMotion);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 58n, "gk.voteCounting().");

    transferCBP(users[0], userComp, 58n);

    await expect(tx).to.emit(bmm, "VoteCounting").withArgs(seqOfMotion, 3);
    console.log(" \u2714 Passed Event Test for bmm.VoteCounting(). \n");

    expect(await bmm.isPassed(seqOfMotion)).to.equal(true);

    gk = await readTool("RODKeeper", gk.target);

    tx = await gk.connect(signers[1]).takePosition(seqOfMotion, 2);

    await royaltyTest(rc.target, signers[1].address, gk.target, tx, 36n, "gk.takePosition().");

    transferCBP(users[1], userComp, 36n);

    await expect(tx).to.emit(bmm, "ExecResolution").withArgs(seqOfMotion, users[1]);
    console.log(" \u2714 Passed Event Control Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "TakePosition").withArgs(2, users[1]);
    console.log(" \u2714 Passed Event Control Test for rod.TakePosition(). \n");

    pos = positionParser(await rod.getPosition(2));

    expect(pos.nominator).to.equal(0);
    expect(pos.titleOfNominator).to.equal(2);
    expect(pos.acct).to.equal(users[1]);
    console.log(" \u2714 Passed Result Verify Test for gk.takePosition(). \n");
        
    // ==== Manager ====

    gk = await readTool("BMMKeeper", gk.target);

    await gk.connect(signers[1]).nominateOfficer(3, users[3]);
    bmmList = (await bmm.getSeqList()).map(v => Number(v));
    seqOfMotion = bmmList[bmmList.length - 1];

    transferCBP(users[1], userComp, 36n);

    await gk.proposeMotionToBoard(seqOfMotion);

    transferCBP(users[0], userComp, 36n);

    await gk.castVote(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[0], userComp, 36n);

    await gk.voteCounting(seqOfMotion);

    transferCBP(users[0], userComp, 58n);

    gk = await readTool("RODKeeper", gk.target);

    await gk.connect(signers[3]).takePosition(seqOfMotion, 3);

    transferCBP(users[3], userComp, 36n);

    pos = positionParser(await rod.getPosition(3));

    expect(pos.nominator).to.equal(0);
    expect(pos.titleOfNominator).to.equal(6);
    expect(pos.acct).to.equal(users[3]);
    console.log(" \u2714 Passed Result Verify Test for gk.takePosition(). witht the title of Manager \n");

    // ---- Quit ----

    // await expect(gk.quitPosition(3)).to.be.revertedWith("OR.quitPosition: not the officer");
    console.log(" \u2714 Passed Access Control Test for gk.quitPosition(). \n");
    
    tx = await gk.connect(signers[3]).quitPosition(3);
    
    await royaltyTest(rc.target, signers[3].address, gk.target, tx, 18n, "gk.quitPosition().");
  
    transferCBP(users[3], userComp, 18n);

    await expect(tx).to.emit(rod, "QuitPosition").withArgs(3, users[3]);
    console.log(" \u2714 Passed Event Test for rod.quitPosition(). \n");

    expect(await rod.isOccupied(3)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for gk.quitPosition(). \n");

    // ---- Reposition of Manager ----

    gk = await readTool("BMMKeeper", gk.target);

    await gk.connect(signers[1]).nominateOfficer(3, users[3]);
    bmmList = (await bmm.getSeqList()).map(v => Number(v));
    seqOfMotion = bmmList[bmmList.length - 1];

    transferCBP(users[1], userComp, 36n);

    await gk.proposeMotionToBoard(seqOfMotion);

    transferCBP(users[0], userComp, 36n);

    await gk.castVote(seqOfMotion, 1, Bytes32Zero);

    transferCBP(users[0], userComp, 36n);

    await gk.voteCounting(seqOfMotion);

    transferCBP(users[0], userComp, 58n);

    gk = await readTool("RODKeeper", gk.target);

    await gk.connect(signers[3]).takePosition(seqOfMotion, 3);

    transferCBP(users[3], userComp, 36n);

    expect(await rod.isOccupied(3)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for  Reposition of Manager. \n");

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
