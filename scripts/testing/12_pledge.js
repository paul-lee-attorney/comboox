// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { getGK, getROP, getROS, } = require("./boox");
const { increaseTime, } = require("./utils");
const { codifyHeadOfPledge, parsePledge } = require("./rop");
const { printShare } = require("./ros");

async function main() {

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const rop = await getROP();
    const ros = await getROS();
    
    // ==== Create Pledge ====

    let headOfPld = {
      seqOfShare: 7,
      seqOfPld: 0,
      createDate: 0,
      daysToMaturity: 10, 
      guaranteeDays: 10,
      creditor: 6,
      debtor: 2,
      pledgor: 3,
      state: 0,
    };

    await gk.connect(signers[3]).createPledge(codifyHeadOfPledge(headOfPld), 8000 * 10 ** 4, 8000 * 10 ** 4, 4000 * 10 ** 4, 5);
    console.log('created pledges on share 7', parsePledge(await rop.getPledge(7, 1)), '\n');

    await printShare(ros, 7);
    

    // ==== Transfer Pledge ====

    await gk.connect(signers[6]).transferPledge(7, 1, 5, 2000 * 10 ** 4);
    console.log('transfer half of pledge on share 7.  Get All Pledges:', (await rop.getAllPledges()).map(v => parsePledge(v)), '\n');

    // ==== Refund Debts ====

    await gk.connect(signers[5]).refundDebt(7, 2, 1000 * 10 ** 4);
    console.log('refund half of pledge 2 on share 7', parsePledge(await rop.getPledge(7, 2)), '\n');

    await printShare(ros, 7);

    // ==== Extend Pledge ====

    await increaseTime(86400 * 6);

    await gk.connect(signers[3]).extendPledge(7, 1, 10);
    console.log('extend pledge 1 on share 7', parsePledge(await rop.getPledge(7, 1)), '\n');

    // ==== Release Pledge ====

    await gk.connect(signers[5]).lockPledge(7, 2, ethers.utils.id('Spring is coming'));
    console.log('locked pld 2 on share 7', parsePledge(await rop.getPledge(7, 2)), '\n');

    await gk.connect(signers[3]).releasePledge(7, 2, 'Spring is coming');
    console.log('release pld 2 on share 7', (await rop.getPledgesOfShare(7)).map(v => parsePledge(v)), '\n');

    await printShare(ros, 7);

    // ==== Execute Pledge ====

    await increaseTime(86400 * 20);

    await gk.connect(signers[6]).execPledge(7, 1, 6, 6);
    console.log('exec pledge 1 on share 7', parsePledge(await rop.getPledge(7, 1)), '\n');

    await printShare(ros, 7);

    // ==== Revoke Pledge ====

    headOfPld = {
      seqOfShare: 7,
      seqOfPld: 0,
      createDate: 0,
      daysToMaturity: 2, 
      guaranteeDays: 2,
      creditor: 6,
      debtor: 2,
      pledgor: 3,
      state: 0,
    };

    await gk.connect(signers[3]).createPledge(codifyHeadOfPledge(headOfPld), 4000 * 10 ** 4, 4000 * 10 ** 4, 2000 * 10 ** 4, 5);
    console.log('created pledges on share 7', parsePledge(await rop.getPledge(7, 3)), '\n');

    await printShare(7);

    // ---- Read API ----

    console.log('Counter of Pledge:', await rop.counterOfPledges(7), '\n');
    console.log('Pledge No', 1, 'on Share', 7, 'Is Pledge ?', await rop.isPledge(7, 3), '\n');
    console.log('get SN list of ROP:', await rop.getSNList(), '\n');

    await increaseTime(86400 * 5);

    await gk.connect(signers[3]).revokePledge(7, 3);
    console.log('created pledges on share 7', parsePledge(await rop.getPledge(7, 3)), '\n');

    await printShare(ros, 7);
  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
