// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows how to nominate candidate and cast vote for officers.
// Usually, directors' board seat will be allocated among Members in SHA.
// So, Members may nominate their candidates as per the SHA. In case any
// special position are defined as "nominated by Chairman", such position
// can only be nominated after the "Chairman" was elected by the General 
// Meeting of Members. Thereafter, the Chairman may further nominate 
// candidate accordingly. All officers will be elected as per the Position
// Rules of SHA. Some can be elected by voting of GMM, while, others
// may be elected by the Board. 

// The scenario for testing include in this section:
// 1. User_1 nominates himself as the candidate for Chaireman as per SHA;
// 2. All Members cast "agree" vote for the Chairman nomination;
// 3. User_1 count the voting result and take the seat of Chairman;
// 4. User_1 (as the Chairman) nominates User_2 as the candidate of CEO;
// 5. User_1 (as the only Director on Board) proposes and cast "agree" vote
//    for the CEO nomination motion;
// 6. User_1 count the voting result and User_2 take the position of CEO;
// 7. User_2 as CEO nominates User_3 as the candidate of Manager;
// 8. User_1 as the only Director propose the nomination motion for Manager, 
//    and cast "agree" vote for it.
// 9. User_1 count the voting result of Board Meeting;
// 10. User_3 take the position of Manager.

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

const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { getGK, getBMM, getGMM, getROD, getRC } = require('./boox');
const { positionParser } = require('./sha');
const { Bytes32Zero, increaseTime, parseTimestamp, now } = require('./utils');
const { royaltyTest } = require("./rc");
const { motionSnParser, getLatestSeqOfMotion } = require("./gmm");

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
    
    // ==== Chairman ====

    // ---- Nominate ----

    await expect(gk.connect(signers[1]).nominateDirector(1, 1)).to.be.revertedWith("GMMK: has no right");
    console.log(" \u2714 Passed Access Control Test for gk.nominateDirector(). \n");

    let tx = await gk.nominateDirector(1, 1);

    let receipt = await tx.wait();
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 72n, "gk.nominateDirector().");
    
    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    let headOfMotion = motionSnParser(receipt.logs[1].topics[1]);
    let contents = parseInt(receipt.logs[1].topics[2].toString());

    expect(headOfMotion.typeOfMotion).to.equal(1); // typeOfMotion: ElectOfficer
    expect(headOfMotion.creator).to.equal(1); // creator user no.
    expect(headOfMotion.executor).to.equal(1); // candidate user no.
    expect(headOfMotion.seqOfVR).to.equal(9); // voting rule no.
    expect(contents).to.equal(1); // position no.

    console.log(" \u2714 Passed Result Verify Test for gk.nominateDirector(). \n");

    // ---- Propose ----

    let seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(gk.connect(signers[5]).proposeMotionToGeneralMeeting(seqOfMotion)).to.be.revertedWith("MR.PMTGM: has no proposalRight");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToGeneralMeeting() \n");

    tx = await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 72n, "gk.proposeMotionToGeneralMeeting()");

    await expect(tx).to.emit(gmm, "ProposeMotionToGeneralMeeting").withArgs(seqOfMotion, 1);
    console.log(" \u2714 Passed Event Test for gmm.ProposeMotionToGeneralMeeting() \n");

    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify for gk.ProposeMotionToGeneralMeeting() \n");

    // ---- Cast Vote ----

    await expect(gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("Checkpoints: block not yet mined");
    console.log(" \u2714 Passed Procedure Test for gk.castVoteOfGM(). \n");

    await increaseTime(86400);

    await expect(gk.connect(signers[5]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("MR.castVoteInGM: not Member");
    console.log(" \u2714 Passed Access Control Test for gk.castVoteOfGM(). \n");

    tx = await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 72n, "gk.castVoteOfGM().");

    await expect(tx).to.emit(gmm, "CastVoteInGeneralMeeting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1), BigNumber.from(1), Bytes32Zero);
    console.log(" \u2714 Passed Event Control Test for gmm.CastVoteInGeneralMeeting(). \n");

    expect(await gmm.isVotedFor(seqOfMotion, 1, 1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM(). \n");

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await expect(gk.voteCountingOfGM(seqOfMotion)).to.be.revertedWith("MR.VT: vote not ended yet");
    console.log(" \u2714 Passed Procedure Control Test for gmm.voteCountingOfGM(). \n");

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    // ---- Vote Counting ----    

    tx = await gk.voteCountingOfGM(seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 88n, "gk.voteCountingOfGM().");

    await expect(tx).to.emit(gmm, "VoteCounting").withArgs(BigNumber.from(seqOfMotion), 3);
    console.log(" \u2714 Passed Event Control Test for gmm.VoteCounting(). \n");

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.voteCountingOfGM(). \n");

    // ---- Take Position ----

    await expect(gk.connect(signers[1]).takeSeat(seqOfMotion, 1)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.takeSeat(). \n");
        
    tx = await gk.takeSeat(seqOfMotion, 1);

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

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
    
    headOfMotion = motionSnParser(receipt.logs[1].topics[1]);
    contents = parseInt(receipt.logs[1].topics[2].toString());

    expect(headOfMotion.typeOfMotion).to.equal(2); // typeOfMotion: RemoveOfficer
    expect(headOfMotion.creator).to.equal(1); // creator user no.
    expect(headOfMotion.executor).to.equal(1); // candidate user no.
    expect(headOfMotion.seqOfVR).to.equal(9); // voting rule no.
    expect(contents).to.equal(1); // position no.

    console.log(" \u2714 Passed Result Verify Test for gk.createMotionToRemoveDirector(). \n");

    // ---- Propose, Vote and Exec Motion ----

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await gk.voteCountingOfGM(seqOfMotion);

    await expect(gk.connect(signers[1]).removeDirector(seqOfMotion, 1)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.removeDirector(). \n");

    tx = await gk.removeDirector(seqOfMotion, 1);
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.removeDirector().");

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "RemoveOfficer").withArgs(BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for rod.RemoveOfficer(). \n");

    expect(await rod.isOccupied(1)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for gk.removeDirector(). \n");

    // ---- Reposition of Chairman ----

    await gk.nominateDirector(1, 1);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await increaseTime(86400);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await gk.voteCountingOfGM(seqOfMotion);

    await gk.takeSeat(seqOfMotion, 1);

    // ==== CEO ====

    // ---- Nominate ----

    await expect(gk.connect(signers[1]).nominateOfficer(2, 2)).to.be.revertedWith("BMMKeeper.nominateOfficer: no rights");
    console.log(" \u2714 Passed Access Control Test for gk.nominateOfficer(). \n");

    tx = await gk.nominateOfficer(2, 2);

    receipt = await tx.wait();
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.nominateOfficer().");

    await expect(tx).to.emit(bmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for bmm.CreateMotion(). \n");

    headOfMotion = motionSnParser(receipt.logs[1].topics[1]);
    contents = parseInt(receipt.logs[1].topics[2].toString());

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

    await expect(tx).to.be.emit(bmm, "ProposeMotionToBoard").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for bmm.ProposeMotionToBoard(). \n");

    expect(await bmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.proposeMotionToBoard(). \n");

    // ---- Cast Vote ----

    await expect(gk.connect(signers[1]).castVote(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("MR.CVBM: not Director");
    console.log(" \u2714 Passed Access Control Test for gk.castVote(). \n");

    tx = await gk.castVote(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.castVote().");

    await expect(tx).to.emit(bmm, "CastVoteInBoardMeeting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1), BigNumber.from(1), Bytes32Zero);
    console.log(" \u2714 Passed Event Test for bmm.CastVoteInBoardMeeting(). \n");

    expect(await bmm.isVoted(seqOfMotion, 1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVote(). \n");

    tx = await gk.voteCounting(seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 58n, "gk.voteCounting().");

    await expect(tx).to.emit(bmm, "VoteCounting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for bmm.VoteCounting(). \n");

    expect(await bmm.isPassed(seqOfMotion)).to.equal(true);

    tx = await gk.connect(signers[1]).takePosition(seqOfMotion, 2);

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 36n, "gk.takePosition().");

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

    await gk.proposeMotionToBoard(seqOfMotion);
    await gk.castVote(seqOfMotion, 1, Bytes32Zero);
    await gk.voteCounting(seqOfMotion);
    await gk.connect(signers[3]).takePosition(seqOfMotion, 3);

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
  
    await expect(tx).to.emit(rod, "QuitPosition").withArgs(BigNumber.from(3), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for rod.quitPosition(). \n");

    expect(await rod.isOccupied(3)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for gk.quitPosition(). \n");

    // ---- Reposition of Manager ----

    await gk.connect(signers[1]).nominateOfficer(3, 3);
    bmmList = (await bmm.getSeqList()).map(v => Number(v));
    seqOfMotion = bmmList[bmmList.length - 1];

    await gk.proposeMotionToBoard(seqOfMotion);
    await gk.castVote(seqOfMotion, 1, Bytes32Zero);
    await gk.voteCounting(seqOfMotion);
    await gk.connect(signers[3]).takePosition(seqOfMotion, 3);

    expect(await rod.isOccupied(3)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for  Reposition of Manager. \n");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
