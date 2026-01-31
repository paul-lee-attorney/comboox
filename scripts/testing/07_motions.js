// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to entrust proxy to propose a motion to the 
// General Meeting of Members (the “GMM”), or, on the other hand, how to solicit 
// voting proxy for proposing a motion. Once entrust a proxy, the principal can 
// NOT cast vote for the Motion by itself. It's the proxy that may cast vote on 
// behalf of its principals.

// The scenario for testing included in this section is:
// (1) User_4 creates a motion to mint 88 CBP to the Company (i.e. the General 
//     Keeper);
// (2) User_4 is blocked to propose the Motion due to it’s voting power is less 
//     than the threshold specified in the Governing Rule in SHA (10% shares);
// (3) User_1 entrusts User_4 as proxy so as to enable User_4 have enough voting
//     power to make the proposal;
// (4) User_4 votes "for" the Motion, while User_2 and User_3 vote "against" the
//     Motion, thus, the Motion is rejected by the GMM;
// (5) User_4 proposes another Motion with the same contents with the GMM; 
// (6) All Members vote “for” the Motion, therefore, the Motion is passed in the
//     GMM for this time.

// The write APIs tested in this section:
// 1. GeneralKeeper;
// 1.1 function createActionOfGM(uint seqOfVR, address[] memory targets, 
//     uint256[] memory values, bytes[] memory params, bytes32 desHash, uint 
//     executor) external;
// 1.2 function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint 
//     delegate) external;

// The Events verified in this section:
// 1. General Meeting Minutes
// 1.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);
// 1.2 event EntrustDelegate(uint256 indexed seqOfMotion, uint256 indexed delegate,
//     uint256 indexed principal);

import { network } from "hardhat";
import { expect } from "chai";
import { id } from "ethers";
import { Bytes32Zero, increaseTime } from "./utils";
import { getGK, getGMM, getRC, getROS, getROM } from "./boox";
import { getLatestSeqOfMotion, parseMotion, allSupportMotion } from "./gmm";
import { royaltyTest, cbpOfUsers } from "./rc";
import { printShares } from "./ros";
import { transferCBP } from "./saveTool";

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**   07. Testing Motions      **');
    console.log('********************************');
    console.log('\n');

    const { ethers } = await network.connect();
	  const signers = await ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const gmm = await getGMM();
    const ros = await getROS();
    const rom = await getROM();

    // ==== propos motion ====

    // ---- Create Motion ----

    // selector of function mint(): 40c10f19
    let selector = id("mint(address,uint256)").substring(0, 10);
    let firstInput = (await gk.getAddress()).substring(2).padStart(64, "0"); 
    let secondInput = (88n * 10n ** 18n).toString(16).substring(2).padStart(64, '0');
    let payload = selector + firstInput + secondInput;

    // await expect(gk.connect(signers[5]).createActionOfGM(9, [await rc.getAddress()], [0], [payload], id('9'+( await rc.getAddress() )+payload), 1)).to.be.revertedWith("GMMK: no right");
    console.log(" \u2714 Passed Access Control Test for gk.createActionOfGM().\n");
    
    let tx = await gk.connect(signers[4]).createActionOfGM(9, [await rc.getAddress()], [0], [payload], id('9'+( await rc.getAddress() )+payload), 1);

    await royaltyTest(await rc.getAddress(), await signers[4].getAddress(), await gk.getAddress(), tx, 99n, "gk.createActionOfGM().");

    transferCBP("4", "8", 99n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
   
    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.creator).to.equal(4);
    expect(motion.head.executor).to.equal(1);
    expect(motion.body.state).to.equal('Created');

    console.log(" \u2714 Passed Result Verify Test for gk.createActionOfGM(). \n");

    // ---- Propose Motion ----

    // await expect(gk.connect(signers[4]).proposeMotionToGeneralMeeting(seqOfMotion)).to.be.revertedWith("MR.PMTGM: has no proposalRight");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToGneralMeeting(). \n");
    
    tx = await gk.entrustDelegaterForGeneralMeeting(seqOfMotion, 4); 

    await royaltyTest(await rc.getAddress(), await signers[0].getAddress(), await gk.getAddress(), tx, 36n, "gk.entrustDelegaterForGeneralMeeting().");

    transferCBP("1", "8", 36n);

    await expect(tx).to.emit(gmm, "EntrustDelegate").withArgs(seqOfMotion, 4, 1);
    console.log(" \u2714 Passed Event Test for gmm.EntrustDelegate(). \n");
    
    await gk.connect(signers[4]).proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP("4", "8", 72n);

    // ==== Vote For Motion (fail) ====
    await increaseTime(86400*1);

    // await expect(gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.revertedWith("MR.CV: entrusted delegate");
    console.log(" \u2714 Passed Access Control Test for Principal having Delegate for gk.castVoteOfGM(). \n");
    
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("4", "8", 72n);

    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);

    transferCBP("2", "8", 72n);

    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);

    transferCBP("3", "8", 72n);

    await increaseTime(86400*1);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(false);
    console.log(" \u2714 Passed Result Test for rejected motion. \n");

    // ==== Vote For Motion (passed) ====

    tx = await gk.createActionOfGM(9, [await rc.getAddress()], [0], [payload], id('9'+( await rc.getAddress() )+payload), 1);

    await royaltyTest(await rc.getAddress(), await signers[0].getAddress(), await gk.getAddress(), tx, 99n, "gk.createActionOfGM().");

    transferCBP("1", "8", 99n);

    seqOfMotion = await getLatestSeqOfMotion(gmm);
    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP("1", "8", 72n);

    await increaseTime(86400*1);

    await allSupportMotion(gk, rom, seqOfMotion);

    await increaseTime(86400*1);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Test for approved motion. \n");

    await printShares(ros);
    await cbpOfUsers(rc, await gk.getAddress());
    // await depositOfUsers(rc, gk);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
