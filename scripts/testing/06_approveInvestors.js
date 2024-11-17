// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { expect } = require("chai");
const { BigNumber, ethers } = require("ethers");

const { parseTimestamp, Bytes32Zero, AddrZero } = require("./utils");
const { getGK, getLOO, getRC } = require("./boox");
const { parseInvestor } = require("./loo");
const { royaltyTest } = require("./rc");

async function main() {

    console.log('/n********************************');
    console.log('**     Approve Investors      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const loo = await getLOO();

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
      console.log("Passed Event Test for gk.regInvestor(). \n");

      let info = parseInvestor(await loo.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Pending');
      console.log('Passed Result Verify Test for gk.regInvestor().\n');     
    
      tx = await gk.approveInvestor(userNo, 1024);

      await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.approveInvestor().");

      await expect(tx).to.emit(loo, "ApproveInvestor").withArgs(userNo, 1);
      console.log("Passed Event Test for loo.ApproveInvestor(). \n");

      info = parseInvestor(await loo.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Approved'); 

      console.log('Passed Result Verify Test for gk.approveInvestor().\n');
    }

    await expect(gk.connect(signers[1]).approveInvestor(1, 1024)).to.be.revertedWith("LOOK.apprInv: no rights");
    console.log('Passed Access Control Test for gk.approveInvestor(). \n');

    for (let i=0; i<10; i++) {
      await regAndApproveInvestor(i);
    }

    // ==== Revoke Investor ====
    
    for (let i=7; i<10; i++) {
      const userNo = await rc.connect(signers[i]).getMyUserNo();
      const tx = await gk.revokeInvestor(userNo, 1024);
      
      await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.revokeIvnestor().");

      await expect(tx).to.emit(loo, "RevokeInvestor").withArgs(userNo, 1);
      console.log('Passed Event Test for gk.revokeInvestor(). \n');
      
      const info = parseInvestor(await loo.getInvestor(userNo));
      
      expect(info.userNo).to.equal(userNo);
      expect(info.approved).to.equal('Revoked'); 
    }

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
