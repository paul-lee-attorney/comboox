// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { saveBooxAddr } = require("./saveTool");
const { codifyHeadOfShare, printShares } = require('./ros');
const { getCNC, getGK, getROM, getROS } = require("./boox");
const { parseTimestamp } = require("./utils");

const parseCompInfo = (arr) => {
  const info = {
    regNum: arr[0],
    regDate: parseTimestamp(arr[1]),
    currency: arr[2],
    state: arr[3],
    symbol: ethers.utils.toUtf8String(arr[4]),
    name: arr[5],
  }

  return info;
}

async function main() {

	  const signers = await hre.ethers.getSigners();
    console.log('Acct_1:', signers[0].address, "Acct_2:", signers[1].address, "\n");

    const cnc = await getCNC();

    // ==== Create Company ====

    let tx = await cnc.createComp(signers[1].address);
    let receipt = await tx.wait();

    const GK = `0x${receipt.logs[0].topics[2].substring(26)}`;
    saveBooxAddr("GK", GK);

    const gk = await getGK(GK);
    
    const ROC = await gk.getROC();
    saveBooxAddr("ROC", ROC);

    const ROD = await gk.getROD();
    saveBooxAddr("ROD", ROD);

    const BMM = await gk.getBMM();
    saveBooxAddr("BMM", BMM);

    const ROM = await gk.getROM();
    saveBooxAddr("ROM", ROM);

    const GMM = await gk.getGMM();
    saveBooxAddr("GMM", GMM);

    const ROA = await gk.getROA();
    saveBooxAddr("ROA", ROA);

    const ROO = await gk.getROO();
    saveBooxAddr("ROO", ROO);

    const ROP = await gk.getROP();
    saveBooxAddr("ROP", ROP);

    const ROS = await gk.getROS();
    saveBooxAddr("ROS", ROS);

    const LOO = await gk.getLOO();
    saveBooxAddr("LOO", LOO);

    const ROCKeeper = await gk.getKeeper(1);
    saveBooxAddr("ROCKeeper", ROCKeeper);

    const RODKeeper = await gk.getKeeper(2);
    saveBooxAddr("RODKeeper", RODKeeper);

    const BMMKeeper = await gk.getKeeper(3);
    saveBooxAddr("BMMKeeper", BMMKeeper);

    const ROMKeeper = await gk.getKeeper(4);
    saveBooxAddr("ROMKeeper", ROMKeeper);

    const GMMKeeper = await gk.getKeeper(5);
    saveBooxAddr("GMMKeeper", GMMKeeper);

    const ROAKeeper = await gk.getKeeper(6);
    saveBooxAddr("ROAKeeper", ROAKeeper);

    const ROOKeeper = await gk.getKeeper(7);
    saveBooxAddr("ROOKeeper", ROOKeeper);

    const ROPKeeper = await gk.getKeeper(8);
    saveBooxAddr("ROPKeeper", ROPKeeper);

    const SHAKeeper = await gk.getKeeper(9);
    saveBooxAddr("SHAKeeper", SHAKeeper);

    const LOOKeeper = await gk.getKeeper(10);
    saveBooxAddr("LOOKeeper", LOOKeeper);

    // ==== Config Comp ====

    const symbol = ethers.utils.hexlify(ethers.utils.toUtf8Bytes("COMBOOX")).padEnd(40, '0');
    await gk.connect(signers[1]).setCompInfo(0, symbol, "ComBoox DAO LLC");
    
    const info = parseCompInfo(await gk.getCompInfo());
    console.log('CompInfo:', info, "\n");
    
    const rom = await getROM();
    rom.connect(signers[1]).setMaxQtyOfMembers(0);

    const ros = await getROS();
    let issueDate = (new Date('2023-11-08')).getTime()/1000;
    
    let head = {
      class: 1,
      seqOfShare: 1,
      preSeq: 0,
      issueDate: issueDate,
      shareholder: 1,
      priceOfPaid: 1,
      priceOfPar: 0,
      votingWeight: 100,
    };

    await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), issueDate, 100000 * 10 ** 4, 100000 * 10 ** 4, 100);
    
    head = {
      class: 1,
      seqOfShare: 2,
      preSeq: 0,
      issueDate: issueDate,
      shareholder: 2,
      priceOfPaid: 1,
      priceOfPar: 0,
      votingWeight: 100,
    };

    await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), issueDate, 80000 * 10 ** 4, 80000 * 10 ** 4, 100);

    head = {
      class: 2,
      seqOfShare: 3,
      preSeq: 0,
      issueDate: issueDate,
      shareholder: 3,
      priceOfPaid: 1.5,
      priceOfPar: 0,
      votingWeight: 100,
    };

    await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), issueDate, 40000 * 10 ** 4, 40000 * 10 ** 4, 100);

    head = {
      class: 2,
      seqOfShare: 4,
      preSeq: 0,
      issueDate: issueDate,
      shareholder: 4,
      priceOfPaid: 1.5,
      priceOfPar: 0,
      votingWeight: 100,
    };

    await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), issueDate, 10000 * 10 ** 4, 20000 * 10 ** 4, 100);

    await printShares(ros);

    ros.connect(signers[1]).setDirectKeeper(gk.address);
    console.log('return Key of ROS \n');

    rom.connect(signers[1]).setDirectKeeper(gk.address);
    console.log('return Key of ROM \n');
    
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
