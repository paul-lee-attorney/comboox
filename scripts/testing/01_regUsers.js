// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests the functions for registering new users in
// ComBoox. Each new user may obtain a sum of awards for its registration, rate
// of which is defined in Platform Rule. And, the Platform Rule can only be set
// and revised by the owner of the Platform. 

// We prepared totally 7 users (User_1 - User_7) for the testing program. User_1 
// to User_4 will be the founding Members of the Company. And, User_5 to User_6 
// will act as external Investors in some scenarios like Drag/Tag Along deals 
// and Listing Deals. 

// Scenarios for testing included in this section:
// (1)Owner of the Platform (User_1) updates the Platform Rule to enable new 
//    users may get 0.018 CBP as rewards;
// (2)User_1 as Owner of the Platform mints 8 CBP to User_1 and User_2 
//    respectively as set up cost;
// (3)Register User_3 to User_7 as potential Members and Investors;
// (4)User_3 to User_7 obtain New User Awards as per the Platform Rule.

// Write APIs tested in this section:
// Smart Contract: RegCenter
// 1. function setPlatformRule(bytes32 snOfRule) external;
// 2. function mint(address to, uint amt) external;
// 3. function regUser() external;

const { pfrCodifier, pfrParser } = require('./rc');
const { getRC } = require("./boox");
const { expect } = require("chai");
const { AddrZero } = require('./utils');

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**      01. Reg Users         **');
    console.log('********************************\n');

    // ==== Obtain Instances ====

	  const signers = await hre.ethers.getSigners();
    const rc = await getRC();

    // ==== Set Platform Rule ====

    let pfr = pfrParser(await rc.getPlatformRule());

    pfr.eoaRewards = "0.018";
    const snOfPFR = pfrCodifier(pfr);

    await expect(rc.connect(signers[1]).setPlatformRule(snOfPFR)).to.be.revertedWith("UR.mf.OO: not owner");
    console.log(" \u2714 Passed Access Control Test for rc.setPlatformRule().\n");

    await expect(rc.setPlatformRule(snOfPFR)).to.emit(rc, "SetPlatformRule").withArgs(snOfPFR);
    console.log(' \u2714 Passed Event Test for rc.SetPlatformRule(). \n');

    expect(pfrParser(await rc.getPlatformRule()).eoaRewards).to.equal("0.018");
    console.log(' \u2714 Passed Verification Test for rc.setPlatformRule(). \n');

    // ==== Reg Users ====

    await expect(rc.mint(signers[0].address, 8n * 10n ** 18n)).to.emit(rc, "Transfer").withArgs(AddrZero, signers[0].address, 8n * 10n ** 18n);
    console.log(" \u2714 Passed Event Test for rc.Transfer(). \n");

    const userNo2 = await rc.connect(signers[1]).getMyUserNo();
    expect(userNo2).to.equal(2);
    console.log(" \u2714 Passed UserNo Verify Test for userNo2. \n");

    await rc.mint(signers[1].address, 8n * 10n ** 18n);
    expect(ethers.utils.formatUnits((await rc.balanceOf(signers[1].address)).toString(), 18)).to.equal("8.0");
    console.log(" \u2714 Passed Result Test for rc.mint(). \n");    

    for (let i = 3; i<7; i++) {
      await rc.connect(signers[i]).regUser();

      expect(await rc.connect(signers[i]).getMyUserNo()).to.equal(i);
      console.log(' \u2714 Passed Result Test for rc.regUser() with signers[', i, '].', '\n');

      expect(ethers.utils.formatUnits((await rc.balanceOf(signers[i].address)).toString(), 18)).to.equal("0.018");
      console.log(' \u2714 Passed NewUserAwards Result Test for signers[', i, '].', '\n');
    }

    await rc.connect(signers[2]).regUser();
    expect(await rc.connect(signers[2]).getMyUserNo()).to.equal(7);
    console.log(' \u2714 Passed Result Test for rc.regUser() with signers[', 2, '].', '\n');

    expect(ethers.utils.formatUnits((await rc.balanceOf(signers[2].address)).toString(), 18)).to.equal("0.018");
    console.log(' \u2714 Passed NewUserAwards Test for signers[', 2, '].', '\n');

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
