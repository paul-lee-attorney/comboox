// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { getRC, getFT, getGK } = require("./boox");

async function main() {

	  const signers = await hre.ethers.getSigners();
    console.log('Acct_1:', signers[0].address, "Acct_2:", signers[1].address, "\n");

    const rc = await getRC();
    const ft = await getFT();
    const gk = await getGK();

    // ==== Transfer Ownership of Platform to Company ====

    await rc.transferOwnership(gk.address);
    let newOwner = await rc.getOwner();
    console.log('newOwner of ComBoox:', newOwner, '\n');

    // ==== Transfer Ownership of Fuel Tank to Company ====

    await ft.setNewOwner(gk.address);
    newOwner = await ft.getOwner();
    console.log('newOwner of FuelTank:', newOwner, '\n');

    // ==== Transfer IPR of Templates to Company ====

    for (let i=1; i<28; i++) {
      tx = await rc.transferIPR(i, 1, 8);
      receipt = await tx.wait();
      console.log('IPR of typeOfDoc', Number(receipt.logs[0].topics[1]),'version', Number(receipt.logs[0].topics[2]), 'transfered to User', Number(receipt.logs[0].topics[3]), '\n');
    }
    
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
