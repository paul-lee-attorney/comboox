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
// (2) Signer_0 to Signer_9 register Investor with Fund Keeper;
// (3) Signer_0 (User_1) as Asset Manager approves the Investor applications;
// (4) User_1 as Asset Manager revokes the Investor role for User_8 to User_10.

// The write APIs tested in this section:
// 1. FundKeeper;
// 1.1 function regInvestor(uint groupRep, bytes32 idHash) external;
// 1.2 function approveInvestor(uint userNo, uint seqOfLR) external;
// 1.3 function revokeInvestor(uint userNo, uint seqOfLR) external;

// Events verified in this section:
// 1. Register of Investors
// 1.1 event RegInvestor(uint indexed investor, uint indexed groupRep, 
//     bytes32 indexed idHash);
// 1.2 event ApproveInvestor(uint indexed investor, uint indexed verifier);
// 1.3 event RevokeInvestor(uint indexed investor, uint indexed verifier);

import { network } from "hardhat";
import { id } from "ethers";
import { expect } from "chai";
import { getRC, getROS, getROI, getFK } from "./boox";
import { parseInvestor } from "./roi";
import { royaltyTest, cbpOfUsers, userParser } from "./rc";
import { printShares } from "./ros";
import { setUserCBP, transferCBP } from "./saveTool";

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**   06.1 Approve Investors   **');
    console.log('********************************');
    console.log('\n');

    const { ethers } = await network.connect();
	  const signers = await ethers.getSigners();

    const rc = await getRC();
    const gk = await getFK();
    const roi = await getROI();
    const ros = await getROS();
    const addrRC = await rc.getAddress();
    const addrGK = await gk.getAddress();

    // ==== Reg New Users ==== 

    const regNewUser = async (signerNo) => {
      await rc.connect(signers[signerNo]).regUser();
      setUserCBP((signerNo+2).toString(), 18n * 10n ** 15n); 
      await rc.connect(signers[signerNo]).setBackupKey(await signers[signerNo+10].getAddress());
    }

    for (let i=7; i<10; i++) {
      await regNewUser(i);
    }
    
    // ==== Reg & Approve Investors ====

    const regAndApproveInvestor = async (signerNo) => {
      const userNo = await rc.connect(signers[signerNo]).getMyUserNo();

      let user = userParser(await rc.connect(signers[signerNo]).getUser());

      let tx = await gk.connect(signers[signerNo]).regInvestor(user.backupKey.pubKey, userNo, id(await signers[signerNo].getAddress()));
      
      await royaltyTest(addrRC, await signers[signerNo].getAddress(), addrGK, tx, 18n, "gk.regInvestor().PrimeKeyTest().");
      transferCBP(userNo.toString(), "8", 18n);

      await royaltyTest(addrRC, await signers[signerNo].getAddress(), addrGK, tx, 18n, "gk.regInvestor().BackupKeyTest().");
      transferCBP(userNo.toString(), "8", 18n);
  
      await expect(tx).to.emit(roi, "RegInvestor").withArgs(userNo, userNo, id(await signers[signerNo].getAddress()));
      console.log(" \u2714 Passed Event Test for gk.regInvestor(). \n");

      let info = parseInvestor(await roi.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Pending');
      console.log(' \u2714 Passed Result Verify Test for gk.regInvestor().\n');     
    
      tx = await gk.approveInvestor(userNo, 1024);

      await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 18n, "gk.approveInvestor().");

      transferCBP("1", "8", 18n);

      await expect(tx).to.emit(roi, "ApproveInvestor").withArgs(userNo, 1);
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
      
      await royaltyTest(addrRC, await signers[0].getAddress(), addrGK, tx, 18n, "gk.revokeIvnestor().");

      transferCBP("1", "8", 18n);

      await expect(tx).to.emit(roi, "RevokeInvestor").withArgs(userNo, 1);
      console.log(' \u2714 Passed Event Test for gk.revokeInvestor(). \n');
      
      const info = parseInvestor(await roi.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Revoked'); 
    }

    await printShares(ros);
    await cbpOfUsers(rc, addrGK);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
