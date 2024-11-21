// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows how to entrust proxy to propose a motion to the General Meeting,
// or, on the other hand, how to solicitate voting proxy for a motion. Once entrust a 
// proxy, the principal can NOT cast vote for the Motion directly by itself.  It's the 
// proxy that may cast vote on behalf of its principals.

// The scenario for testing include in this section:
// 1. User_4 created a motion to mint certain number of CBP to the Company (GeneralKeeper);
// 2. User_1 entrust User_4 as proxy so as to enable User_4 have enough voting weight to 
//    propose and vote for the said Motion;
// 3. User_4 votes "for" the Motion, while User_2 and User_3 vote "against" the Motion, thus
//    the Motion is rejectd by the General Meeting;
// 4. User_4 repropose another Motion with the same contents with the General Meeting;
// 5. All Members support the Motion, therefore, the Motion is passed by the General Meeting.

// The write APIs tested in this section:
// 1. GeneralKeeper;
// 1.1 function createActionOfGM(uint seqOfVR, address[] memory targets, uint256[] memory values,
//     bytes[] memory params, bytes32 desHash, uint executor) external;
// 1.2 function entrustDelegaterForGeneralMeeting(uint256 seqOfMotion, uint delegate) external;

const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { Bytes32Zero, increaseTime, parseUnits } = require("./utils");
const { getGK, getGMM, getRC } = require("./boox");
const { getLatestSeqOfMotion, parseMotion } = require("./gmm");
const { royaltyTest } = require("./rc");

async function main() {

    console.log('\n********************************');
    console.log('**   07. Testing Motions      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const gmm = await getGMM();
    
    // ==== propos motion ====

    // ---- Create Motion ----

    // selector of function mint(): 40c10f19
    let selector = ethers.utils.id("mint(address,uint256)").substring(0, 10);
    let firstInput = gk.address.substring(2).padStart(64, "0"); 
    let secondInput = parseUnits('88', 18).padStart(64, '0');
    let payload = selector + firstInput + secondInput;

    await expect(gk.connect(signers[5]).createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1)).to.be.revertedWith("GMMK: no right");
    console.log(" \u2714 Passed Access Control Test for gk.createActionOfGM().\n");
    
    tx = await gk.connect(signers[4]).createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1);

    await royaltyTest(rc.address, signers[4].address, gk.address, tx, 99n, "gk.createActionOfGM().");

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
   
    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.creator).to.equal(4);
    expect(motion.head.executor).to.equal(1);
    expect(motion.body.state).to.equal('Created');

    console.log(" \u2714 Passed Result Verify Test for gk.createActionOfGM(). \n");

    // ---- Propose Motion ----

    await expect(gk.connect(signers[4]).proposeMotionToGeneralMeeting(seqOfMotion)).to.be.revertedWith("MR.PMTGM: has no proposalRight");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToGneralMeeting(). \n");
    
    // User_1 entrust User_4 for propose and vote for seqOfMotion;
    tx = await gk.entrustDelegaterForGeneralMeeting(seqOfMotion, 4); 

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.entrustDelegaterForGeneralMeeting().");

    await expect(tx).to.emit(gmm, "EntrustDelegate").withArgs(seqOfMotion, BigNumber.from(4), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.EntrustDelegate(). \n");
    
    // User_4 propose the motion with voting weight entrusted by User_1, so, 
    // this time, the propose action shall be successful.;
    await gk.connect(signers[4]).proposeMotionToGeneralMeeting(seqOfMotion);

    // ==== Vote For Motion (fail) ====
    await increaseTime(86400*1);

    await expect(gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero)).to.revertedWith("MR.CV: entrusted delegate");
    console.log(" \u2714 Passed Access Control Test for Principal having Delegate for gk.castVoteOfGM(). \n");
    
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);

    await increaseTime(86400*1);

    await gk.voteCountingOfGM(seqOfMotion);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(false);
    console.log(" \u2714 Passed Result Test for rejected motion. \n");

    // ==== Vote For Motion (passed) ====

    await gk.createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1);
    
    seqOfMotion = await getLatestSeqOfMotion(gmm);
    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await increaseTime(86400*1);

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);
    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);

    await increaseTime(86400*1);

    await gk.voteCountingOfGM(seqOfMotion);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Test for approved motion. \n");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
