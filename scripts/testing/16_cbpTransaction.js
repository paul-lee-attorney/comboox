// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
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
//     amount of ETH;
// (6) User_1 creates and proposes a Motion to the GMM to pickup
//     80 ETH income back from the Fuel Tank;
// (7) After obtaining the voting approval from the GMM, User_1
//     executes the Motion to pickup the 80 ETH back from Fuel Tank
//     to General Keeper;
// (8) User_1 creates, proposes and executes Motion to withdraw
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
// 3.1 function refuel() external payable;
// 3.2 function withdrawIncome(uint amt) external;
// 3.3 function withdrawFuel(uint amt) external;

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

// 4. Registration Center
// 4.1 event Transfer(address indexed from, address indexed to, uint256 indexed value);

// 5. Fuel Tank
// 5.1 event Refuel (address indexed buyer, uint indexed amtOfEth, uint indexed amtOfCbp);

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getRC, getGMM, getROM, getFT, getGMMKeeper, } = require("./boox");
const { increaseTime, parseUnits, Bytes32Zero, now, } = require("./utils");
const { getLatestSeqOfMotion, allSupportMotion, parseMotion } = require("./gmm");
const { royaltyTest } = require("./rc");

async function main() {

    console.log('********************************');
    console.log('**     16. CBP Transactions   **');
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
    console.log(" \u2714 Passed Access Control Test for gk.createActionOfGM(). \n");

    let tx = await gk.createActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), 1);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 99n, "gk.createActionOfGM().");

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    let seqOfMotion = await getLatestSeqOfMotion(gmm);
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Approve Action");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(1);
    expect(motion.head.executor).to.equal(1);
    expect(motion.body.state).to.equal("Created");

    console.log(" \u2714 Passed Result Verify Test for gk.createActionOfGM(). \n");

    await gk.proposeMotionToGeneralMeeting(seqOfMotion);

    motion = parseMotion(await gmm.getMotion(seqOfMotion));
    expect(motion.body.state).to.equal("Proposed");

    console.log(" \u2714 Passed Result Verify Test for gk.proposeMotionToGeneralMeeting(). \n");
    
    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.castVote() & gk.voteCounting(). \n");

    // ---- Mint CBP to GK ----

    // console.log('CBP balance of GK before:', ethers.utils.formatUnits((await rc.balanceOf(gk.address)).toString(), 18), '\n');

    let balaBefore = BigInt(await rc.balanceOf(gk.address));

    tx = await gk.execActionOfGM(9, [rc.address], [0], [payload], ethers.utils.id('9'+rc.address+payload), seqOfMotion);

    // await royaltyTest(rc.address, signers[0].address, gk.address, tx, 36n, "gk.execActionOfGM().");

    await expect(tx).to.emit(gmmKeeper, "ExecAction").withArgs(rc.address, BigNumber.from(0), payload, BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmmKeeper.ExecAction(). \n");

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(gk, "ExecAction");
    console.log(" \u2714 Passed Event Test for gk.ExecAction(). \n");

    let balaAfter = BigInt(await rc.balanceOf(gk.address));

    expect(balaAfter - balaBefore).to.equal(ethers.utils.parseUnits("88.00036", 18));

    console.log(" \u2714 Passed Result Verify Test for CBP Mint. \n");

    // ==== Motion for Transfer CBP to Fuel Tank ====

    let today = await now();
    let expireDate = today + 86400 * 3;
    
    tx = await gk.proposeToTransferFund(false, ft.address, true, ethers.utils.parseUnits("88", 18) , expireDate, 9, 1);
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 99n, "gk.proposeToTransferFund().");

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "ProposeMotionToGeneralMeeting").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ProposeMotionToGeneralMeeting(). \n");
    
    motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Transfer Fund");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(1);
    expect(motion.head.executor).to.equal(1);
    expect(motion.body.state).to.equal("Proposed");

    console.log(" \u2714 Passed Result Verify Test for gk.proposeToTransferFund(). \n");

    await increaseTime(86400);

    await allSupportMotion(gk, rom, seqOfMotion);
    await gk.voteCountingOfGM(seqOfMotion);
    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.castVote() & gk.voteCounting(). \n");

    // ---- Transfer CBP to Fuel Tank ----

    balaBefore = BigInt(await rc.balanceOf(ft.address));

    tx = await gk.transferFund(false, ft.address, true, ethers.utils.parseUnits("88", 18), expireDate, seqOfMotion);

    // await royaltyTest(rc.address, signers[0].address, gk.address, tx, 76n, "gk.transferFund().");
    
    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(gmmKeeper, "TransferFund").withArgs(ft.address, true, ethers.utils.parseUnits("88", 18), BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmmKeeper.TransferFund(). \n");

    await expect(tx).to.emit(rc, "Transfer").withArgs(gk.address, ft.address, ethers.utils.parseUnits("88", 18));
    console.log(" \u2714 Passed Event Test for rc.Transfer(). \n");

    balaAfter = BigInt(await rc.balanceOf(ft.address));

    expect(balaAfter - balaBefore).to.equal(ethers.utils.parseUnits("88", 18));
    console.log(" \u2714 Passed Result Verify Test for gk.transferFund(). \n");

    // ==== User-3 refuel gas from Fuel Tank ====
    
    balaBefore = BigInt(await rc.balanceOf(signers[3].address));

    tx = await ft.connect(signers[3]).refuel({value: ethers.utils.parseUnits("80", 18)});

    await expect(tx).to.emit(ft, "Refuel").withArgs(signers[3].address, ethers.utils.parseUnits("80", 18), ethers.utils.parseUnits("80", 18));
    console.log(" \u2714 Passed Event Test for ft.Refuel(). \n");

    await expect(tx).to.emit(rc, "Transfer").withArgs(ft.address, signers[3].address, ethers.utils.parseUnits("80", 18));
    console.log(" \u2714 Passed Event Test for rc.Transfer(). \n");

    balaAfter = BigInt(await rc.balanceOf(signers[3].address));

    expect(balaAfter - balaBefore).to.equal(ethers.utils.parseUnits("80", 18));
    console.log(" \u2714 Passed Result Verify Test for ft.refuel(). \n");

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
    console.log(" \u2714 Passed Result Verify Test for ft.withdrawIncome(). \n");
    
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
    console.log(" \u2714 Passed Result Verify Test for ft.withdrawFuel(). \n");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
