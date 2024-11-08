// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const path = require("path");
const fs = require("fs");
const tempsDir = path.join(__dirname, "..", "..", "server", "src", "contracts");
const { readContract } = require("../readTool"); 
const { saveBooxAddr } = require("./saveTool");
const { codifyHeadOfShare, parseHeadOfShare, pfrCodifier, pfrParser, longDataParser } = require('./utils');


async function main() {

    const fileNameOfContractAddrList = path.join(tempsDir, "contracts-address.json");
    const Temp = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));

    const fileNameOfBoox = path.join(__dirname, "boox.json");
    const Boox = JSON.parse(fs.readFileSync(fileNameOfBoox));

	  const signers = await hre.ethers.getSigners();
    console.log('Acct_1:', signers[0].address, "Acct_2:", signers[1].address, "\n");

    const rc = await readContract("RegCenter", Temp.RegCenter);
    const ft = await readContract("FuelTank", Temp.FuelTank);

    // ==== Set Platform Rule ====


    let pfr = pfrParser(await rc.getPlatformRule());
    console.log("Obtained PlatformRule:", pfr);

    pfr.eoaRewards = "0.018";
    await rc.setPlatformRule(pfrCodifier(pfr));
    pfr = pfrParser(await rc.getPlatformRule());
    console.log("Updated PlatformRule:", pfr, "\n");

    // ==== Reg Users ====

    await rc.mint(signers[0].address, 8n * 10n ** 18n);
    await rc.mint(signers[1].address, 8n * 10n ** 18n);

    for (let i = 3; i<7; i++) {
      await rc.connect(signers[i]).regUser();
      console.log('RegUser:', await rc.connect(signers[i]).getMyUserNo());
      console.log('Balance Of CBP:', ethers.utils.formatUnits((await rc.balanceOf(signers[i].address)), 18), "\n");
    }
    await rc.connect(signers[2]).regUser();
    console.log('RegUser:', await rc.connect(signers[2]).getMyUserNo());
    console.log('Balance Of CBP:', ethers.utils.formatUnits((await rc.balanceOf(signers[2].address)), 18), "\n");

    // ==== Create Company ====

    const cnc = await readContract("CreateNewComp", Temp.CreateNewComp);
    let tx = await cnc.createComp(signers[1].address);
    let receipt = await tx.wait();

    const GK = `0x${receipt.logs[0].topics[2].substring(26)}`;
    saveBooxAddr("GK", GK);

    const gk = await readContract("GeneralKeeper", GK);
    
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
    
    const info = await gk.getCompInfo();
    console.log('CompInfo:', info);
    console.log('Symbol:', ethers.utils.toUtf8String(info[4]));
    const regDate = new Date(info[1]*1000);
    console.log('RegDate:', regDate.toUTCString(), '\n');
    
    const rom = await readContract("RegisterOfMembers", ROM);
    rom.connect(signers[1]).setMaxQtyOfMembers(0);

    const ros = await readContract("RegisterOfShares", ROS);

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

    let filter = ros.filters.IssueShare();
    let events = await ros.queryFilter(filter);

    events.forEach((log)=>{
      console.log("BlkNo:", log.blockNumber);
      console.log("IssuedShare:", parseHeadOfShare(log.topics[1]), 'with Paid:', longDataParser(ethers.utils.formatUnits(log.topics[2], 4)), 'and Par:', longDataParser(ethers.utils.formatUnits(log.topics[3], 4)), "\n");
    });

    ros.connect(signers[1]).setDirectKeeper(gk.address);
    console.log('return Key of ROS \n');

    rom.connect(signers[1]).setDirectKeeper(gk.address);
    console.log('return Key of ROM \n');

    // ==== Transfer Ownership of Platform to Company ====

    await rc.transferOwnership(Boox.GK);
    let newOwner = await rc.getOwner();
    console.log('newOwner of ComBoox:', newOwner, '\n');

    // ==== Transfer Ownership of Fuel Tank to Company ====

    await ft.setNewOwner(Boox.GK);
    newOwner = await ft.getOwner();
    console.log('newOwner of FuelTank:', newOwner, '\n');

    // ==== Transfer IPR of Templates to Company ====

    for (let i=1; i<28; i++) {
      tx = await rc.transferIPR(i, 1, 8);
      receipt = await tx.wait();
      console.log('IPR of typeOfDoc', Number(receipt.logs[0].topics[1]),'version', Number(receipt.logs[0].topics[2]), 'was transfered to User', Number(receipt.logs[0].topics[3]), '\n');
    }
    
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
