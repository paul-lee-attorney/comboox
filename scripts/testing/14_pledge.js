// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to set up, sell, refund, release, and revoke
// Pledge attached on equity shares.

// Members may pledge their equity shares as collateral to secure debts owed
// to relevant creditors. Upon the establishment of a pledge, the clean
// (unencumbered) paid of the pledged shares will be reduced by the amount of
// the pledge. If the debtor fails to repay the debt on time, the creditor has
// the right to enforce the pledge by transferring the pledged shares to a
// designated party up to the pledged amount.

// The pledge, along with its attached rights, may be transferred to a new
// creditor if the debt itself is assigned. Partial repayment of the debt
// allows for a proportional release of the pledged shares. The pledgor may
// fully repay the debt at any time to release the pledge entirely.
// Additionally, once the secured obligation period has expired, the pledgor
// may revoke the pledge, thereby restoring the full clean value of the
// pledged shares.

// The scenario for testing in this section are as follows:
// (1) User_3 creates a pledge amount to $8,000 (the “Pledge_1”) on its
//     Share_8 to secure a debt amount to $4,000 owed to User_6 (the
//     “Debt_1”), which we summarize as Pledge_1 ($8,000 Share_8 for $4,000
//     owed to User_6) to describe the guarantee arrangement concerned.
// (2) User_6 transfers partial of Debt_1 ($2,000) to User_5 together with
//     the attached Pledge_1, thus, a new Pledge_2 ($4,000 Share_8 for
//     $2,000 owed to User_5) was created;
// (3) User_5 as the creditor of the Debt_2, confirms receiving a refund
//     amount to $1,000. As the consequence, Pledge_2 is released by
//     $2,000 pledged amount, and turns into Pledge_2 ($2,000 Share_8 for
//     $1,000 owed to User5). 
// (4) User_3 extends the guarantee period of Pledge_1 for more 10 days;
// (5) User_5 transfers partial of its Debt_2 ($500) back to User_6,
//     together with the attached Pledge_2. Therefore, a new Pledge_3
//     ($1,000 Share_8 for $500 owed to User_6) was created accordingly.
// (6) User_5 sets up a hash lock on Pledge_2 so as to enable User_3
//     refund off-chain the Debt_2 concerned.
// (7) User_3 inputs the hash key releasing the Pledge_2, which
//     indicates that User_3 has refund the balance of Debt_2 off-chain
//     and obtained the hash key from User_5. As consequences, the clean
//     paid amount of Share_3 is recovered by $1,000 into $5,000.
// (8) Upon maturity of the Debt_1, User_6 executes the Pledge_1 to
//     request transferring the pledged amount of Share_3 to himself.
//     Thus, $4,000 Share_3 is transferred to User_6.
// (9) After expiration of Pledge_3, User_3 revokes the Pledge_3.
//     Therefore, the total clean paid amount of Share_3 is recovered
//     by $1,000 into $6,000.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.1 function createPledge(bytes32 snOfPld, uint paid, uint par, uint guaranteedAmt, uint execDays) external;
// 1.2 function transferPledge(uint256 seqOfShare, uint256 seqOfPld, uint buyer, uint amt) external;
// 1.3 function refundDebt(uint256 seqOfShare, uint256 seqOfPld, uint amt) external;
// 1.4 function extendPledge(uint256 seqOfShare, uint256 seqOfPld, uint extDays) external;
// 1.5 function lockPledge(uint256 seqOfShare, uint256 seqOfPld, bytes32 hashLock) external;
// 1.6 function releasePledge(uint256 seqOfShare, uint256 seqOfPld, string memory hashKey) external;
// 1.7 function execPledge(uint seqOfShare, uint256 seqOfPld, uint buyer, uint groupOfBuyer) external;
// 1.8 function revokePledge(uint256 seqOfShare, uint256 seqOfPld) external;

// Events verified in this section:
// 1. Register of Pledge;
// 1.1 event CreatePledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld,
//     uint256 creditor, uint256 indexed paid, uint256 par);
// 1.2 event TransferPledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld,
//     uint256 indexed newSeqOfPld, uint256 buyer, uint256 paid, uint256 par);
// 1.3 event RefundDebt(uint256 indexed seqOfShare, uint256 indexed seqOfPld,
//     uint256 indexed refundAmt);
// 1.4 event ExtendPledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld,
//     uint256 indexed extDays);
// 1.5 event LockPledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld,
//     bytes32 indexed hashLock);
// 1.6 event ReleasePledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld,
//     string indexed hashKey);
// 1.7 event ExecPledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld);
// 1.8 event RevokePledge(uint256 indexed seqOfShare, uint256 indexed seqOfPld);

// 2. Register of Shares
// 2.1 event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.2 event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.3 event SubAmountFromShare(uint256 indexed seqOfShare, uint indexed paid,
//     uint indexed par);

// 3. Register of Members
// 3.1 event AddMember(uint256 indexed acct, uint indexed qtyOfMembers);
// 3.2 event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

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
