// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { getRC, getFT, getGK } = require("./boox");

// This section we will test the IPR and Ownership control
// functions of the Platform. Or, more specificly, the 
// functions of the smart contract of RegCenter.

// Owner of the Platform has the rights to:
// (1) set Platform Rule to regulate the award policies
//     and commission splitting rate;
// (2) collect commission incurred by IPR royalties;
// (3) mint CBP to any party;
// (4) transfer the ownerhip title to others.

// Keeper of the Platform has the rights to:
// (1) incorporate a smart contract as Template, so that 
//     the author of which may collect royalties when 
//     users calls the smart contracts cloned therefrom;
// (2) transfer the Keeper title to others;

// Author of the Template may:
// (1) automatically collect CBP as royalites for the 
//     Template they developed;
// (2) set the Royalty Rule for all its works to regulate 
//     the promotion policies concerned;
// (3) transfer the IPR of certain Template to others;

// Scenarios for testing included in this section:
// 1. User No.1 (as owner of the Platform) transfer 
//    the ownership to the Company (User No.8), so that
//    the Company may mint and supply CBP to the users
//    of the Platform;
// 2. User No.1 (as owner of the smart contract of 
//    Fuel Tnak) transfer the ownership to Fuel Tank
//    to the Company, so that, the Company may sell
//    CBP via Fuel Tank and collect ETH income therefrom;
// 3. User No.1 (as author of all Templates) transfer 
//    the IPRs concerned to the Company, so that
//    the Company will collect all royalties in CBP when
//    users call the relevant API of the smart contracts
//    cloned from the Templates.

// Write APIs tested in this section:
// 1. RegCenter
// 1.1 function transferOwnership(address newOwner) external;
// 1.2 function transferIPR(uint typeOfDoc, uint version, 
//     uint transferee) external;
// 2. Ownable
// 2.1 function setNewOwner(address acct) onlyOwner public;

async function main() {

    console.log('********************************');
    console.log('**       Config ComBoox       **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const ft = await getFT();
    const gk = await getGK();

    // ==== Transfer Ownership of Platform to Company ====

    // User_2 is not the owner of RegCenter, thus,
    // below call will be blocked and reverted with
    // error message.
    
    await expect(rc.connect(signers[1]).transferOwnership(gk.address)).to.be.revertedWith("UR.mf.OO: not owner");
    console.log("Passed Access Control Test for rc.transferOwnership(). \n");

    await expect(rc.transferOwnership(gk.address)).to.emit(rc, "TransferOwnership");
    console.log("Passed Event Test for rc.TransferOwnership(). \n");

    let newOwner = (await rc.getOwner()).toLowerCase();
    expect(newOwner).to.equal(gk.address.toLowerCase());
    console.log('Passed Result Verify Test for rc.transferOwnership(). \n');

    // ==== Transfer Ownership of Fuel Tank to Company ====

    await ft.setNewOwner(gk.address);
    newOwner = (await ft.getOwner()).toLowerCase();
    expect(newOwner).to.equal(gk.address.toLowerCase());
    console.log('Passed Result Verify Test for ft.setNewOwner(). \n');

    // ==== Transfer IPR of Templates to Company ====

    for (let i=1; i<28; i++) {
      
      tx = await rc.transferIPR(i, 1, 8);
      await tx.wait();
      
      await expect(tx).to.emit(rc, "TransferIPR").withArgs(BigNumber.from(i), BigNumber.from(1), BigNumber.from(8));
      console.log('Passed Event Test for rc.transferIPR() with typeOfDoc', i, ' version 1. \n');
    }
    
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
