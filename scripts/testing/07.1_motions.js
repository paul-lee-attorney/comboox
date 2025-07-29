// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// The scenario for testing included in this section is:
// (1) User_1, as GP, creates a motion to mint 88 CBP to the Fund (i.e. the Fund Keeper);
// (2) User_1 votes "for" the Motion to enable it passed;

// The write APIs tested in this section:
// 1. FundKeeper;
// 1.1 function createActionOfGM(uint seqOfVR, address[] memory targets, 
//     uint256[] memory values, bytes[] memory params, bytes32 desHash, uint 
//     executor) external;

// The Events verified in this section:
// 1. General Meeting Minutes
// 1.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);
// 1.2 event EntrustDelegate(uint256 indexed seqOfMotion, uint256 indexed delegate,
//     uint256 indexed principal);

const { expect } = require("chai");
const { Bytes32Zero, parseUnits } = require("./utils");
const { getGMM, getRC, getROS, getFK } = require("./boox");
const { getLatestSeqOfMotion, parseMotion } = require("./gmm");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { printShares } = require("./ros");
const { transferCBP } = require("./saveTool");

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**   07.1 Testing Motions     **');
    console.log('********************************');
    console.log('\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getFK();
    const gmm = await getGMM();
    const ros = await getROS();

    // ==== propos motion ====
    // ---- Create Motion ----

    // selector of function mint(): 40c10f19
    let selector = ethers.utils.id("mint(address,uint256)").substring(0, 10);
    let firstInput = gk.address.substring(2).padStart(64, "0"); 
    let secondInput = parseUnits('88', 18).padStart(64, '0');
    let payload = selector + firstInput + secondInput;

    await expect(gk.connect(signers[5]).createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1)).to.be.revertedWith("MR.memberExist: not");
    console.log(" \u2714 Passed Access Control Test for gk.createActionOfGM().\n");
    
    tx = await gk.createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 99n, "gk.createActionOfGM().");

    transferCBP("1", "8", 99n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
   
    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.creator).to.equal(1);
    expect(motion.head.executor).to.equal(1);
    expect(motion.body.state).to.equal('Created');

    console.log(" \u2714 Passed Result Verify Test for gk.createActionOfGM(). \n");

    // ---- Propose Motion ----

    await expect(gk.connect(signers[4]).proposeMotionToGeneralMeeting(seqOfMotion)).to.be.revertedWith("MR.PMTGM: has no proposalRight");
    console.log(" \u2714 Passed Access Control Test for gk.proposeMotionToGneralMeeting(). \n");
    
    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP("1", "8", 72n);

    // ==== Vote For Motion  ====
    
    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);

    transferCBP("1", "8", 72n);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(" \u2714 Passed Result Test for approved motion. \n");

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
