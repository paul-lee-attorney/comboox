// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
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

// 8. USDKeeper
// 8.1 function payInCapital(ICashier.TransferAuth memory auth, uint seqOfShare, uint paid) external;

// 2. Ownable
// 2.1 function setNewOwner(address acct) onlyOwner public;

// Events Verified in this section:
// 1. RegCenter
// 1.1 event TransferOwnership(address indexed newOwner);
// 1.2 event TransferIPR(uint indexed typeOfDoc, uint indexed version,
//     uint indexed transferee);


import { expect } from "chai";
import { getRC, getFT, getGK, getROS, getCashier, getTypeByName, getUSDC } from "./boox";
import { printShares, parseShare } from "./ros";
import { cbpOfUsers, getAllUsers, royaltyTest } from "./rc";
import { generateAuth } from "./sigTools";
import { transferCBP } from "./saveTool";
import { network } from "hardhat";
import { getContractWithSigner, readTool } from "../readTool";
import { parseCompInfo } from "./gk";
import { now } from "./utils";

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**    03 Config ComBoox DAO   **');
    console.log('********************************');
    console.log('\n');
    
    const { ethers } = await network.connect();
	  const signers = await ethers.getSigners();

    const rc = await getRC();
    const ft = await getFT();

    let gk = await getGK();
    const cashier = await getCashier();
    const users = await getAllUsers(rc, 6);
    const userComp = await parseCompInfo(await gk.getCompInfo()).regNum;
    const ros = await getROS();

    // ==== Pay In Capital in USD ====
    
    gk = await readTool("ROMKeeper", gk.target);

    // console.log("ROMK.interfaces:", gk.interface.fragments[2]);

    let auth = await generateAuth(signers[4], cashier.target, 7500);
    console.log("auth:", auth);

    let tx = await gk.connect(signers[4]).payInCapital(auth, 4n, 5000n * 10n ** 4n);
    console.log("Transaction hash:", tx.hash, "\n");

    await royaltyTest(rc.target, signers[4].address, signers[0].address, tx, 36n, "ROMK.payInCapital().");

    // setUserDepo("8", 0n);
    // setUserDepo("4", 0n);
    
    // setUserDepo("1", 0n);
    // setUserDepo("2", 0n);
    // setUserDepo("3", 0n);
    // setUserDepo("5", 0n);
    // setUserDepo("6", 0n);
    // setUserDepo("7", 0n);

    console.log("users[4]:", users[4], "users[0]:", users[0], "\n");
    transferCBP(users[4], users[0], 36n);

    // console.log("Transferred 36 CBP from userNo", users[4].toString(), "to userNo", users[0].toString(), "\n");

    // console.log("gk:", gk.target, "\n");

    await expect(tx).to.emit(gk, "PayInCapital");
    console.log(" \u2714 Passed Event Test for RomKeeper.PayInCapital(). \n");
    
    let share = parseShare(await ros.getShare(4));

    expect(share.body.paid).to.equal("20,000.0");
    console.log(" \u2714 Passed Result Verify Test for RomKeeper.payInCapital(). \n");

    // ==== Transfer Ownership of Platform to Company ====
    
    // await expect(rc.connect(signers[1]).transferOwnership(gk.address)).to.be.revertedWith("UR.mf.OO: not owner");
    // console.log(" \u2714 Passed Access Control Test for rc.transferOwnership(). \n");

    await expect(rc.transferOwnership(gk.target)).to.emit(rc, "TransferOwnership");
    console.log(" \u2714 Passed Event Test for rc.TransferOwnership(). \n");

    let newOwner = (await rc.getOwner()).toLowerCase();
    expect(newOwner).to.equal((gk.target).toLowerCase());
    console.log(' \u2714 Passed Result Verify Test for rc.transferOwnership(). \n');

    // ==== Transfer Ownership of Fuel Tank to Company ====

    await ft.connect(signers[1]).setCashier(cashier.target);

    let newCashier = (await ft.cashier()).toLowerCase();
    expect(newCashier).to.equal(cashier.target.toLowerCase());
    console.log(' \u2714 Passed Result Verify Test for ft.setCashier(). \n');

    // await ft.setNewOwner(gk.target);
    // newOwner = (await ft.getOwner()).toLowerCase();
    // expect(newOwner).to.equal((gk.target).toLowerCase());
    // console.log(' \u2714 Passed Result Verify Test for ft.setNewOwner(). \n');

    gk = await readTool("GeneralKeeper", gk.target);

    await gk.connect(signers[1]).regKeeper(16, ft.target);
    let keeper_16 = (await gk.getKeeper(16)).toLowerCase();
    expect(keeper_16).to.equal((ft.target).toLowerCase());
    console.log(' \u2714 Passed Result Verify Test for usdFT as 16th keeper of the Company. \n');

    // ==== Transfer IPR of Templates to Company ====

    const transferIPR = async (nameOfTemp)=>{
      const typeOfDoc = getTypeByName(nameOfTemp);

      let tx = await rc.transferIPR(typeOfDoc, 1, userComp);
      await tx.wait();
      
      await expect(tx).to.emit(rc, "TransferIPR").withArgs(typeOfDoc, 1, userComp);
      console.log(' \u2714 Passed Event Test for rc.transferIPR() with', typeOfDoc, 'version 1. \n');
    }

    await transferIPR("GeneralKeeper");
    await transferIPR("ROCKeeper");
    await transferIPR("RODKeeper");
    await transferIPR("BMMKeeper");
    await transferIPR("ROMKeeper");
    await transferIPR("GMMKeeper");
    await transferIPR("ROAKeeper");
    await transferIPR("ROOKeeper");
    await transferIPR("ROPKeeper");
    await transferIPR("SHAKeeper");
    await transferIPR("Accountant");
    await transferIPR("ROIKeeper");
    await transferIPR("LOOKeeper");
    await transferIPR("Cashier");

    await printShares(ros);
    await cbpOfUsers(rc, gk.target, userComp);
    // await depositOfUsers(rc, gk);
    
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
