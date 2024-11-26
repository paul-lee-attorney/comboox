// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
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
// 1.1 event RegInvestor(uint indexed investor, uint indexed groupRep, bytes32 indexed idHash);
// 1.2 event ApproveInvestor(uint indexed investor, uint indexed verifier);
// 1.3 event RevokeInvestor(uint indexed investor, uint indexed verifier);


const { expect } = require("chai");
const { getGK, getLOO, getRC, getROS } = require("./boox");
const { parseInvestor } = require("./loo");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { printShares } = require("./ros");
const { depositOfUsers } = require("./gk");

async function main() {

    console.log('\n********************************');
    console.log('**   06. Approve Investors    **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const loo = await getLOO();
    const ros = await getROS();

    // ==== Reg New Users ==== 

    const regNewUser = async (signerNo) => {
      await rc.connect(signers[signerNo]).regUser();
    }

    for (let i=7; i<10; i++) {
      await regNewUser(i);
    }
    
    // ==== Reg & Approve Investors ====

    const regAndApproveInvestor = async (signerNo) => {
      const userNo = await rc.connect(signers[signerNo]).getMyUserNo();
      let tx = await gk.connect(signers[signerNo]).regInvestor(userNo, ethers.utils.id(signers[signerNo].address));
      
      await royaltyTest(rc.address, signers[signerNo].address, gk.address, tx, 36n, "gk.regInvestor().");

      await expect(tx).to.emit(loo, "RegInvestor").withArgs(userNo, userNo, ethers.utils.id(signers[signerNo].address));
      console.log(" \u2714 Passed Event Test for gk.regInvestor(). \n");

      let info = parseInvestor(await loo.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Pending');
      console.log(' \u2714 Passed Result Verify Test for gk.regInvestor().\n');     
    
      tx = await gk.approveInvestor(userNo, 1024);

      await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.approveInvestor().");

      await expect(tx).to.emit(loo, "ApproveInvestor").withArgs(userNo, 1);
      console.log(" \u2714 Passed Event Test for loo.ApproveInvestor(). \n");

      info = parseInvestor(await loo.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Approved'); 

      console.log(' \u2714 Passed Result Verify Test for gk.approveInvestor().\n');
    }

    await expect(gk.connect(signers[1]).approveInvestor(1, 1024)).to.be.revertedWith("LOOK.apprInv: no rights");
    console.log(' \u2714 Passed Access Control Test for gk.approveInvestor(). \n');

    for (let i=0; i<10; i++) {
      await regAndApproveInvestor(i);
    }

    // ==== Revoke Investor ====
    
    for (let i=7; i<10; i++) {
      const userNo = await rc.connect(signers[i]).getMyUserNo();
      const tx = await gk.revokeInvestor(userNo, 1024);
      
      await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.revokeIvnestor().");

      await expect(tx).to.emit(loo, "RevokeInvestor").withArgs(userNo, 1);
      console.log(' \u2714 Passed Event Test for gk.revokeInvestor(). \n');
      
      const info = parseInvestor(await loo.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Revoked'); 
    }

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);
    await depositOfUsers(rc, gk);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
