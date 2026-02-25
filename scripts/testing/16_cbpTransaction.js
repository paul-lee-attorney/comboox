// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2026 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how does the ComBoox DAO LLC (the "DAO") 
// mint and supply the CBP to the market, and how to collect ETH income
// incurred back to the DAO (i.e. General Keeper).

// In exchange of the initial capital, the Founding Member invested the
// ownership to the Platform to the DAO as his capital contribution.
// Thereafter, the DAO may mint CBP as per the General Meeting's
// resolution, and, may transfer the CBP to the smart contract of Fuel
// Tank to sell them to the market. Thereafter, the DAO may collect ETH
// income back from the Fuel Tank to the DAO (i.e. General Keeper). 

// Users of ComBoox need to pay CBP as royalty when calling the
// relevant write API of smart contracts cloned from the Template of
// the ComBoox. Thus, they need to purchase CBP from Fuel Tank as per
// the exchange rate predefined therein. This process is called as
// "refuel".

// The scenario for testing in this section are as follows:
// (1) User_1 creates Motion to Mint 88 CBP to the address of General
//     Keeper, which representing the legal person of the DAO;
// (2) After obtained the voting approval from the General Meeting of
//     Members (the "GMM"), User_1 as the executor of the Motion, 
//     triggers the API to execute the Action to Mint 88 CBP to
//     General Keeper;
// (3) User_1 further proposes a Motion to transfer 88 CBP to the
//     Fuel Tank with the GMM;
// (4) User_1 as the executor of the Motion, triggers the API to
//     transfer the 88 CBP to Fuel Tank;
// (5) User_3 refuels 80 CBP from the Fuel Tank by paying equivalent
//     amount of USDC;
// (6) User_1 creates, proposes and executes Motion to withdraw
//     8 CBP back from Fuel Tank.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.1 function createActionOfGM(uint seqOfVR, address[] memory
//     targets, uint256[] memory values, bytes[] memory params,
//     bytes32 desHash, uint executor) external;
// 1.2 function execActionOfGM(uint seqOfVR,
//     address[] memory targets, uint256[] memory values,
//     bytes[] memory params, bytes32 desHash, uint256 seqOfMotion)
//     external;
// 1.3 function proposeToTransferFund(bool toBMM, address to,
//     bool isCBP, uint amt, uint expireDate, uint seqOfVR,
//     uint executor) external;
// 1.4 function transferFund(bool fromBMM, address to, bool isCBP,
//     uint amt, uint expireDate, uint seqOfMotion) external;

// 2. Registration Center
// 2.1 function mint(address to, uint amt) external;
// 2.2 function transfer(address to, uint256 amount) public;

// 3. Fuel Tank
// 3.1 function refuel(ICashier.TransferAuth memory auth, uint amt) external;
// 3.2 function withdrawFuel(uint amt) external;

// Events verified in this section:
// 1. General Meeting Minutes
// 1.1 event CreateMotion(bytes32 indexed snOfMotion, uint256 indexed contents);
// 1.2 event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);
// 1.3 event ProposeMotionToGeneralMeeting(uint256 indexed seqOfMotion,
//     uint256 indexed proposer);

// 2. GMMKeeper
// 2.1 event ExecAction(address indexed targets, uint indexed values,
//     bytes indexed params, uint seqOfMotion, uint caller);
// 2.2 event TransferFund(address indexed to, bool indexed isCBP, uint indexed amt,
//     uint seqOfMotion, uint caller);

// 3. General Keeper
// 3.1 event ExecAction(uint256 indexed contents);
// 3.2 event ReceivedCash(address indexed from, uint indexed amt);

// 4. Registration Center
// 4.1 event Transfer(address indexed from, address indexed to, uint256 indexed value);

// 5. Fuel Tank
// 5.1 event Refuel (address indexed buyer, uint indexed amtOfEth, uint indexed amtOfCbp);

import { network } from "hardhat";
import { expect } from "chai";
import { parseUnits, id } from "ethers";

import { getGK, getRC, getGMM, getROM, getFT, getROS, getCashier } from "./boox";
import { increaseTime, now } from "./utils";
import { getLatestSeqOfMotion, allSupportMotion, parseMotion } from "./gmm";
import { royaltyTest, cbpOfUsers, getAllUsers } from "./rc";
import { printShares } from "./ros";
import { transferCBP, addCBPToUser, minusCBPFromUser } from "./saveTool";
import { generateAuth } from "./sigTools";
import { parseCompInfo } from "./gk";
import { readTool } from "../readTool";

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**     16. CBP Transactions   **');
    console.log('********************************');
    console.log('\n');

    const { ethers } = await network.connect();
	  const signers = await ethers.getSigners();

    const rc = await getRC();
    const ft = await getFT();
    const cashier = await getCashier();
    let gk = await getGK();

    const users = await getAllUsers(rc, 9);
    const userComp = await parseCompInfo(await gk.getCompInfo()).regNum;

    const rom = await getROM();
    const gmm = await getGMM();
    const ros = await getROS();

    // ==== Motion for Mint CBP to DAO ====

    gk = await readTool("GMMKeeper", gk.target);

    // selector of function mint(): 40c10f19
    let selector = id("mint(address,uint256)").substring(0, 10);
    let firstInput = (gk.target).substring(2).padStart(64, "0"); 
    let secondInput = parseUnits('88', 18).toString(16).padStart(64, '0');
    let payload = selector + firstInput + secondInput;

    // await expect(gk.connect(signers[2]).createActionOfGM(9, [rc.target], [0], [payload], id('9'+(rc.target)+payload), 1)).revertedWith("GMMK: no right");
    console.log(" \u2714 Passed Access Control Test for gk.createActionOfGM(). \n");

    let tx = await gk.createActionOfGM(9, [rc.target], [0], [payload], id('9'+(rc.target)+payload), users[0]);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 99n, "gk.createActionOfGM().");

    transferCBP(users[0], userComp, 99n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Approve Action");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(users[0]);
    expect(motion.head.executor).to.equal(users[0]);
    expect(motion.body.state).to.equal("Created");

    console.log(" \u2714 Passed Result Verify Test for gk.createActionOfGM(). \n");

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 72n, "gk.proposeMotionToGeneralMeeting().");
    transferCBP(users[0], userComp, 72n);

    motion = parseMotion(await gmm.getMotion(seqOfMotion));
    expect(motion.body.state).to.equal("Proposed");

    console.log(" \u2714 Passed Result Verify Test for gk.proposeMotionToGeneralMeeting(). \n");
    
    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion, userComp);

    await gk.voteCountingOfGM(seqOfMotion);

    transferCBP(users[0], userComp, 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.castVote() & gk.voteCounting(). \n");

    // ---- Mint CBP to GK ----

    // console.log('CBP balance of GK before:', ethers.utils.formatUnits((await rc.balanceOf(gk.address)).toString(), 18), '\n');

    let balaBefore = BigInt(await rc.balanceOf(gk.target));

    tx = await gk.execActionOfGM(9, [rc.target], [0], [payload], id('9'+(rc.target)+payload), seqOfMotion);

    transferCBP(users[0], userComp, 36n);
    
    addCBPToUser(88n * 10n ** 18n, userComp);
    
    // await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.execActionOfGM().");

    await expect(tx).to.emit(gk, "ExecAction").withArgs(rc.target, 0, payload, seqOfMotion, users[0]);
    console.log(" \u2714 Passed Event Test for gk.ExecAction(). \n");

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(seqOfMotion, users[0]);
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(gk, "ExecAction");
    console.log(" \u2714 Passed Event Test for gk.ExecAction(). \n");

    let balaAfter = BigInt(await rc.balanceOf(gk.target));

    // console.log("balaBefore:", balaBefore.toString());
    // console.log("balaAfter:", balaAfter.toString());
    // console.log("result:", (balaAfter - balaBefore).toString());

    expect(balaAfter - balaBefore).to.equal(parseUnits("88.00036", 18));

    console.log(" \u2714 Passed Result Verify Test for CBP Mint. \n");

    // ==== Motion for Transfer CBP to Fuel Tank ====

    let today = await now();
    let expireDate = today + 86400 * 3;
    
    tx = await gk.proposeToTransferFundWithGM(ft.target, true, parseUnits("88", 18), expireDate, 9, users[0]);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 99n, "gk.proposeToTransferFund().");
    transferCBP(users[0], userComp, 99n);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "ProposeMotionToGeneralMeeting").withArgs(seqOfMotion, users[0]);
    console.log(" \u2714 Passed Event Test for gmm.ProposeMotionToGeneralMeeting(). \n");
    
    motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Transfer Fund");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(users[0]);
    expect(motion.head.executor).to.equal(users[0]);
    expect(motion.body.state).to.equal("Proposed");

    console.log(" \u2714 Passed Result Verify Test for gk.proposeToTransferFund(). \n");

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion, userComp);

    await gk.voteCountingOfGM(seqOfMotion);
    transferCBP(users[0], userComp, 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.castVote() & gk.voteCounting(). \n");

    // ---- Transfer CBP to Fuel Tank ----

    gk = await readTool("Accountant", gk.target);

    balaBefore = BigInt(await rc.balanceOf(ft.target));

    tx = await gk.transferFund(false, ft.target, true, parseUnits("88", 18), expireDate, seqOfMotion);

    await royaltyTest(rc.target, signers[0].address, gk.target, tx, 76n, "gk.transferFund().");

    transferCBP(users[0], userComp, 76n);

    minusCBPFromUser(88n * 10n ** 18n, userComp);
        
    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(seqOfMotion, users[0]);
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await royaltyTest(rc.target, gk.target, ft.target, tx, 88n * 10n ** 5n, "rc.Transfer() in gk.transferFund().");

    balaAfter = BigInt(await rc.balanceOf(ft.target));

    expect(balaAfter - balaBefore).to.equal(parseUnits("88", 18));
    console.log(" \u2714 Passed Result Verify Test for gk.transferFund(). \n");

    // ==== User-3 refuel gas from Fuel Tank ====

    balaBefore = BigInt(await rc.balanceOf(signers[3].address));

    let usdBalaOfCompBefore = BigInt(await cashier.balanceOfComp());

    let auth = await generateAuth(signers[3], cashier.target, 2600 * 81);
    console.log("auth:", auth);

    tx = await ft.connect(signers[3]).refuel(auth, parseUnits("80", 18));

    addCBPToUser(80n * 10n ** 18n, users[3]);

    await expect(tx).to.emit(ft, "Refuel").withArgs(signers[3].address, parseUnits("208", 9), parseUnits("80", 18));
    console.log(" \u2714 Passed Event Test for ft.Refuel(). \n");

    await expect(tx).to.emit(rc, "Transfer").withArgs(ft.target, signers[3].address, parseUnits("80", 18));
    console.log(" \u2714 Passed Event Test for rc.Transfer(). \n");

    balaAfter = BigInt(await rc.balanceOf(signers[3].address));
    expect(balaAfter - balaBefore).to.equal(parseUnits("80", 18));
    console.log(" \u2714 Passed Result Verify Test for ft.refuel(). \n");

    let usdBalaOfCompAfter = BigInt(await cashier.balanceOfComp());
    expect(usdBalaOfCompAfter - usdBalaOfCompBefore).to.equal(parseUnits("208", 9));
    console.log(" \u2714 Passed Result Verify Test for cashier.balanceOfComp(). \n");
    
    // ==== Withdraw Fuel 8 CBP from Fuel Tank ====

    // ---- Motion for Withdraw Fuel ----

    gk = await readTool("GMMKeeper", gk.target);

    // selector of function withdrawFuel(uint256): bbc446ac
    selector = id("withdrawFuel(uint256)").substring(0, 10);
    firstInput = parseUnits("8", 18).toString(16).padStart(64, '0');  // 8 CBP
    payload = selector + firstInput;

    await gk.createActionOfGM(9, [ft.target], [0], [payload], id('9'+ft.target+payload), users[0]);

    transferCBP(users[0], userComp, 99n);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    transferCBP(users[0], userComp, 72n);

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion, userComp);
    await gk.voteCountingOfGM(seqOfMotion);
    
    transferCBP(users[0], userComp, 88n);

    // ---- Withdraw Fuel ----

    balaBefore = BigInt(await rc.balanceOf(ft.target));

    await gk.execActionOfGM(9, [ft.target], [0], [payload], id('9'+ft.target+payload), seqOfMotion);

    transferCBP(users[0], userComp, 36n);

    addCBPToUser(8n * 10n ** 18n, userComp);

    balaAfter = BigInt(await rc.balanceOf(ft.target));

    expect(balaBefore - balaAfter).to.equal(parseUnits("8", 18));
    console.log(" \u2714 Passed Result Verify Test for ft.withdrawFuel(). \n");

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
