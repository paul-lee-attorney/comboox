// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to register, approve and revoke Investors in
// ComBoox. Only approved Investors can enter into investment agreements, list 
// offers or bids on the List of Orders. This procedure is designed to comply 
// with any legal requirements relating to anti-money laundering or accredited 
// investors. 

// The scenarios for testing include in this section are:
// (1) Signer_7 to Signer_9 register Users with Registration Center;
// (2) Signer_0 to Signer_9 register Investor with General Keeper;
// (3) Signer_0 (User_1) as Chairman approves the Investor applications;
// (4) User_1 as Chairman revokes the Investor role for User_8 to User_10.

// The write APIs tested in this section:
// 1. GeneralKeeper;
// 1.1 function regInvestor(uint groupRep, bytes32 idHash) external;
// 1.2 function approveInvestor(uint userNo, uint seqOfLR) external;
// 1.3 function revokeInvestor(uint userNo, uint seqOfLR) external;

// Events verified in this section:
// 1. List of Orders
// 1.1 event RegInvestor(uint indexed investor, uint indexed groupRep, 
//     bytes32 indexed idHash);
// 1.2 event ApproveInvestor(uint indexed investor, uint indexed verifier);
// 1.3 event RevokeInvestor(uint indexed investor, uint indexed verifier);

import { network } from "hardhat";
import { expect } from "chai";
import { getGK, getRC, getROS, getROI } from "./boox";
import { parseInvestor } from "./roi";
import { royaltyTest, cbpOfUsers, userParser, getAllUsers } from "./rc";
import { printShares } from "./ros";
import { setUserCBP, transferCBP } from "./saveTool";
import { id } from "ethers";
import { parseCompInfo } from "./gk";
import { readTool } from "../readTool";

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**   06. Approve Investors    **');
    console.log('********************************');
    console.log('\n');

    const { ethers } = await network.connect();

	  const signers = await ethers.getSigners();

    const rc = await getRC();
    let gk = await getGK();
    const userComp = await parseCompInfo(await gk.getCompInfo()).regNum;
    const roi = await getROI();
    const ros = await getROS();

    // ==== Reg New Users ==== 

    // const regNewUser = async (signerNo) => {
    //   await rc.connect(signers[signerNo]).regUser();
    //   setUserCBP((signerNo+2).toString(), 18n * 10n ** 15n); 
    //   await rc.connect(signers[signerNo]).setBackupKey(await signers[signerNo+10].getAddress());
    // }

    // for (let i=7; i<10; i++) {
    //   await regNewUser(i);
    // }

    const users = await getAllUsers(rc, 9);

    // ==== Reg & Approve Investors ====

    const regAndApproveInvestor = async (signerNo) => {
      const userNo = await rc.connect(signers[signerNo]).getMyUserNo();

      let user = userParser(await rc.connect(signers[signerNo]).getMyUser());

      gk = await readTool("ROIKeeper", gk.target);

      let tx = await gk.connect(signers[signerNo]).regInvestor(user.backupKey.pubKey, userNo, id(signers[signerNo].address));
      
      await royaltyTest(rc.target, signers[signerNo].address, gk.target, tx, 18n, "gk.regInvestor().PrimeKeyTest().");

      transferCBP(userNo.toString(), userComp, 18n);

      await royaltyTest(rc.target, signers[signerNo].address, gk.target, tx, 18n, "gk.regInvestor().BackupKeyTest().");
      transferCBP(userNo.toString(), userComp, 18n);
  
      await expect(tx).to.emit(roi, "RegInvestor").withArgs(userNo, userNo, id(signers[signerNo].address));
      console.log(" \u2714 Passed Event Test for gk.regInvestor(). \n");

      let info = parseInvestor(await roi.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Pending');
      console.log(' \u2714 Passed Result Verify Test for gk.regInvestor().\n');
    
      gk = await readTool("ROIKeeper", gk.target);

      tx = await gk.approveInvestor(userNo, 1024);

      await royaltyTest(rc.target, signers[0].address, gk.target, tx, 18n, "gk.approveInvestor().");

      transferCBP(users[0], userComp, 18n);

      await expect(tx).to.emit(roi, "ApproveInvestor").withArgs(userNo, users[0]);
      console.log(" \u2714 Passed Event Test for roi.ApproveInvestor(). \n");

      info = parseInvestor(await roi.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Approved'); 

      console.log(' \u2714 Passed Result Verify Test for gk.approveInvestor().\n');
    }

    // await expect(gk.connect(signers[1]).approveInvestor(1, 1024)).to.be.revertedWith("ROIK.checkVerifierLicense: no rights");
    console.log(' \u2714 Passed Access Control Test for gk.approveInvestor(). \n');

    for (let i=0; i<10; i++) {
      await regAndApproveInvestor(i);
    }

    // ==== Revoke Investor ====
    
    for (let i=7; i<10; i++) {
      const userNo = await rc.connect(signers[i]).getMyUserNo();
      const tx = await gk.revokeInvestor(userNo, 1024);
      
      await royaltyTest(rc.target, signers[0].address, gk.target, tx, 18n, "gk.revokeInvestor().");

      transferCBP(users[0], userComp, 18n);

      await expect(tx).to.emit(roi, "RevokeInvestor").withArgs(userNo, users[0]);
      console.log(' \u2714 Passed Event Test for gk.revokeInvestor(). \n');
      
      const info = parseInvestor(await roi.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Revoked'); 
    }

    await printShares(ros);
    await cbpOfUsers(rc, gk.target, userComp);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
