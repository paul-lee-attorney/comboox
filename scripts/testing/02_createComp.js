// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { saveBooxAddr } = require("./saveTool");
const { codifyHeadOfShare, printShares } = require('./ros');
const { getCNC, getGK, getROM, getROS, getRC } = require("./boox");
const { now } = require("./utils");
const { parseCompInfo } = require("./gk");

// First step to use ComBoox system is to set up a Company Boox.
// This section displays how the owner of a company creates 
// the entire booking system for their company in ComBoox. 

// Scenarios for testing included in this section:
// 1. User No.1 create the entire booking system in ComBoox with
//    appointing User No.2 as "the secretary" of the company;
// 2. User No.2 (as the secretary) sets the following general  
//    information of the company: 
//    (1) the maximum quantity of members; 
//    (2) the symbol of the company; and
//    (3) the full name of the company.
// 3. User No.2 (as the secretary) set up the initial status
//    of the "Register of Shares" ("ROS") of the company.
//    (1) Share_1: shareholder: User_1, paid: 100k, par: 100k;
//    (2) Share_2: shareholder: User_2, paid: 80k, par: 80k;
//    (3) Share_3: shareholder: User_3, paid: 40k, par: 40k;
//    (4) Share_4: shareholder: User_4, paid: 10k, par: 20k;
// 4. User No.2 (as the secretary) return the control rights
//    to ROS and "Register of Members" ("ROM") back to ROMKeeper. 

// Write APIs tested in this section:
// 1. CreateNewComp
// 1.1 function createComp(address dk) external;

// 2. RegCenter
// 2.1 function createDoc(bytes32 snOfDoc,address primeKeyOfOwner) external;

// 3. Ownable
// 3.1 function init(address owner, address regCenter) external;

// 4. GeneralKeeper
// 4.1 function createCorpSeal() external;
// 4.2 function regKeeper(uint256 title, address keeper) external;
// 4.3 function regBook(uint256 title, address keeper) external;

// 5. AccessControl
// 5.1 function initKeepers(address dk,address gk) external;
// 5.2 function setDirectKeeper(address keeper) external;

// 6. RegisterOfMembers
// 6.1 function setMaxQtyOfMembers(uint max) external;

// 7. RegisterOfShares
// 7.1 function issueShare(bytes32 shareNumber, uint payInDeadline, uint paid, 
//        uint par, uint distrWeight) external;

async function main() {

    console.log('********************************');
    console.log('**    Create Company Boox     **');
    console.log('********************************\n');

    // ==== Get Instances ====

	  const signers = await ethers.getSigners();
    const cnc = await getCNC();
    const rc = await getRC();

    // ==== Create Company ====

    let tx = await cnc.createComp(signers[1].address);
    let receipt = await tx.wait();

    await expect(tx).to.emit(rc, "CreateDoc");
    console.log("Passed Event Test for rc.CreateDoc(). \n");

    const GK = `0x${receipt.logs[0].topics[2].substring(26)}`;
    saveBooxAddr("GK", GK);

    const gk = await getGK(GK);
    
    await expect(tx).to.emit(gk, "SetDirectKeeper").withArgs(signers[1].address);
    console.log("Passed Event Test for gk.SetDirectKeeper(). \n");

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
    
    // User No.1 is NOT the secretary of the company, thus, below call
    // shall be blocked and reversed with error message.
    await expect(gk.setCompInfo(0, symbol, "ComBoox DAO LLC")).to.be.revertedWith("AC.onlyDK: not");
    console.log("Passed Access Control Test for OnlyDK. \n");
    
    await gk.connect(signers[1]).setCompInfo(0, symbol, "ComBoox DAO LLC");
    
    const info = parseCompInfo(await gk.getCompInfo());
    console.log('CompInfo:', info, "\n");
    
    const rom = await getROM();
    
    await rom.connect(signers[1]).setMaxQtyOfMembers(50);
    expect(await rom.maxQtyOfMembers()).to.equal(50);
    console.log("Passed Result Verify Test for rom.setMaxQtyOfMembers. \n");

    const ros = await getROS();

    const issueDate = (new Date('2023-11-08')).getTime()/1000;
    
    const today = await now();
    const payInDeadline = today + 86400 * 180;
    
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

    tx = await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), issueDate, 100000 * 10 ** 4, 100000 * 10 ** 4, 100);
    
    await tx.wait();

    await expect(tx).to.emit(ros, "IssueShare").withArgs(codifyHeadOfShare(head), BigNumber.from(100000 * 10 ** 4), BigNumber.from(100000 * 10 ** 4));
    console.log("Passed Event Test for ros.IssueShare(). \n");

    await expect(tx).to.emit(rom, "AddMember").withArgs(BigNumber.from(1), BigNumber.from(1));
    console.log("Passed Event Test for rom.AddMember(). \n");

    await expect(tx).to.emit(rom, "CapIncrease").withArgs(BigNumber.from(100), BigNumber.from(100000 * 10 ** 4), BigNumber.from(100000 * 10 ** 4), BigNumber.from(100));
    console.log("Passed Event Test for rom.CapIncrease(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(1), BigNumber.from(1));

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

    await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), payInDeadline, 10000 * 10 ** 4, 20000 * 10 ** 4, 100);

    await printShares(ros);

    await ros.connect(signers[1]).setDirectKeeper(ROMKeeper);

    let dk = (await ros.getDK()).toLowerCase();
    expect(dk).to.equal(ROMKeeper.toLowerCase());
    console.log("Passed Result Verify Test for ros.setDirectKeeper(). \n");
    
    await rom.connect(signers[1]).setDirectKeeper(ROMKeeper);
    
    dk = (await rom.getDK()).toLowerCase();
    expect(dk).to.equal(ROMKeeper.toLowerCase());
    console.log("Passed Result Verify Test for rom.setDirectKeeper(). \n");
    
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
