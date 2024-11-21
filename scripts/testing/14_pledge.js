// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROP, getROS, getRC, getROM, } = require("./boox");
const { increaseTime, Bytes32Zero, } = require("./utils");
const { codifyHeadOfPledge, parsePledge } = require("./rop");
const { getLatestShare, parseShare } = require("./ros");
const { royaltyTest } = require("./rc");

async function main() {

    console.log('\n********************************');
    console.log('**      14. Pledges           **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const rop = await getROP();
    const ros = await getROS();
    const rom = await getROM();
    
    // ==== Create Pledge ====

    let headOfPld = {
      seqOfShare: 8,
      seqOfPld: 1,
      createDate: 0,
      daysToMaturity: 10, 
      guaranteeDays: 10,
      creditor: 6,
      debtor: 2,
      pledgor: 3,
      state: 0,
    };

    await expect(gk.createPledge(codifyHeadOfPledge(headOfPld), 8000 * 10 ** 4, 8000 * 10 ** 4, 4000 * 10 ** 4, 5)).to.be.revertedWith("BOPK.createPld: NOT shareholder");
    console.log(" \u2714 Passed Access Control Test for gk.createPledge(). \n");

    let tx = await gk.connect(signers[3]).createPledge(codifyHeadOfPledge(headOfPld), 8000 * 10 ** 4, 8000 * 10 ** 4, 4000 * 10 ** 4, 5);
    
    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 66n, "gk.createPledge().");

    await expect(tx).to.emit(rop, "CreatePledge").withArgs(BigNumber.from(8), BigNumber.from(1), BigNumber.from(6), BigNumber.from(8000 * 10 ** 4), BigNumber.from(8000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for rop.CreatePledge(). \n");
    
    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(BigNumber.from(8), BigNumber.from(8000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.CreatePledge(). \n");

    let pld = parsePledge(await rop.getPledge(8, 1));
    
    expect(pld.head.seqOfShare).to.equal(8);
    expect(pld.head.seqOfPld).to.equal(1);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(6);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Issued");
    expect(pld.body.paid).to.equal("8,000.0");
    
    let share = parseShare(await ros.getShare(8));

    expect(share.body.cleanPaid).to.equal("2,000.0");

    console.log(" \u2714 Passed Result Verify Test for gk.createPledge(). \n");

    // ==== Transfer Pledge ====

    tx = await gk.connect(signers[6]).transferPledge(8, 1, 5, 2000 * 10 ** 4);

    await royaltyTest(rc.address, signers[6].address, gk.address, tx, 36n, "gk.transferPledge().");

    await expect(tx).to.emit(rop, "TransferPledge").withArgs(BigNumber.from(pld.head.seqOfShare), BigNumber.from(1), BigNumber.from(2), BigNumber.from(5), BigNumber.from(4000 * 10 ** 4), BigNumber.from(4000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for rop.TransferPledge(). \n");

    pld = parsePledge(await rop.getPledge(8, 2));

    expect(pld.head.seqOfShare).to.equal(8);
    expect(pld.head.seqOfPld).to.equal(2);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(5);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Issued");
    expect(pld.body.paid).to.equal("4,000.0");

    console.log(' \u2714 Passed Result Verify Test for gk.transferPledge(). \n');

    // ==== Refund Debts ====

    tx = await gk.connect(signers[5]).refundDebt(8, 2, 1000 * 10 ** 4);

    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 36n, "gk.refundDebt().");

    await expect(tx).to.emit(rop, "RefundDebt").withArgs(BigNumber.from(pld.head.seqOfShare), BigNumber.from(pld.head.seqOfPld), BigNumber.from(1000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for rop.RefundDebt(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(pld.head.seqOfShare), BigNumber.from(2000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    pld = parsePledge(await rop.getPledge(8, 2));

    expect(pld.body.paid).to.equal("2,000.0");

    share = parseShare(await ros.getShare(8));
    
    expect(share.body.cleanPaid).to.equal("4,000.0");

    console.log(' \u2714 Passed Result Verify Test for gk.refundDebt(). \n');

    // ==== Extend Pledge ====

    await expect(gk.connect(signers[6]).extendPledge(8, 1, 10)).to.be.revertedWith("PR.extendPld: not pledgor");
    console.log(" \u2714 Passed Acceess Control Test for gk.extendPledge(). \n");

    tx = await gk.connect(signers[3]).extendPledge(8, 1, 10);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 18n, "gk.extendPledge().");

    await expect(tx).to.emit(rop, "ExtendPledge").withArgs(BigNumber.from(8), BigNumber.from(1), BigNumber.from(10));
    console.log(" \u2714 Passed Event Test for rop.ExtendPledge(). \n");

    pld = parsePledge(await rop.getPledge(8, 1));
    expect(pld.head.guaranteeDays).to.equal(20);
    
    console.log(' \u2714 Passed Result Verify Test for gk.extendPledge(). \n');

    // ==== Lock & Release Pledge ====

    await gk.connect(signers[5]).transferPledge(8, 2, 6, 500 * 10 ** 4);

    const hashLock = ethers.utils.id('Spring is coming');

    await expect(gk.connect(signers[3]).lockPledge(8, 2, hashLock)).to.be.revertedWith("PR.lockPld: not creditor");
    console.log(" \u2714 Passed Acceess Control Test for gk.lockPledge(). \n");

    await expect(gk.connect(signers[5]).lockPledge(8, 2, Bytes32Zero)).to.be.revertedWith("PR.lockPld: zero hashLock");
    console.log(" \u2714 Passed Parameter Control Test for gk.lockPledge(). \n");

    tx = await gk.connect(signers[5]).lockPledge(8, 2, hashLock);

    await royaltyTest(rc.address, signers[5].address, gk.address, tx, 58n, "gk.lockPledge().");

    await expect(tx).to.emit(rop, "LockPledge").withArgs(BigNumber.from(8), BigNumber.from(2), hashLock);
    console.log(" \u2714 Passed Event Test for rop.LockPledge(). \n");

    pld = parsePledge(await rop.getPledge(8, 2));

    expect(pld.head.seqOfShare).to.equal(8);
    expect(pld.head.seqOfPld).to.equal(2);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(5);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Locked");
    expect(pld.body.paid).to.equal("1,000.0");
    expect(pld.hashLock).to.equal(hashLock);

    console.log(' \u2714 Passed Result Verify Test for gk.lockPledge(). \n');

    // ==== Release Pledge ====

    await expect(gk.connect(signers[3]).releasePledge(8, 2, 'Spring is came')).to.be.revertedWith("PR.releasePld: wrong Key");
    console.log(" \u2714 Passed Wrong Hashkey Check Test for gk.releasePledge(). \n");

    tx = await gk.connect(signers[3]).releasePledge(8, 2, 'Spring is coming');

    await expect(tx).to.emit(rop, "ReleasePledge").withArgs(BigNumber.from(8), BigNumber.from(2), "Spring is coming");
    console.log(" \u2714 Passed Event Test for rop.ReleasePledge(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(8), BigNumber.from(1000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    pld = parsePledge(await rop.getPledge(8, 2));

    expect(pld.head.seqOfShare).to.equal(8);
    expect(pld.head.seqOfPld).to.equal(2);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(5);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Released");
    expect(pld.body.paid).to.equal("1,000.0");
    expect(pld.hashLock).to.equal(hashLock);

    share = parseShare(await ros.getShare(8));

    expect(share.body.cleanPaid).to.equal("5,000.0");

    console.log(' \u2714 Passed Result Verify Test for gk.releasePledge(). \n');

    // ==== Execute Pledge ====

    await increaseTime(86400 * 21);

    tx = await gk.connect(signers[6]).execPledge(8, 1, 6, 6);

    await royaltyTest(rc.address, signers[6].address, gk.address, tx, 88n, "gk.execPledge().");

    await expect(tx).to.emit(rop, "ExecPledge").withArgs(BigNumber.from(8), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for rop.ExecPledge(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(8), BigNumber.from(4000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    await expect(tx).to.emit(ros, "SubAmountFromShare").withArgs(BigNumber.from(8), BigNumber.from(4000 * 10 ** 4), BigNumber.from(4000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.SubAmountFromShare(). \n");

    await expect(tx).to.emit(rom, "AddMember").withArgs(BigNumber.from(6), BigNumber.from(5));
    console.log(" \u2714 Passed Event Test for rom.AddMember(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(23), BigNumber.from(6));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    pld = parsePledge(await rop.getPledge(8, 1));

    expect(pld.head.seqOfShare).to.equal(8);
    expect(pld.head.seqOfPld).to.equal(1);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(20);
    expect(pld.head.creditor).to.equal(6);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Executed");
    expect(pld.body.paid).to.equal("4,000.0");

    share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(23);
    expect(share.head.shareholder).to.equal(6);
    expect(share.body.paid).to.equal("4,000.0");
    expect(share.body.cleanPaid).to.equal("4,000.0");
    
    console.log(' \u2714 Passed Result Verify Test for gk.execPledge(). \n');

    // ==== Pledge Expire ====

    await expect(gk.connect(signers[6]).transferPledge(8, 3, 5, 500 * 10 ** 4)).to.be.revertedWith("PR.splitPld: pledge expired");
    console.log(" \u2714 Passed Expiration Test for gk.transferPledge(). \n");    

    await expect(gk.connect(signers[6]).refundDebt(8, 3, 500 * 10 ** 4)).to.be.revertedWith("PR.splitPld: pledge expired");
    console.log(" \u2714 Passed Expiration Test for gk.refundPledge(). \n");    

    await expect(gk.connect(signers[3]).extendPledge(8, 3, 10)).to.be.revertedWith("PR.UP: pledge expired");
    console.log(" \u2714 Passed Expiration Test for gk.extendPledge(). \n");    

    await expect(gk.connect(signers[6]).lockPledge(8, 3, hashLock)).to.be.revertedWith("PR.lockPld: pledge expired");
    console.log(" \u2714 Passed Expiration Test for gk.lockPledge(). \n");    

    // ==== Revoke Pledge ====

    await expect(gk.connect(signers[2]).revokePledge(8, 3)).to.be.revertedWith("BOPK.RP: not pledgor");
    console.log(" \u2714 Passed Access Control Test for gk.revokePledge(). \n");    

    tx = await gk.connect(signers[3]).revokePledge(8, 3);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.revokePledge().");

    await expect(tx).to.emit(rop, "RevokePledge").withArgs(BigNumber.from(8), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for rop.RevokePledge(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(8), BigNumber.from(1000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    pld = parsePledge(await rop.getPledge(8, 3));

    expect(pld.head.seqOfShare).to.equal(8);
    expect(pld.head.seqOfPld).to.equal(3);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(6);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Revoked");
    expect(pld.body.paid).to.equal("1,000.0");

    share = parseShare(await ros.getShare(8));

    expect(share.body.cleanPaid).to.equal("6,000.0");

    console.log(' \u2714 Passed Result Verify Test for gk.revokePledge(). \n');
      
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
