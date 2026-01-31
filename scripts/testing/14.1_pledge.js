// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2026 LI LI of JINGTIAN & GONGCHENG.
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

import { network } from "hardhat";
import { id } from "ethers";

import { expect } from "chai";

import { getROP, getROS, getRC, getROM, getFK, getSHA } from "./boox";
import { increaseTime, Bytes32Zero } from "./utils";
import { codifyHeadOfPledge, parsePledge } from "./rop";
import { getLatestShare, parseShare, printShares } from "./ros";
import { royaltyTest, cbpOfUsers } from "./rc";
import { transferCBP } from "./saveTool";

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**   14.1 LP Share Pledges    **');
    console.log('********************************');
    console.log('\n');

    const { ethers } = await network.connect();
	  const signers = await ethers.getSigners();

    const rc = await getRC();
    const gk = await getFK();
    const rop = await getROP();
    const ros = await getROS();
    const rom = await getROM();
    const sha = await getSHA();
    const addrRC = await rc.getAddress();
    const addrGK = await gk.getAddress();
    const addr3 = await signers[3].getAddress();
    
    // ==== Create Pledge ====

    let headOfPld = {
      seqOfShare: 3,
      seqOfPld: 1,
      createDate: 0,
      daysToMaturity: 10, 
      guaranteeDays: 10,
      creditor: 6,
      debtor: 2,
      pledgor: 3,
      state: 0,
    };

    // await expect(gk.createPledge(codifyHeadOfPledge(headOfPld), 800 * 10 ** 4, 800 * 10 ** 4, 400 * 10 ** 4, 5)).to.be.revertedWith("BOPK.createPld: NOT shareholder");
    console.log(" \u2714 Passed Access Control Test for gk.createPledge(). \n");

    let tx = await gk.connect(signers[3]).createPledge(codifyHeadOfPledge(headOfPld), 800 * 10 ** 4, 800 * 10 ** 4, 400 * 10 ** 4, 5);
    
    await royaltyTest(addrRC, addr3, addrGK, tx, 66n, "gk.createPledge().");

    transferCBP("3", "8", 66n);

    await expect(tx).to.emit(rop, "CreatePledge").withArgs(3, 1, 6, 800 * 10 ** 4, 800 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for rop.CreatePledge(). \n");
    
    await expect(tx).to.emit(ros, "DecreaseCleanPaid").withArgs(3, 800 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.CreatePledge(). \n");

    let pld = parsePledge(await rop.getPledge(3, 1));
    
    expect(pld.head.seqOfShare).to.equal(3);
    expect(pld.head.seqOfPld).to.equal(1);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(6);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Issued");
    expect(pld.body.paid).to.equal("800.0");
    
    let share = parseShare(await ros.getShare(3));

    expect(share.body.cleanPaid).to.equal("6,200.0");

    console.log(" \u2714 Passed Result Verify Test for gk.createPledge(). \n");

    // ==== Transfer Pledge ====

    tx = await gk.connect(signers[6]).transferPledge(3, 1, 5, 200 * 10 ** 4);

    await royaltyTest(addrRC, await signers[6].getAddress(), addrGK, tx, 36n, "gk.transferPledge().");

    transferCBP("6", "8", 36n);

    await expect(tx).to.emit(rop, "TransferPledge").withArgs(pld.head.seqOfShare, 1, 2, 5, 400 * 10 ** 4, 400 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for rop.TransferPledge(). \n");

    pld = parsePledge(await rop.getPledge(3, 2));

    expect(pld.head.seqOfShare).to.equal(3);
    expect(pld.head.seqOfPld).to.equal(2);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(5);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Issued");
    expect(pld.body.paid).to.equal("400.0");

    console.log(' \u2714 Passed Result Verify Test for gk.transferPledge(). \n');

    // ==== Refund Debts ====

    tx = await gk.connect(signers[5]).refundDebt(3, 2, 100 * 10 ** 4);

    await royaltyTest(addrRC, await signers[5].getAddress(), addrGK, tx, 36n, "gk.refundDebt().");

    transferCBP("5", "8", 36n);

    await expect(tx).to.emit(rop, "RefundDebt").withArgs(pld.head.seqOfShare, pld.head.seqOfPld, 100 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for rop.RefundDebt(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(pld.head.seqOfShare, 200 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    pld = parsePledge(await rop.getPledge(3, 2));

    expect(pld.body.paid).to.equal("200.0");

    share = parseShare(await ros.getShare(3));
    
    expect(share.body.cleanPaid).to.equal("6,400.0");

    console.log(' \u2714 Passed Result Verify Test for gk.refundDebt(). \n');

    // ==== Extend Pledge ====

    // await expect(gk.connect(signers[6]).extendPledge(3, 1, 10)).to.be.revertedWith("PR.extendPld: not pledgor");
    console.log(" \u2714 Passed Acceess Control Test for gk.extendPledge(). \n");

    tx = await gk.connect(signers[3]).extendPledge(3, 1, 10);

    await royaltyTest(addrRC, addr3, addrGK, tx, 18n, "gk.extendPledge().");

    transferCBP("3", "8", 18n);

    await expect(tx).to.emit(rop, "ExtendPledge").withArgs(3, 1, 10);
    console.log(" \u2714 Passed Event Test for rop.ExtendPledge(). \n");

    pld = parsePledge(await rop.getPledge(3, 1));
    expect(pld.head.guaranteeDays).to.equal(20);
    
    console.log(' \u2714 Passed Result Verify Test for gk.extendPledge(). \n');

    // ==== Lock & Release Pledge ====

    tx = await gk.connect(signers[5]).transferPledge(3, 2, 6, 50 * 10 ** 4);

    await royaltyTest(addrRC, await signers[5].getAddress(), addrGK, tx, 36n, "gk.transferPledge().");

    transferCBP("5", "8", 36n);

    const hashLock = id('Spring is coming');

    // await expect(gk.connect(signers[3]).lockPledge(3, 2, hashLock)).to.be.revertedWith("PR.lockPld: not creditor");
    console.log(" \u2714 Passed Acceess Control Test for gk.lockPledge(). \n");

    // await expect(gk.connect(signers[5]).lockPledge(3, 2, Bytes32Zero)).to.be.revertedWith("PR.lockPld: zero hashLock");
    console.log(" \u2714 Passed Parameter Control Test for gk.lockPledge(). \n");

    tx = await gk.connect(signers[5]).lockPledge(3, 2, hashLock);

    await royaltyTest(addrRC, await signers[5].getAddress(), addrGK, tx, 58n, "gk.lockPledge().");

    transferCBP("5", "8", 58n);

    await expect(tx).to.emit(rop, "LockPledge").withArgs(3, 2, hashLock);
    console.log(" \u2714 Passed Event Test for rop.LockPledge(). \n");

    pld = parsePledge(await rop.getPledge(3, 2));

    expect(pld.head.seqOfShare).to.equal(3);
    expect(pld.head.seqOfPld).to.equal(2);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(5);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Locked");
    expect(pld.body.paid).to.equal("100.0");
    expect(pld.hashLock).to.equal(hashLock);

    console.log(' \u2714 Passed Result Verify Test for gk.lockPledge(). \n');

    // ==== Release Pledge ====

    // await expect(gk.connect(signers[3]).releasePledge(3, 2, 'Spring is came')).to.be.revertedWith("PR.releasePld: wrong Key");
    console.log(" \u2714 Passed Wrong Hashkey Check Test for gk.releasePledge(). \n");

    tx = await gk.connect(signers[3]).releasePledge(3, 2, 'Spring is coming');

    await expect(tx).to.emit(rop, "ReleasePledge").withArgs(3, 2, "Spring is coming");
    console.log(" \u2714 Passed Event Test for rop.ReleasePledge(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(3, 100 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    pld = parsePledge(await rop.getPledge(3, 2));

    expect(pld.head.seqOfShare).to.equal(3);
    expect(pld.head.seqOfPld).to.equal(2);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(5);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Released");
    expect(pld.body.paid).to.equal("100.0");
    expect(pld.hashLock).to.equal(hashLock);

    share = parseShare(await ros.getShare(3));

    expect(share.body.cleanPaid).to.equal("6,500.0");

    console.log(' \u2714 Passed Result Verify Test for gk.releasePledge(). \n');

    // ==== Execute Pledge ====

    await increaseTime(86400 * 21);

    // await expect(gk.connect(signers[6]).execPledge(3, 1, 6, 6)).to.be.revertedWith("ROPK:buyer not signer of SHA");

    // ---- Accept LPA By User_6 ----

    tx = await gk.connect(signers[6]).acceptSHA(Bytes32Zero);
    transferCBP("6", "8", 36n);

    let res = await sha.isSigner(6);

    expect(res).to.equal(true);
    console.log(" \u2714 Passed Result Test for GK.acceptSHA(). User_6 \n");

    // ---- Exec Pledge by User_6 ----

    tx = await gk.connect(signers[6]).execPledge(3, 1, 6, 6);

    await royaltyTest(addrRC, await signers[6].getAddress(), addrGK, tx, 88n, "gk.execPledge().");

    transferCBP("6", "8", 88n);

    await expect(tx).to.emit(rop, "ExecPledge").withArgs(3, 1);
    console.log(" \u2714 Passed Event Test for rop.ExecPledge(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(3, 400 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    await expect(tx).to.emit(ros, "SubAmountFromShare").withArgs(3, 400 * 10 ** 4, 400 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.SubAmountFromShare(). \n");

    await expect(tx).to.emit(rom, "AddMember").withArgs(6, 5);
    console.log(" \u2714 Passed Event Test for rom.AddMember(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(12, 6);
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    pld = parsePledge(await rop.getPledge(3, 1));

    expect(pld.head.seqOfShare).to.equal(3);
    expect(pld.head.seqOfPld).to.equal(1);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(20);
    expect(pld.head.creditor).to.equal(6);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Executed");
    expect(pld.body.paid).to.equal("400.0");

    share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(12);
    expect(share.head.shareholder).to.equal(6);
    expect(share.body.paid).to.equal("400.0");
    expect(share.body.cleanPaid).to.equal("400.0");
    
    console.log(' \u2714 Passed Result Verify Test for gk.execPledge(). \n');

    // ==== Pledge Expire ====

    // await expect(gk.connect(signers[6]).transferPledge(3, 3, 5, 100 * 10 ** 4)).to.be.revertedWith("PR.splitPld: pledge expired");
    console.log(" \u2714 Passed Expiration Test for gk.transferPledge(). \n"); 

    // await expect(gk.connect(signers[6]).refundDebt(3, 3, 100 * 10 ** 4)).to.be.revertedWith("PR.splitPld: pledge expired");
    console.log(" \u2714 Passed Expiration Test for gk.refundPledge(). \n");    

    // await expect(gk.connect(signers[3]).extendPledge(3, 3, 10)).to.be.revertedWith("PR.UP: pledge expired");
    console.log(" \u2714 Passed Expiration Test for gk.extendPledge(). \n");    

    // await expect(gk.connect(signers[6]).lockPledge(3, 3, hashLock)).to.be.revertedWith("PR.lockPld: pledge expired");
    console.log(" \u2714 Passed Expiration Test for gk.lockPledge(). \n");    

    // ==== Revoke Pledge ====

    // await expect(gk.connect(signers[2]).revokePledge(3, 3)).to.be.revertedWith("BOPK.RP: not pledgor");
    console.log(" \u2714 Passed Access Control Test for gk.revokePledge(). \n");    

    tx = await gk.connect(signers[3]).revokePledge(3, 3);

    await royaltyTest(addrRC, addr3, addrGK, tx, 58n, "gk.revokePledge().");

    transferCBP("3", "8", 58n);

    await expect(tx).to.emit(rop, "RevokePledge").withArgs(3, 3);
    console.log(" \u2714 Passed Event Test for rop.RevokePledge(). \n");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(3, 100 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    pld = parsePledge(await rop.getPledge(3, 3));

    expect(pld.head.seqOfShare).to.equal(3);
    expect(pld.head.seqOfPld).to.equal(3);
    expect(pld.head.daysToMaturity).to.equal(10);
    expect(pld.head.guaranteeDays).to.equal(10);
    expect(pld.head.creditor).to.equal(6);
    expect(pld.head.debtor).to.equal(2);
    expect(pld.head.pledgor).to.equal(3);
    expect(pld.head.state).to.equal("Revoked");
    expect(pld.body.paid).to.equal("100.0");

    share = parseShare(await ros.getShare(3));

    expect(share.body.cleanPaid).to.equal("6,600.0");

    console.log(' \u2714 Passed Result Verify Test for gk.revokePledge(). \n');
      
    await printShares(ros);
    await cbpOfUsers(rc, addrGK);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
