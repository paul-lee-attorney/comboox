// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to distribute profits of the DAO, and how to 
// check USDC balance and pickup the same from the deposit account in Cashier.

// The scenario for testing in this section are as follows:
// 1. User_1 proposes a Motion to the General Meeting of Members (the "GMM") to 
//    distribute 5% of the total USDC of the DAO to Members as per the distribution
//    powers thereof;
// 2. Upon approval of the GMM, User_1 as the executor of the Motion, executes
//    the Motion to distribute the predefined amount of USDC to Members;
// 3. User_1 to User_6 as Members and Sellers of listed shares, query the balance
//    USDC in their deposit account and pickup the same from the Cashier.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.2 function createActionOfGM(uint seqOfVR, address[] memory targets, uint256[] memory values, 
//     bytes[] memory params, bytes32 desHash, uint executor) external;
// 1.3 function proposeMotionToGeneralMeeting(uint256 seqOfMotion) external;
// 1.4 function castVoteOfGM(uint256 seqOfMotion, uint attitude, bytes32 sigHash) external;
// 1.5 function voteCountingOfGM(uint256 seqOfMotion) external;
// 1.6 function execActionOfGM(uint seqOfVR, address[] memory targets, uint256[] memory values, 
//     bytes[] memory params, bytes32 desHash, uint256 seqOfMotion) external;

// 2. Cashier
// 2.1 function distributeUsd(uint amt) external;
// 2.2 function depositOfMine(uint user) external view returns(uint);
// 2.3 function pickupUsd() external; 

// Events verified in this section:
// 1. General Meeting Minutes
// 1.1 event ExecResolution(uint256 indexed seqOfMotion, uint256 indexed caller);

// 2. General Keeper
// 2.1  event ExecAction(uint256 indexed contents);

// 3. GMMKeeper
// 3.1  event ExecAction(uint256 indexed contents);

const { expect } = require("chai");
const { BigNumber, ethers } = require("ethers");

const { getRC, getGMM, getROS, getCashier, getUSDC, getFK, getROR, } = require("./boox");
const { increaseTime, now, Bytes32Zero } = require("./utils");
const { getLatestSeqOfMotion, parseMotion, } = require("./gmm");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { printShares, parseShare } = require("./ros");
const { transferCBP } = require("./saveTool");
const { parseRequest } = require("./ror");
const { parseDrop } = require("./cashier");

async function main() {

    console.log('\n');
    console.log('**********************************');
    console.log('**  18.1 Redeem & Distribution  **');
    console.log('**********************************');
    console.log('\n');

	  const signers = await hre.ethers.getSigners();

    const cashier = await getCashier();
    const usdc = await getUSDC();
    const rc = await getRC();
    const gk = await getFK();
    const gmm = await getGMM();
    const ros = await getROS();
    const ror = await getROR();

    // ==== Redeemable Class Setting ====

    // ---- Add Redeemable Class ----

    await expect(gk.connect(signers[1]).addRedeemableClass(3)).to.be.revertedWith("FundRORK: not GP or Manager");
    console.log(" \u2714 Passed Access Control Test for gk.addRedeemeableClass(). \n");
    
    let tx = await gk.addRedeemableClass(3);
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.addRedeemableClass().");
    transferCBP("1", "8", 18n);
    
    await expect(tx).to.emit(ror, "AddRedeemableClass").withArgs(BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for ror.AddRedeemableClass(). \n");

    let res = await ror.isRedeemable(3);

    expect(res).to.equal(true);
    console.log(" \u2714 Passed Result Test for ror.AddRedeemableClass(). \n");

    // ---- Remove Redeemable Class ----

    await expect(gk.connect(signers[1]).removeRedeemableClass(3)).to.be.revertedWith("FundRORK: not GP or Manager");
    console.log(" \u2714 Passed Access Control Test for gk.removeRedeemeableClass(). \n");

    tx = await gk.removeRedeemableClass(3);
    
    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.removeRedeemableClass().");
    transferCBP("1", "8", 18n);
    
    await expect(tx).to.emit(ror, "RemoveRedeemableClass").withArgs(BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for ror.AddRedeemableClass(). \n");

    res = await ror.isRedeemable(3);

    expect(res).to.equal(false);
    console.log(" \u2714 Passed Result Test for ror.RemoveRedeemableClass(). \n");

    // ---- Add Class_3 again ----

    tx = await gk.addRedeemableClass(3);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.addRedeemableClass().");
    transferCBP("1", "8", 18n);

    res = await ror.isRedeemable(3);

    expect(res).to.equal(true);
    console.log(" \u2714 Passed Result Test for ror.AddRedeemableClass(). \n");

    // ==== NAV updates ====

    await expect(gk.connect(signers[1]).updateNavPrice(3, 2.3 * 10 ** 4)).to.be.revertedWith("FundRORK: not GP or Manager");
    console.log(" \u2714 Passed Access Control Test for gk.updateNavPrice(). \n");

    await expect(gk.updateNavPrice(3, 0)).to.be.revertedWith("FundRORK: zero navPrice");
    console.log(" \u2714 Passed Zero Price Test for gk.updateNavPrice(). \n");
  
    tx = await gk.updateNavPrice(3, 2.5 * 10 ** 4);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.udpateNavPrice().");
    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(ror, "UpdateNavPrice").withArgs(BigNumber.from(3), BigNumber.from(2.5 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ror.updateNavPrice(). \n");

    res = await ror.getInfoOfClass(3);

    expect(res.navPrice).to.equal(BigNumber.from(2.5 * 10 ** 4));
    console.log(" \u2714 Passed Result Test for ror.updateNavPrice(). \n");

    // ==== Redemption Request ====

    // ---- 1st request ---- 

    await expect(gk.requestForRedemption(3, 100 * 10 ** 4)).to.be.revertedWith("FundRORK: not class member");
    console.log(" \u2714 Passed Access Control Test for gk.requestForRedemption(). \n");

    tx = await gk.connect(signers[1]).requestForRedemption(3, 100 * 10 ** 4);

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 88n, "gk.requestForRedemption().");
    transferCBP("2", "8", 88n);

    await expect(tx).to.emit(ror, "RequestForRedemption").withArgs(BigNumber.from(3), BigNumber.from(4), BigNumber.from(100 * 10 ** 4), BigNumber.from(2.5 * 10 ** 6));
    console.log(" \u2714 Passed Event Test for ror.requestForRedemption(). \n");

    // ---- Util BigNumber to Number ----
    const big2Num = (big) => Number(big.toString());
    const list2Num = (list) => list.map(v => big2Num(v));

    res = ethers.utils.formatUnits((await ror.getInfoOfClass(3)).value.toString(), 4);
    expect(res).to.equal('250.0');

    let list = list2Num(await ror.getPacksList(3));
    console.log('pack list of class 3:', list, '\n');

    res = ethers.utils.formatUnits((await ror.getInfoOfPack(3, big2Num(list[list.length - 1]))).value.toString(), 4);
    expect(res).to.equal('250.0');
    
    let request = parseRequest(await ror.getRequest(3, big2Num(list[list.length - 1]), 4));
    console.log('request:', request);

    expect(request.class).to.equal(3);
    expect(request.seqOfShare).to.equal(4);
    expect(request.navPrice).to.equal(2.5);
    expect(request.shareholder).to.equal(2);
    expect(request.paid).to.equal(100);
    expect(request.value).to.equal(250);

    console.log(" \u2714 Passed Result Test for ror.requestForRedemption(). Request_1 \n");

    // ---- 2nd Request ----

    tx = await gk.connect(signers[3]).requestForRedemption(3, 200 * 10 ** 4);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 88n, "gk.requestForRedemption().");
    transferCBP("3", "8", 88n);

    await expect(tx).to.emit(ror, "RequestForRedemption").withArgs(BigNumber.from(3), BigNumber.from(5), BigNumber.from(200 * 10 ** 4), BigNumber.from(5 * 10 ** 6));
    console.log(" \u2714 Passed Event Test for ror.requestForRedemption(). \n");

    res = ethers.utils.formatUnits((await ror.getInfoOfClass(3)).value.toString(), 4);
    expect(res).to.equal('750.0');

    list = list2Num(await ror.getPacksList(3));
    console.log('pack list of class 3:', list);

    res = ethers.utils.formatUnits((await ror.getInfoOfPack(3, big2Num(list[list.length - 1]))).value.toString(), 4);
    expect(res).to.equal('750.0');
    
    request = parseRequest(await ror.getRequest(3, big2Num(list[list.length - 1]), 5));
    console.log('request:', request);

    expect(request.class).to.equal(3);
    expect(request.seqOfShare).to.equal(5);
    expect(request.navPrice).to.equal(2.5);
    expect(request.shareholder).to.equal(3);
    expect(request.paid).to.equal(200);
    expect(request.value).to.equal(500);

    console.log(" \u2714 Passed Result Test for ror.requestForRedemption(). Request_2 \n");

    // ---- Time Increase ----

    await increaseTime(86400);

    // ==== update NAV ====

    tx = await gk.updateNavPrice(3, 2.8 * 10 ** 4);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.udpateNavPrice().");
    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(ror, "UpdateNavPrice").withArgs(BigNumber.from(3), BigNumber.from(2.8 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ror.updateNavPrice(). \n");

    res = await ror.getInfoOfClass(3);

    expect(res.navPrice).to.equal(2.8 * 10 ** 4);
    console.log(" \u2714 Passed Result Test for ror.updateNavPrice(). \n");    

    // ---- 3rd request ---- 

    tx = await gk.connect(signers[1]).requestForRedemption(3, 100 * 10 ** 4);

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 88n, "gk.requestForRedemption().");
    transferCBP("2", "8", 88n);

    await expect(tx).to.emit(ror, "RequestForRedemption").withArgs(BigNumber.from(3), BigNumber.from(4), BigNumber.from(100 * 10 ** 4), BigNumber.from(2.8 * 10 ** 6));
    console.log(" \u2714 Passed Event Test for ror.requestForRedemption(). \n");

    res = ethers.utils.formatUnits((await ror.getInfoOfClass(3)).value.toString(), 4);
    expect(res).to.equal('1030.0');

    list = list2Num(await ror.getPacksList(3));
    console.log('pack list of class 3:', list);

    res = ethers.utils.formatUnits((await ror.getInfoOfPack(3, big2Num(list[list.length - 1]))).value.toString(), 4);
    expect(res).to.equal('280.0');
    
    request = parseRequest(await ror.getRequest(3, big2Num(list[list.length - 1]), 4));
    console.log('request:', request);

    expect(request.class).to.equal(3);
    expect(request.seqOfShare).to.equal(4);
    expect(request.navPrice).to.equal(2.8);
    expect(request.shareholder).to.equal(2);
    expect(request.paid).to.equal(100);
    expect(request.value).to.equal(280);

    console.log(" \u2714 Passed Result Test for ror.requestForRedemption(). request_3 \n");

    // ---- 4th Request ----

    tx = await gk.connect(signers[3]).requestForRedemption(3, 200 * 10 ** 4);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 88n, "gk.requestForRedemption().");
    transferCBP("3", "8", 88n);

    await expect(tx).to.emit(ror, "RequestForRedemption").withArgs(BigNumber.from(3), BigNumber.from(5), BigNumber.from(200 * 10 ** 4), BigNumber.from(5.6 * 10 ** 6));
    console.log(" \u2714 Passed Event Test for ror.requestForRedemption(). \n");

    res = ethers.utils.formatUnits((await ror.getInfoOfClass(3)).value.toString(),4);
    expect(res).to.equal('1590.0')

    list = list2Num(await ror.getPacksList(3));
    console.log('pack list of class 3:', list);

    res = ethers.utils.formatUnits((await ror.getInfoOfPack(3, big2Num(list[list.length - 1]))).value.toString(), 4);
    expect(res).to.equal('840.0');
    
    request = parseRequest(await ror.getRequest(3, big2Num(list[list.length - 1]), 5));
    console.log('request:', request);

    expect(request.class).to.equal(3);
    expect(request.seqOfShare).to.equal(5);
    expect(request.navPrice).to.equal(2.8);
    expect(request.shareholder).to.equal(3);
    expect(request.paid).to.equal(200);
    expect(request.value).to.equal(560);

    console.log(" \u2714 Passed Result Test for ror.requestForRedemption(). request_4 \n");

    // ==== Redeem For Request 1 & 2 ====

    await expect(gk.connect(signers[1]).redeem(3, big2Num(list[list.length - 2]))).to.be.revertedWith("FundRORK: not GP or Manager");
    console.log(" \u2714 Passed Access Control Test for gk.redeem(). \n");

    let bala_2_before = big2Num(await cashier.depositOfMine(2));
    let bala_3_before = big2Num(await cashier.depositOfMine(3));

    res = await ror.getInfoOfPack(3, big2Num(list[list.length - 2]));
    expect(ethers.utils.formatUnits(res.value.toString(), 4)).to.equal('750.0');

    tx = await gk.redeem(3, big2Num(list[list.length - 2]));

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.redeem().");
    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(ror, "RedeemClass").withArgs(BigNumber.from(3), res.paid, res.value);
    console.log(" \u2714 Passed Event Test for ror.RedeemClass(). \n");

    let bala_2_after = big2Num(await cashier.depositOfMine(2));
    expect(ethers.utils.formatUnits(bala_2_after.toString(), 6)).to.equal('250.0');

    let bala_3_after = big2Num(await cashier.depositOfMine(3));
    expect(ethers.utils.formatUnits(bala_3_after.toString(), 6)).to.equal('500.0');

    let share_4_after = parseShare(await ros.getShare(4));
    expect(share_4_after.body.paid).to.equal('9,900.0');
    expect(share_4_after.body.par).to.equal('9,900.0');
    expect(share_4_after.body.cleanPaid).to.equal('9,800.0');

    let share_5_after = parseShare(await ros.getShare(5));
    expect(share_5_after.body.paid).to.equal('9,800.0');
    expect(share_5_after.body.par).to.equal('9,800.0');
    expect(share_5_after.body.cleanPaid).to.equal('9,600.0');

    expect(bala_2_after - bala_2_before).to.equal(250 * 10 ** 6);
    expect(bala_3_after - bala_3_before).to.equal(500 * 10 ** 6);
    
    console.log(" \u2714 Passed Result Test for ror.redeem(). \n");

    // ==== Redeem For Request 3 & 4 ====

    await expect(gk.connect(signers[1]).redeem(3, big2Num(list[list.length - 1]))).to.be.revertedWith("FundRORK: not GP or Manager");
    console.log(" \u2714 Passed Access Control Test for gk.redeem(). \n");

    bala_2_before = big2Num(await cashier.depositOfMine(2));
    bala_3_before = big2Num(await cashier.depositOfMine(3));

    res = await ror.getInfoOfPack(3, big2Num(list[list.length - 1]));
    expect(ethers.utils.formatUnits(res.value.toString(), 4)).to.equal('840.0');

    tx = await gk.redeem(3, big2Num(list[list.length - 1]));

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.redeem().");
    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(ror, "RedeemClass").withArgs(BigNumber.from(3), res.paid, res.value);
    console.log(" \u2714 Passed Event Test for ror.RedeemClass(). \n");

    bala_2_after = big2Num(await cashier.depositOfMine(2));
    expect(ethers.utils.formatUnits(bala_2_after.toString(), 6)).to.equal('530.0');

    bala_3_after = big2Num(await cashier.depositOfMine(3));
    expect(ethers.utils.formatUnits(bala_3_after.toString(), 6)).to.equal('1060.0');

    share_4_after = parseShare(await ros.getShare(4));
    expect(share_4_after.body.paid).to.equal('9,800.0');
    expect(share_4_after.body.par).to.equal('9,800.0');
    expect(share_4_after.body.cleanPaid).to.equal('9,800.0');

    share_5_after = parseShare(await ros.getShare(5));
    expect(share_5_after.body.paid).to.equal('9,600.0');
    expect(share_5_after.body.par).to.equal('9,600.0');
    expect(share_5_after.body.cleanPaid).to.equal('9,600.0');

    expect(bala_2_after - bala_2_before).to.equal(280 * 10 ** 6);
    expect(bala_3_after - bala_3_before).to.equal(560 * 10 ** 6);
    console.log(" \u2714 Passed Result Test for ror.redeem(). \n");

    // ==== Propose To Distribute Profits ====

    const seqOfVR = 9n;
    let seqOfDR = 1280n;
    const executor = await rc.getMyUserNo();

    await usdc.transfer(cashier.address, 200000 * 10 ** 6);
    let distAmt = 10000 * 10 ** 6;

    let today = await now();
    let expireDate = today + 86400 * 60;

    tx = await gk.proposeToDistributeUsd(distAmt, expireDate, seqOfVR, seqOfDR, 0, executor);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 68n, "gk.proposeToDistributeUsd().");
    transferCBP("1", "8", 68n);

    let seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
    
    let motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Distribute Profits");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(1);
    expect(motion.body.proposer).to.equal(1);

    console.log(" \u2714 Passed Result Verify Test for gk.proposeToDistributeUsd(). \n");

    // ==== Vote for Distribution Motion ====

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    transferCBP("1", "8", 72n);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(' \u2714 Passed Result Verify Test for motion voting. \n');

    // ==== Distribute Profits ====
    await increaseTime(86400 * 30);

    await expect(gk.connect(signers[1]).distributeProfits(distAmt, expireDate, seqOfDR, seqOfMotion)).to.be.revertedWith("Accountant: not GP");
    console.log(" \u2714 Passed Access Control Test for gk.distributeProfits(). \n");

    bala_2_before = big2Num(await cashier.depositOfMine(2));
    bala_3_before = big2Num(await cashier.depositOfMine(3));

    tx = await gk.distributeProfits(distAmt, expireDate, seqOfDR, seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.distributeProfits().");
    transferCBP("1", "8", 18n);

    bala_2_after = big2Num(await cashier.depositOfMine(2));
    bala_3_after = big2Num(await cashier.depositOfMine(3));

    console.log('profits_2:', ethers.utils.formatUnits((bala_2_after - bala_2_before).toString(), 6));
    console.log('profits_3:', ethers.utils.formatUnits((bala_3_after - bala_3_before).toString(), 6));

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(BigNumber.from(seqOfMotion), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(cashier, "DistrProfits").withArgs(distAmt, seqOfDR, 1);
    console.log(" \u2714 Passed Event Test for cashier.DistrProfits(). \n");

    // res = await cashier.getDropsOfStream(1);
    // console.log('DropsOfStream_1:', res);

    // ==== Propose To Distribute Income ====

    distAmt = 130000 * 10 ** 6;

    today = await now();
    expireDate = today + 86400 * 60;
    seqOfDR = 1281n;

    tx = await gk.proposeToDistributeUsd(distAmt, expireDate, seqOfVR, seqOfDR, executor, executor);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 68n, "gk.proposeToDistributeUsd().");
    transferCBP("1", "8", 68n);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
    
    motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Distribute Profits");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(1);
    expect(motion.body.proposer).to.equal(1);

    console.log(" \u2714 Passed Result Verify Test for gk.proposeToDistributeUsd(). \n");

    // ==== Vote for Distribution Motion ====

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    transferCBP("1", "8", 72n);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(' \u2714 Passed Result Verify Test for motion voting. \n');

    // await printShares(ros);

    // ==== Distribute Income ====
    await increaseTime(86400 * 30);

    await expect(gk.connect(signers[1]).distributeIncome(distAmt, expireDate, seqOfDR, 1, seqOfMotion)).to.be.revertedWith("Accountant: not GP");
    console.log(" \u2714 Passed Access Control Test for gk.distributeIncome(). \n");

    bala_2_before = big2Num(await cashier.depositOfMine(2));
    console.log('bala_2_before:', bala_2_before);
    bala_3_before = big2Num(await cashier.depositOfMine(3));
    console.log('bala_3_before:', bala_3_before);

    tx = await gk.distributeIncome(distAmt, expireDate, seqOfDR, 1, seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.distributeIncome().");
    transferCBP("1", "8", 18n);

    const calDistrOfClass = async (seqOfClass, rate) => {

      let seaInfo = parseDrop(await cashier.getSeaInfo(seqOfClass));
      // console.log('seaInfo', seqOfClass, ':', seaInfo);

      let initSeaInfo = parseDrop(await cashier.getInitSeaInfo(seqOfClass));
      // console.log('initSeaInfo', seqOfClass,':', initSeaInfo);

      let income = initSeaInfo.principal * (seaInfo.distrDate - initSeaInfo.distrDate) * rate / (365 * 86400 * 10000);
      // console.log('incomeOfClass', seqOfClass, ':', income);

      let distr = initSeaInfo.principal + income;
      // console.log('distrOfClass', seqOfClass, ':', distr);

      return distr;
    }

    let distr = await calDistrOfClass(2, 500);
    distr += await calDistrOfClass(3, 700);
    distr += await calDistrOfClass(4, 1000);

    console.log('sum of distr for Classes 2, 3 & 4 :', ethers.utils.formatUnits(Math.floor(distr).toString(), 6));

    bala_2_after = big2Num(await cashier.depositOfMine(2));
    bala_3_after = big2Num(await cashier.depositOfMine(3));

    console.log('profits_2:', ethers.utils.formatUnits((bala_2_after - bala_2_before).toString(), 6));
    console.log('profits_3:', ethers.utils.formatUnits((bala_3_after - bala_3_before).toString(), 6));
    console.log('total distr of User 2 & 3:', ethers.utils.formatUnits((bala_2_after + bala_3_after - bala_2_before - bala_3_before).toString(), 6));

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(seqOfMotion, 1);
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(cashier, "DistrIncome").withArgs(distAmt, seqOfDR, executor, 2);
    console.log(" \u2714 Passed Event Test for cashier.DistrIncome(). \n");

    // ==== Propose To Distribute Income ====

    distAmt = 50000 * 10 ** 6;

    today = await now();
    expireDate = today + 86400 * 60;
    seqOfDR = 1282n;

    tx = await gk.proposeToDistributeUsd(distAmt, expireDate, seqOfVR, seqOfDR, executor, executor);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 68n, "gk.proposeToDistributeUsd().");
    transferCBP("1", "8", 68n);

    seqOfMotion = await getLatestSeqOfMotion(gmm);

    await expect(tx).to.emit(gmm, "CreateMotion");
    console.log(" \u2714 Passed Event Test for gmm.CreateMotion(). \n");
    
    motion = parseMotion(await gmm.getMotion(seqOfMotion));

    expect(motion.head.typeOfMotion).to.equal("Distribute Profits");
    expect(motion.head.seqOfVR).to.equal(9);
    expect(motion.head.creator).to.equal(1);
    expect(motion.body.proposer).to.equal(1);

    console.log(" \u2714 Passed Result Verify Test for gk.proposeToDistributeUsd(). \n");

    // ==== Vote for Distribution Motion ====

    await gk.castVoteOfGM(seqOfMotion, 1, Bytes32Zero);
    transferCBP("1", "8", 72n);

    await increaseTime(86400);

    await gk.voteCountingOfGM(seqOfMotion);
    transferCBP("1", "8", 88n);

    expect(await gmm.isPassed(seqOfMotion)).to.equal(true);
    console.log(' \u2714 Passed Result Verify Test for motion voting. \n');

    await printShares(ros);

    // ==== Distribute Income ====
    await increaseTime(86400 * 30);

    await expect(gk.connect(signers[1]).distributeIncome(distAmt, expireDate, seqOfDR, 1, seqOfMotion)).to.be.revertedWith("Accountant: not GP");
    console.log(" \u2714 Passed Access Control Test for gk.distributeIncome(). \n");

    let bala_1_before = big2Num(await cashier.depositOfMine(1));
    console.log('bala_1_before:', bala_1_before);
    bala_2_before = big2Num(await cashier.depositOfMine(2));
    console.log('bala_2_before:', bala_2_before);
    bala_3_before = big2Num(await cashier.depositOfMine(3));
    console.log('bala_3_before:', bala_3_before);

    tx = await gk.distributeIncome(distAmt, expireDate, seqOfDR, 1, seqOfMotion);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.distributeIncome().");
    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(gmm, "ExecResolution").withArgs(seqOfMotion, 1);
    console.log(" \u2714 Passed Event Test for gmm.ExecResolution(). \n");

    await expect(tx).to.emit(cashier, "DistrIncome").withArgs(distAmt, seqOfDR, executor, 3);
    console.log(" \u2714 Passed Event Test for cashier.DistrIncome(). \n");

    let initSeaInfo = parseDrop(await cashier.getInitSeaInfo(5));
    // console.log('initSeaInfo_5:', initSeaInfo);

    let seaInfo = parseDrop(await cashier.getSeaInfo(5));
    // console.log('seaInfo_5:', seaInfo);

    let threshold = initSeaInfo.principal * (seaInfo.distrDate - initSeaInfo.distrDate) * 8 / (100 * 365 * 86400) + initSeaInfo.principal;
    // console.log('threshold:', threshold);

    let hurdle = initSeaInfo.principal * (seaInfo.distrDate - initSeaInfo.distrDate) * 2 / (100 * 365 * 86400);
    // console.log('hurdle:', hurdle);

    let carry = hurdle / 4;
    // console.log('carry-1:', carry);

    let exceed = (distAmt - threshold - hurdle - carry) / 5;
    // console.log('exceed:', exceed);

    carry += exceed * 4;
    console.log('carry-2:', carry);

    let bala_1_after = big2Num(await cashier.depositOfMine(1));
    bala_2_after = big2Num(await cashier.depositOfMine(2));
    bala_3_after = big2Num(await cashier.depositOfMine(3));

    console.log('profits_1:', ethers.utils.formatUnits((bala_1_after - bala_1_before).toString(), 6));
    console.log('profits_2:', ethers.utils.formatUnits((bala_2_after - bala_2_before).toString(), 6));
    console.log('profits_3:', ethers.utils.formatUnits((bala_3_after - bala_3_before).toString(), 6));

    let islandInfo = parseDrop(await cashier.getIslandInfo(5, 3));
    console.log('islandInfo_5_3:', islandInfo);

    res = await cashier.getDropsOfStream(3);
    console.log('DropsOfStream_3:', res);

    res = await cashier.getGulfInfo(5);
    console.log('GulfInfo_5:', res);

    res = await cashier.getSeaInfo(5);
    console.log('SeaInfo_5:', res);

    res = await cashier.getInitSeaInfo(5);
    console.log('InitSeaInfo_5:', res);

    // ==== Pickup Deposits ====

    for (let i=0; i<4; i++) {

      if (i == 2) continue;

      const userNo = await rc.connect(signers[i]).getMyUserNo();
      const depo = await cashier.connect(signers[i]).depositOfMine(userNo);

      let balaBefore = await usdc.balanceOf(signers[i].address);
      tx = await cashier.connect(signers[i]).pickupUsd();
      let balaAfter = await usdc.balanceOf(signers[i].address);
      
      await royaltyTest(rc.address, signers[i].address, gk.address, tx, 18n, "cashier.pickupUsd().");

      transferCBP(userNo.toString(), "8", 18n);

      await expect(tx).to.emit(cashier, "PickupUsd").withArgs(signers[i].address, userNo, depo);
      console.log(" \u2714 Passed Event Test for cashier.PickupUsd(). \n");
      
      diff = balaAfter - balaBefore;

      expect(diff).to.equal(BigInt(depo.toString()));

      console.log(" \u2714 Passed Result Verify Test for cashier.pickupUsd(). for User", parseInt(userNo.toString()), " \n");

    }

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
