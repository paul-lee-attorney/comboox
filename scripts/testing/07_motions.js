// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { expect } = require("chai");

const { Bytes32Zero, increaseTime, parseUnits } = require("./utils");
const { getGK, getGMM, getRC } = require("./boox");
const { getLatestSeqOfMotion, parseMotion } = require("./gmm");

async function main() {

    console.log('********************************');
    console.log('**     Testing Motions        **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const gmm = await getGMM();
    
    // ==== propos motion ====

    // selector of function mint(): 40c10f19
    let selector = ethers.utils.id("mint(address,uint256)").substring(0, 10);
    let firstInput = gk.address.substring(2).padStart(64, "0"); 
    let secondInput = parseUnits('88', 18).padStart(64, '0');
    let payload = selector + firstInput + secondInput;

    await gk.connect(signers[4]).createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1);
    
    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));
    console.log('motion created:', motion, '\n');

    await expect(gk.connect(signers[4]).proposeMotionToGeneralMeeting(seqOfMotion)).to.be.revertedWith("MR.PMTGM: has no proposalRight") ;
    
    // User_1 entrust User_4 for propose and vote for seqOfMotion;
    await gk.entrustDelegaterForGeneralMeeting(seqOfMotion, 4); 

    // User_4 propose the motion with voting weight entrusted by User_1, so, 
    // this time, the propose action shall be successful.;
    await gk.connect(signers[4]).proposeMotionToGeneralMeeting(seqOfMotion);

    motion = parseMotion(await gmm.getMotion(seqOfMotion));
    console.log('motion proposed:', motion, '\n');    

    // ==== Vote For Motion (fail) ====
    await increaseTime(86400*1);

    await gk.connect(signers[4]).castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    await gk.connect(signers[1]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);
    await gk.connect(signers[3]).castVoteOfGM(seqOfMotion, 2, Bytes32Zero);

    await increaseTime(86400*1);

    await gk.voteCountingOfGM(seqOfMotion);
    console.log('Motion', seqOfMotion, 'is Passed ?', await gmm.isPassed(seqOfMotion), "\n");

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
    console.log('Motion', seqOfMotion, 'is Passed ?', await gmm.isPassed(seqOfMotion), "\n");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
