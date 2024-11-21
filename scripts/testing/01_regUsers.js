// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section is to test the functions for registering new
// users in ComBoox. Each new user may obtain a sum of awards
// for its registration, rate of which is defined in Platform 
// Rule. And, the Platform Rule can only be set and revised by
// the owner of the Platform. 

// We prepared totally 7 users (User No.1 - No.7) for the testing
// program. User No.1 - No.4 will be the founding members of the 
// Company. And, User No.5 - No.6 will act as external investors
// in some scenarios like Drag/Tag Along deals and Listing Deals. 

// Scenarios for testing included in this section:
// 1. Owner (User No.1) set Platform Rule to enable new users may
//    get 0.018 CBP as rewards;
// 2. Mint 8 CBP to User No.1 and User No.2 as set up cost;
// 3. Register User No.3 - No. 7 as potential Members and Investors
// 4. User No.3 - No.7 obtain New User Awards as per the Platfrom
//    Rule.

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

    // Set new user awards for each EOA account as 0.018 CBP. 
    pfr.eoaRewards = "0.018";
    const snOfPFR = pfrCodifier(pfr);

    // User No.2 is not Owner, thus, setPlatformRule func shall block
    // the calling and revert error message. 
    await expect(rc.connect(signers[1]).setPlatformRule(snOfPFR)).to.be.revertedWith("UR.mf.OO: not owner");
    console.log(" \u2714 Passed Access Control Test for rc.setPlatformRule().\n");

    // User No.1 is owner, therefore, setPlatformRule func shall successfully
    // triggered and emit Events as expected.
    await expect(rc.setPlatformRule(snOfPFR)).to.emit(rc, "SetPlatformRule").withArgs(snOfPFR);
    console.log(' \u2714 Passed Event Test for rc.SetPlatformRule(). \n');

    expect(pfrParser(await rc.getPlatformRule()).eoaRewards).to.equal("0.018");
    console.log(' \u2714 Passed Verification Test for rc.setPlatformRule(). \n');

    // ==== Reg Users ====

    // User No.1 and User No.2 are two special Users registered during the
    // deploying process of ComBoox, thus, they cannot get new user awards. 
    // This "mint" process is to provide enough start up CBP for them to go
    // through this test process.
    await expect(rc.mint(signers[0].address, 8n * 10n ** 18n)).to.emit(rc, "Transfer").withArgs(AddrZero, signers[0].address, 8n * 10n ** 18n);
    console.log(" \u2714 Passed Event Test for rc.Transfer(). \n");

    const userNo2 = await rc.connect(signers[1]).getMyUserNo();
    expect(userNo2).to.equal(2);
    console.log(" \u2714 Passed UserNo Verify Test for userNo2. \n");

    await rc.mint(signers[1].address, 8n * 10n ** 18n);
    expect(ethers.utils.formatUnits((await rc.balanceOf(signers[1].address)).toString(), 18)).to.equal("8.0");
    console.log(" \u2714 Passed Result Test for rc.mint(). \n");    

    // Reg new users for signers[3-7].
    for (let i = 3; i<7; i++) {
      await rc.connect(signers[i]).regUser();

      expect(await rc.connect(signers[i]).getMyUserNo()).to.equal(i);
      console.log(' \u2714 Passed Result Test for rc.regUser() with signers[', i, '].', '\n');

      expect(ethers.utils.formatUnits((await rc.balanceOf(signers[i].address)).toString(), 18)).to.equal("0.018");
      console.log(' \u2714 Passed NewUserAwards Result Test for signers[', i, '].', '\n');
    }

    // Reg new user for signers[2] (as User_7).
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
  
