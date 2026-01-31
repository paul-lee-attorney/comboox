// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to nominate and elect directors and officers.

// Nomination rights for the positions of Directors and Officers are allocated
// among the Members in accordance with the Position Rules in the LPA,
// which also stipulates the Voting Rules for the approval of the
// relevant nominated candidates.

// In the LPA activated in the section 4, the Position Rules are set out as
// follows:

// __________________________________________  
// |     SN of Rule       |	      256       |  
// |    SN of Position    |	       1        |	 
// |   Title of Position  |  Asset Manager  |	 
// |     Nominator        |	       1        |	 
// |  Title of Nominator  | General Partner | 
// |   SN of Voting Rule  | 	     9	      |
// | End Date of Position |	  2026-12-31  	|
// ------------------------------------------

// The above Position Rules mean that:
// (1) Asset Manager shall be nominated by User_1 as Member and approved by the GMM
//     pursuant to the Voting Rule No. 9 (Decisive Matters of GP);

// The scenario for testing included in this section is as follows:
// (1) User_1 nominates himself as the candidate for AM as per the LPA;
// (2) User_1 as GP cast vote "for" the motion of AM nomination;
// (3) User_1 counts the voting result and takes the seat of AM;

// Write APIs tested in this section:
// 1. FundKeeper
// 1.1 function nominateDirector(uint256 seqOfPos, uint candidate) external;
// 1.2 function createMotionToRemoveDirector(uint256 seqOfPos) external;
// 1.3 function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external;
// 1.4 function castVoteOfGM(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;
// 1.5 function voteCountingOfGM(uint256 seqOfMotion) external;
// 1.6 function takeSeat(uint256 seqOfMotion, uint256 seqOfPos) external;
// 1.7 function removeDirector (uint256 seqOfMotion, uint256 seqOfPos) external;
// 1.8 function takePosition(uint256 seqOfMotion, uint256 seqOfPos) external;

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
import { getGMM, getROD, getRC, getROS, getFK } from './boox';
import { positionParser } from './sha';
import { Bytes32Zero } from './utils';
import { royaltyTest, cbpOfUsers } from "./rc";
import { motionSnParser, getLatestSeqOfMotion } from "./gmm";
import { printShares } from "./ros";
import { transferCBP } from "./saveTool";

async function main() {

    console.log('\n');
    console.log('************************************');
    console.log('**   05.1 Appoint Asset Manager   **');
    console.log('************************************');
    console.log('\n');

    const { ethers } = await network.connect();
	  const signers = await ethers.getSigners();

    const rc = await getRC();
    const gk = await getFK();
    const gmm = await getGMM();
    const rod = await getROD();
    const ros = await getROS();
    const addrRC = await rc.getAddress();
    const addrGK = await gk.getAddress();
    
    // ==== Chairman ====

    // ---- Nominate Chairman ----

    // await expect(gk.connect(signers[1]).nominateDirector(1, 1)).to.be.revertedWith("MR.memberExist: not");
    console.log(" \u2714 Passed Access Control Test for gk.nominateDirector(). \n");

    let tx = await gk.nominateDirector(1, 1);

    let receipt = await tx.wait();
    
    await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 72n, "gk.nominateDirector().");

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

    // ---- Propose Nomination of Asset Manager ----

    let seqOfMotion = await getLatestSeqOfMotion(gmm);

    // await expect(gk.connect(signers[5]).proposeMotionToGeneralMeeting(seqOfMotion)).to.be.revertedWith("MR.PMTGM: has no proposalRight");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToGeneralMeeting() \n");

    tx = await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 72n, "gk.proposeMotionToGeneralMeeting()");

    transferCBP("1", "8", 72n);

    await expect(tx).to.emit(gmm, "ProposeMotionToGeneralMeeting").withArgs(seqOfMotion, 1);
    console.log(" \u2714 Passed Event Test for gmm.ProposeMotionToGeneralMeeting() \n");

    expect(await gmm.isProposed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify for gk.ProposeMotionToGeneralMeeting() \n");

    // ---- Cast Vote for Asset Manager ----

    // await expect(gk.connect(signers[5]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.be.revertedWith("MR.memberExist: not");
    console.log(" \u2714 Passed Access Control Test for gk.castVoteOfGM(). \n");

    tx = await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 72n, "gk.castVoteOfGM().");

    transferCBP("1", "8", 72n);

    await expect(tx).to.emit(gmm, "CastVoteInGeneralMeeting").withArgs(seqOfMotion, 1, 1, Bytes32Zero);
    console.log(" \u2714 Passed Event Control Test for gmm.CastVoteInGeneralMeeting(). \n");

    expect(await gmm.isVotedFor(seqOfMotion, 1, 1)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.castVoteOfGM(). \n");

    // ---- Vote Counting for Asset Manager ----

    tx = await gk.voteCountingOfGM(seqOfMotion);

    await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 88n, "gk.voteCountingOfGM().");

    transferCBP("1", "8", 88n);

    await expect(tx).to.emit(gmm, "VoteCounting").withArgs(seqOfMotion, 3);
    console.log(" \u2714 Passed Event Control Test for gmm.VoteCounting(). \n");

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Verify Test for gk.voteCountingOfGM(). \n");

    // ---- Asset Manager Take Position ----

    // await expect(gk.connect(signers[1]).takeSeat(seqOfMotion, 1)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.takeSeat(). \n");
        
    tx = await gk.takeSeat(seqOfMotion, 1);

    await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 36n, "gk.takeSeat().");

    transferCBP("1", "8", 36n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(seqOfMotion, 1);
    console.log(" \u2714 Passed Event Control Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "TakePosition").withArgs(1, 1);
    console.log(" \u2714 Passed Event Control Test for rod.TakePosition(). \n");

    let pos = positionParser(await rod.getPosition(1));

    expect(pos.nominator).to.equal(1);
    expect(pos.titleOfNominator).to.equal(1);
    expect(pos.acct).to.equal(1);
    console.log(" \u2714 Passed Result Verify Test for gk.takeSeat(). \n");
    
    // ---- Propose to Remove Asset Manager ----

    // await expect(gk.connect(signers[1]).createMotionToRemoveDirector(1)).to.be.revertedWith("GMMK: has no right");
    
    tx = await gk.createMotionToRemoveDirector(1);

    receipt = await tx.wait();

    await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 116n, "gk.createMotionToRemoveDirector().");

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

    // ---- Propose, Vote and Exec Motion to Remove Asset Manager ----

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP("1", "8", 72n);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("1", "8", 72n);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    // await expect(gk.connect(signers[1]).removeDirector(seqOfMotion, 1)).to.be.revertedWith("MR.ER: not executor");
    console.log(" \u2714 Passed Access Control Test for gk.removeDirector(). \n");

    tx = await gk.removeDirector(seqOfMotion, 1);
    
    await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 58n, "gk.removeDirector().");

    transferCBP("1", "8", 58n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(seqOfMotion, 1);
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(rod, "RemoveOfficer").withArgs(1);
    console.log(" \u2714 Passed Event Test for rod.RemoveOfficer(). \n");

    expect(await rod.isOccupied(1)).to.equal(false);
    console.log(" \u2714 Passed Result Verify Test for gk.removeDirector(). \n");

    // ---- Reposition of Asset Manager ----

    await gk.nominateDirector(1, 1);

    transferCBP("1", "8", 72n);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP("1", "8", 72n);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("1", "8", 72n);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    await gk.takeSeat(seqOfMotion, 1);

    transferCBP("1", "8", 36n);

    await printShares(ros);
    await cbpOfUsers(rc, addrGK);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
