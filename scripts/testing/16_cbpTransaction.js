// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getRC, getGMM, getROM, getFT, getGMMKeeper, } = require("./boox");
const { increaseTime, parseUnits, Bytes32Zero, now, } = require("./utils");
const { getLatestSeqOfMotion, allSupportMotion, parseMotion } = require("./gmm");
const { getLatestShare } = require("./ros");
const { parseOption, parseOracle, parseSwap } = require("./roo");
const { royaltyTest } = require("./rc");

async function main() {

    console.log('********************************');
    console.log('**       CBP Transactions     **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const ft = await getFT();
    const gk = await getGK();
    const rom = await getROM();
    const gmm = await getGMM();
    const gmmKeeper = await getGMMKeeper();

    // ==== Motion for Mint CBP to DAO ====

    // selector of function mint(): 40c10f19
    let selector = ethers.utils.id("mint(address,uint256)").substring(0, 10);
    let firstInput = gk.address.substring(2).padStart(64, "0"); 
    let secondInput = parseUnits('88', 18).padStart(64, '0');
    let payload = selector + firstInput + secondInput;

    await expect(gk.connect(signers[2]).createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1)).revertedWith("GMMK: no right");
    console.log("Passed Access Control Test for gk.createActionOfGM(). \n");

    let tx = await gk.createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 99n, "gk.createActionOfGM().");

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log("Passed Event Test for gmm.CreateMotion(). \n");

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Approve Action");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(1);
    expect(motion.head.executor).to.equal(1);
    expect(motion.body.state).to.equal("Created");

    console.log("Passed Result Verify Test for gk.createActionOfGM(). \n");

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    motion = parseMotion(await gmm.getMotion(seqOfMotion));
    expect(motion.body.state).to.equal("Proposed");

    console.log("Passed Result Verify Test for gk.proposeMotionToGeneralMeeting(). \n");
    
    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    console.log("Passed Result Verify Test for gk.castVote() & gk.voteCounting(). \n");

    // ---- Mint CBP to GK ----

    // console.log('CBP balance of GK before:', ethers.utils.formatUnits((await rc.balanceOf(gk.address)).toString(), 18), '\n');

    let balaBefore = BigInt(await rc.balanceOf(gk.address));

    tx = await gk.execActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), seqOfMotion);

    // await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.execActionOfGM().");

    await expect(tx).to.emit(gmmKeeper, "ExecAction").withArgs(rc.address, BigNumber.from(0), payload, BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log("Passed Event Test for gmmKeeper.ExecAction(). \n");

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log("Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(gk, "ExecAction");
    console.log("Passed Event Test for gk.ExecAction(). \n");

    let balaAfter = BigInt(await rc.balanceOf(gk.address));

    expect(balaAfter - balaBefore).to.equal(ethers.utils.parseUnits("88.00036", 18));

    console.log("Passed Result Verify Test for CBP Mint. \n");

    // ==== Motion for Transfer CBP to Fuel Tank ====

    let today = await now();
    let expireDate = today + 86400 * 3;
    
    tx = await gk.proposeToTransferFund(false, ft.address, true, ethers.utils.parseUnits("88", 18) , expireDate, 9, 1);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 99n, "gk.proposeToTransferFund().");

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log("Passed Event Test for gmm.CreateMotion(). \n");

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "ProposeMotionToGeneralMeeting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log("Passed Event Test for gmm.ProposeMotionToGeneralMeeting(). \n");
    
    motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Transfer Fund");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(1);
    expect(motion.head.executor).to.equal(1);
    expect(motion.body.state).to.equal("Proposed");

    console.log("Passed Result Verify Test for gk.proposeToTransferFund(). \n");

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);
    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    console.log("Passed Result Verify Test for gk.castVote() & gk.voteCounting(). \n");

    // ---- Transfer CBP to Fuel Tank ----

    balaBefore = BigInt(await rc.balanceOf(ft.address));

    tx = await gk.transferFund(false, ft.address, true, ethers.utils.parseUnits("88", 18), expireDate, seqOfMotion);

    // await royaltyTest(rc.address, signers[0].address, gk.address, tx, 76n, "gk.transferFund().");
    
    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log("Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(gmmKeeper, "TransferFund").withArgs(ft.address, true, ethers.utils.parseUnits("88", 18), BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log("Passed Event Test for gmmKeeper.TransferFund(). \n");

    await expect(tx).to.emit(rc, "Transfer").withArgs(gk.address, ft.address, ethers.utils.parseUnits("88", 18));
    console.log("Passed Event Test for rc.Transfer(). \n");

    balaAfter = BigInt(await rc.balanceOf(ft.address));

    expect(balaAfter - balaBefore).to.equal(ethers.utils.parseUnits("88", 18));
    console.log("Passed Result Verify Test for gk.transferFund(). \n");

    // ==== User-3 refuel gas from Fuel Tank ====
    
    balaBefore = BigInt(await rc.balanceOf(signers[3].address));

    tx = await ft.connect(signers[3]).refuel({value: ethers.utils.parseUnits("80", 18)});

    await expect(tx).to.emit(ft, "Refuel").withArgs(signers[3].address, ethers.utils.parseUnits("80", 18), ethers.utils.parseUnits("80", 18));
    console.log("Passed Event Test for ft.Refuel(). \n");

    await expect(tx).to.emit(rc, "Transfer").withArgs(ft.address, signers[3].address, ethers.utils.parseUnits("80", 18));
    console.log("Passed Event Test for rc.Transfer(). \n");

    balaAfter = BigInt(await rc.balanceOf(signers[3].address));

    expect(balaAfter - balaBefore).to.equal(ethers.utils.parseUnits("80", 18));
    console.log("Passed Result Verify Test for ft.refuel(). \n");

    // ==== Pickup Income 80 ETH from Fuel Tank ====

    // ---- Motion for Pickup Income ----

    // selector of function withdrawIncome(uint256): 9273bbb6
    selector = ethers.utils.id("withdrawIncome(uint256)").substring(0, 10);
    firstInput = parseUnits("80", 18).padStart(64, '0');  // 80 ETH
    payload = selector + firstInput;

    await gk.createActionOfGM(9, [ft.address], [0], [payload], ethers.utils.id('9'+ft.address+payload), 1);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);   

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    // ---- Pickup Income ----

    balaBefore = BigInt(await ethers.provider.getBalance(ft.address));

    tx = await gk.execActionOfGM(9, [ft.address], [0], [payload], ethers.utils.id('9'+ft.address+payload), seqOfMotion)

    balaAfter = BigInt(await ethers.provider.getBalance(ft.address));

    expect(balaBefore - balaAfter).to.equal(ethers.utils.parseUnits("80", 18));
    console.log("Passed Result Verify Test for ft.withdrawIncome(). \n");
    
    // ==== Withdraw Fuel 8 CBP from Fuel Tank ====

    // ---- Motion for Withdraw Fuel ----

    // selector of function withdrawFuel(uint256): bbc446ac
    selector = ethers.utils.id("withdrawFuel(uint256)").substring(0, 10);
    firstInput = parseUnits("8", 18).padStart(64, '0');  // 8 CBP
    payload = selector + firstInput;

    await gk.createActionOfGM(9, [ft.address], [0], [payload], ethers.utils.id('9'+ft.address+payload), 1);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);
    
    // ---- Withdraw Fuel ----

    balaBefore = BigInt(await rc.balanceOf(ft.address));

    await gk.execActionOfGM(9, [ft.address], [0], [payload], ethers.utils.id('9'+ft.address+payload), seqOfMotion)

    balaAfter = BigInt(await rc.balanceOf(ft.address));

    expect(balaBefore - balaAfter).to.equal(ethers.utils.parseUnits("8", 18));
    console.log("Passed Result Verify Test for ft.withdrawFuel(). \n");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
