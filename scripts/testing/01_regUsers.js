// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { pfrCodifier, pfrParser } = require('./rc');
const { getRC } = require("./boox");
const { expect } = require("chai");
const { AddrZero } = require('./utils');

// This section is to test the functions for registering new
// users in ComBoox. Each new user may obtain a sum of awards
// for its registration, rate of which is defined in Platform 
// Rule. And, the Platform Rule can only be set and revised by
// the owner of the Platform. Currently, the owner is ComBoox DAO.

// We prepared totally 7 users (User No.1 - No.7) for the testing
// program. User No.1 - No. 4 will be the founding members of the 
// Company. And, User No.5 - No.6 will act as external investors
// in some scenarios like Drag/Tag Along deals and Listing Deals. 

// Write APIs tested in this section:
// RegCenter:
// 1. function setPlatformRule(bytes32 snOfRule) external;
// 2. function mint(address to, uint amt) external;
// 3. function regUser() external;

async function main() {

    console.log('********************************');
    console.log('**         Reg Users          **');
    console.log('********************************\n');

    // ==== Obtain Instances ====

	  const signers = await ethers.getSigners();
    const rc = await getRC();

    // ==== Set Platform Rule ====

    let pfr = pfrParser(await rc.getPlatformRule());

    // Set new user awards for each EOA account as 0.018 CBP. 
    pfr.eoaRewards = "0.018";
    const snOfPFR = pfrCodifier(pfr);

    await expect(rc.setPlatformRule(snOfPFR)).to.emit(rc, "SetPlatformRule").withArgs(snOfPFR);
    console.log('Passed Event Test for SetPlatformRule. \n');

    expect(pfrParser(await rc.getPlatformRule()).eoaRewards).to.equal("0.018");
    console.log('Passed Verification Test for rc.setPlatformRule func. \n');

    // ==== Reg Users ====

    // User_1 and User_2 are two special Users registered during the deploying 
    // process of ComBoox, thus, they cannot get new user awards. This "mint"
    // process is to provide enough start up CBP for them to go through this 
    // test process.
    await expect(rc.mint(signers[0].address, 8n * 10n ** 18n)).to.emit(rc, "Transfer").withArgs(AddrZero, signers[0].address, 8n * 10n ** 18n);

    await rc.mint(signers[1].address, 8n * 10n ** 18n);

    // Reg new users for signers[3-7].
    for (let i = 3; i<7; i++) {
      await rc.connect(signers[i]).regUser();

      expect(await rc.connect(signers[i]).getMyUserNo()).to.equal(i);
      console.log('Passed UserNo test for signers[', i, '].', '\n');

      expect(ethers.utils.formatUnits((await rc.balanceOf(signers[i].address)).toString(), 18)).to.equal("0.018");
      console.log('Passed NewUserAwards test for signers[', i, '].', '\n');
    }

    // Reg new user for signers[2] (as User_7).
    await rc.connect(signers[2]).regUser();
    expect(await rc.connect(signers[2]).getMyUserNo()).to.equal(7);
    console.log('Passed UserNo test for signers[', 2, '].', '\n');

    expect(ethers.utils.formatUnits((await rc.balanceOf(signers[2].address)).toString(), 18)).to.equal("0.018");
    console.log('Passed NewUserAwards test for signers[', 2, '].', '\n');

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
