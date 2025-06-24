// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests the IPR and Ownership control functions of the 
// Platform. Or, more specific, the functions of the smart contract of RegCenter.

// Owner of the Platform has the rights to:
// (1) set Platform Rule to regulate the award policies and commission splitting 
//     rate;
// (2) collect commission incurred by IPR royalties;
// (3) mint CBP to any party;
// (4) transfer the ownerhip title to others.

// Keeper of the Platform has the rights to:
// (1) incorporate a smart contract as Template, so that the author of which may 
//     collect royalties when users calls the smart contracts cloned therefrom; 
// (2) transfer the Keeper’s title to others.

// Author of the Template may:
// (1) automatically collect CBP as royalties for the Template they developed;
// (2) set the Royalty Rule for all its Templates to regulate the promotion 
//     policies concerned; and
// (3) transfer the IPR of its Template to others;

// Scenarios for testing included in this section:
// (1) User_1 (as owner of the Platform) transfers the ownership to the DAO 
//     (User_8), so that the DAO may mint and supply CBP to the users of the 
//     Platform;
// (2) User_1 (as owner of the smart contract of Fuel Tank) transfers the 
//     ownership of Fuel Tank to the DAO, so that, the DAO may sell CBP via Fuel 
//     Tank and collect ETH income therefrom;
// (3) User_1 (as author of all Templates) transfers the IPRs concerned to the 
//     DAO, so that the DAO may collect royalties incurred therefrom.

// Write APIs tested in this section:
// 1. RegCenter
// 1.1 function transferOwnership(address newOwner) external;
// 1.2 function transferIPR(uint typeOfDoc, uint version, 
//     uint transferee) external;

// 2. Ownable
// 2.1 function setNewOwner(address acct) onlyOwner public;

// Events Verified in this section:
// 1. RegCenter
// 1.1 event TransferOwnership(address indexed newOwner);
// 1.2 event TransferIPR(uint indexed typeOfDoc, uint indexed version,
//     uint indexed transferee);


const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { getRC, getFT, getGK, getROS, getCashier, } = require("./boox");
const { printShares } = require("./ros");
const { depositOfUsers } = require("./gk");
const { cbpOfUsers } = require("./rc");

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**   03. Config ComBoox       **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const ft = await getFT();
    const gk = await getGK();
    const ros = await getROS();

    const cashier = await getCashier();


    // ==== Transfer Ownership of Platform to Company ====
    
    await expect(rc.connect(signers[1]).transferOwnership(gk.address)).to.be.revertedWith("UR.mf.OO: not owner");
    console.log(" \u2714 Passed Access Control Test for rc.transferOwnership(). \n");

    await expect(rc.transferOwnership(gk.address)).to.emit(rc, "TransferOwnership");
    console.log(" \u2714 Passed Event Test for rc.TransferOwnership(). \n");

    let newOwner = (await rc.getOwner()).toLowerCase();
    expect(newOwner).to.equal(gk.address.toLowerCase());
    console.log(' \u2714 Passed Result Verify Test for rc.transferOwnership(). \n');

    // ==== Transfer Ownership of Fuel Tank to Company ====

    await ft.setCashier(cashier.address);
    
    let newCashier = (await ft.cashier()).toLowerCase();
    expect(newCashier).to.equal(cashier.address.toLowerCase());
    console.log(' \u2714 Passed Result Verify Test for ft.setCashier(). \n');

    await ft.setNewOwner(gk.address);
    newOwner = (await ft.getOwner()).toLowerCase();
    expect(newOwner).to.equal(gk.address.toLowerCase());
    console.log(' \u2714 Passed Result Verify Test for ft.setNewOwner(). \n');

    await gk.connect(signers[1]).regKeeper(16, ft.address);
    let keeper_16 = (await gk.getKeeper(16)).toLowerCase();
    expect(keeper_16).to.equal(ft.address.toLowerCase());
    console.log(' \u2714 Passed Result Verify Test for usdFT as 16th keeper of the Company. \n');

    // ==== Transfer IPR of Templates to Company ====

    for (let i=1; i<35; i++) {

      tx = await rc.transferIPR(i, 1, 8);
      await tx.wait();
      
      await expect(tx).to.emit(rc, "TransferIPR").withArgs(BigNumber.from(i), BigNumber.from(1), BigNumber.from(8));
      console.log(' \u2714 Passed Event Test for rc.transferIPR() with typeOfDoc', i, ' version 1. \n');
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
  
