// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// First step to use ComBoox system is to set up a Records-Keeping System for
// the company. This section displays how the owner of a company creates the 
// entire Records-Keeping System for its company in ComBoox. 

// Scenarios for testing included in this section:
// (1) User_1 creates the entire Records-Keeping System in ComBoox with 
//     appointing User_2 as "the secretary" of the company;
// (2) User_2 (as the secretary) sets the following general information of the
//     company: 
//       A.the maximum quantity of members: 50; 
//       B.the symbol of the company: “COMBOOX”; and
//       C.the full name of the company: “ComBoox DAO LLC”.
// (3) User_2 (as the secretary) sets up the initial status of the "Register of
//     Shares" (the "ROS") of the company.
//    ________________________________________________ 
//    |  Share   | Shareholder | Paid Amt |  Par Amt |
//    | Share_1  |    User_1   | $100,000 | $100,000 |
//    | Share_2  |    User_2   | $80,000  | $80,000  |
//    | Share_3  |    User_3   | $40,000  | $40,000  |
//    | Share_4  |    User_4   | $10,000  | $20,000  |
//    ------------------------------------------------
// (4) User_2 (as the secretary) wrongly issues a new Share_5, and removes the 
//     same off the ROS shortly.
// (5) User_2 (as the secretary) turns over the Direct Keeper rights of ROS and
//     the "Register of Members" (the "ROM") back to ROMKeeper. 
// (6) User_2 (as the secretary) locks paid-in capital amount to $5,000 on 
//     Share_4 with hash lock.
// (7) User_4 unlock the hash locks with the correct string key, which indicates
//     it has already paid consideration in exchange of the key, so that obtained
//     the paid-in capital.
// (8) User_2 (as the secretary) locks paid-in capital amount to $5,000 again on
//     Share_4 with hash lock.
// (9) After the expiration of the pay in deadline, User_2 withdraws the locked 
//     amount back from the hash lock.
// (10) User_4 pays in ETH directly to increase the paid-in capital of Share_4 by
//      $5,000. 

// Write APIs tested in this section:
// 1. CreateNewComp
// 1.1 function createComp(address dk) external;

// 2. RegCenter
// 2.1 function createDoc(bytes32 snOfDoc,address primeKeyOfOwner) external;

// 3. GeneralKeeper
// 3.1 function createCorpSeal() external;
// 3.2 function regKeeper(uint256 title, address keeper) external;
// 3.3 function regBook(uint256 title, address keeper) external;

// 4. AccessControl
// 4.1 function setDirectKeeper(address keeper) external;

// 5. RegisterOfMembers
// 5.1 function setMaxQtyOfMembers(uint max) external;

// 6. RegisterOfShares
// 6.1 function issueShare(bytes32 shareNumber, uint payInDeadline, uint paid, 
//     uint par, uint distrWeight) external;
// 6.2 function decreaseCapital(uint256 seqOfShare, uint paid, uint par) external;

// 7. GeneralKeeper
// 7.1 function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, 
//     bytes32 hashLock) external;
// 7.2 function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;
// 7.3 function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;
// 7.4 function payInCapital(uint seqOfShare, uint amt) external payable;

// Events verified in this scetion:
// 1. RegCenter
// 1.1 event CreateDoc(bytes32 indexed snOfDoc, address indexed body);

// 2. Access Control
// 2.2 event SetDirectKeeper(address indexed keeper);

// 3. Register of Shares
// 3.1 event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par);
// 3.2 event SetPayInAmt(bytes32 indexed headSn, bytes32 indexed hashLock);
// 3.3 event DeregisterShare(uint256 indexed seqOfShare);
// 3.4 event PayInCapital(uint256 indexed seqOfShare, uint indexed amount);
// 3.5 event WithdrawPayInAmt(uint indexed seqOfShare, uint indexed amount);

// 4. Register of Members
// 4.1 event AddMember(uint256 indexed acct, uint indexed qtyOfMembers);
// 4.2 event CapIncrease(uint indexed votingWeight, uint indexed paid, uint indexed par, uint distrWeight);
// 4.3 event AddShareToMember(uint indexed seqOfShare, uint indexed acct);
// 4.4 event CapDecrease(uint indexed votingWeight, uint indexed paid, uint indexed par, uint distrWeight);
// 4.5 event RemoveShareFromMember(uint indexed seqOfShare, uint indexed acct);
// 4.6 event ChangeAmtOfMember(uint indexed acct, uint indexed paid, 
//     uint indexed par, bool increase);

const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { saveBooxAddr } = require("./saveTool");
const { codifyHeadOfShare, parseShare } = require('./ros');
const { getCNC, getGK, getROM, getROS, getRC, refreshBoox } = require("./boox");
const { now, increaseTime } = require("./utils");
const { parseCompInfo } = require("./gk");
const { readContract } = require("../readTool");
const { royaltyTest } = require("./rc");

async function main() {

    console.log('\n********************************');
    console.log('**   02. Create Company Boox  **');
    console.log('********************************\n');

    // ==== Get Instances ====

	  const signers = await hre.ethers.getSigners();
    const cnc = await getCNC();
    const rc = await getRC();

    // ==== Create Company ====

    let tx = await cnc.createComp(signers[1].address);
    let receipt = await tx.wait();

    await expect(tx).to.emit(rc, "CreateDoc");
    console.log(" \u2714 Passed Event Test for rc.CreateDoc(). \n");

    const GK = ethers.utils.getAddress(`0x${receipt.logs[0].topics[2].substring(26)}`);
    saveBooxAddr("GK", GK);

    const gk = await getGK(GK);
    
    await expect(tx).to.emit(gk, "SetDirectKeeper").withArgs(signers[1].address);
    console.log(" \u2714 Passed Event Test for gk.SetDirectKeeper(). \n");

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

    refreshBoox();

    // ==== Config Comp ====

    const symbol = ethers.utils.hexlify(ethers.utils.toUtf8Bytes("COMBOOX")).padEnd(40, '0');
    
    await expect(gk.setCompInfo(0, symbol, "ComBoox DAO LLC")).to.be.revertedWith("AC.onlyDK: not");
    console.log(" \u2714 Passed Access Control Test for ac.OnlyDK(). \n");
    
    await gk.connect(signers[1]).setCompInfo(0, symbol, "ComBoox DAO LLC");
    
    const info = parseCompInfo(await gk.getCompInfo());

    expect(info.regNum).to.equal(8);
    expect(info.currency).to.equal('USD');
    expect(info.symbol).to.equal('COMBOOX');
    expect(info.name).to.equal("ComBoox DAO LLC");

    console.log(' \u2714 Passed Result Verify Test for gk.setCompInfo(). \n');
    
    const rom = await getROM();
    
    await rom.connect(signers[1]).setMaxQtyOfMembers(50);
    expect(await rom.maxQtyOfMembers()).to.equal(50);
    console.log(" \u2714 Passed Result Verify Test for rom.setMaxQtyOfMembers(). \n");

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
    
    await expect(tx).to.emit(ros, "IssueShare").withArgs(codifyHeadOfShare(head), BigNumber.from(100000 * 10 ** 4), BigNumber.from(100000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.IssueShare(). \n");

    await expect(tx).to.emit(rom, "AddMember").withArgs(BigNumber.from(1), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for rom.AddMember(). \n");

    await expect(tx).to.emit(rom, "CapIncrease").withArgs(BigNumber.from(100), BigNumber.from(100000 * 10 ** 4), BigNumber.from(100000 * 10 ** 4), BigNumber.from(100));
    console.log(" \u2714 Passed Event Test for rom.CapIncrease(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(1), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

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

    head = {
      class: 2,
      seqOfShare: 5,
      preSeq: 0,
      issueDate: issueDate,
      shareholder: 5,
      priceOfPaid: 1.5,
      priceOfPar: 0,
      votingWeight: 100,
    };

    await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), payInDeadline, 20000 * 10 ** 4, 20000 * 10 ** 4, 100);

    // ==== Decrease Capital ====

    tx = await ros.connect(signers[1]).decreaseCapital(5, 20000 * 10 ** 4, 20000 * 10 ** 4);

    await tx.wait();

    await expect(tx).to.emit(rom, "CapDecrease").withArgs(BigNumber.from(100), BigNumber.from(20000 * 10 ** 4), BigNumber.from(20000 * 10 ** 4), 100);
    console.log(" \u2714 Passed Event Test for rom.CapDecrease(). \n");

    await expect(tx).to.emit(rom, "RemoveShareFromMember").withArgs(BigNumber.from(5), BigNumber.from(5));
    console.log(" \u2714 Passed Event Test for rom.RemoveShareFromMember(). \n");

    await expect(tx).to.emit(ros, "DeregisterShare").withArgs(BigNumber.from(5));
    console.log(" \u2714 Passed Event Test for ros.DeregisterShare(). \n");

    // ==== Turn Over Direct Keeper Rights ====

    await ros.connect(signers[1]).setDirectKeeper(ROMKeeper);

    let dk = await ros.getDK();
    expect(dk).to.equal(ROMKeeper);
    console.log(" \u2714 Passed Result Verify Test for ros.setDirectKeeper(). \n");
    
    await rom.connect(signers[1]).setDirectKeeper(ROMKeeper);
    
    dk = await rom.getDK();
    expect(dk).to.equal(ROMKeeper);
    console.log(" \u2714 Passed Result Verify Test for rom.setDirectKeeper(). \n");

    // ==== Pay In Capital by Hash Lock ====

    let expireDate = today + 86400 * 3;
    let hashLock = ethers.utils.id('Today is Monday.');
    tx = await gk.connect(signers[1]).setPayInAmt(4, 5000 * 10 ** 4, expireDate, hashLock);

    await tx.wait();

    await expect(tx).to.emit(ros, "SetPayInAmt");
    console.log(" \u2714 Passed Event Test for ros.SetPayInAmt(). \n");

    tx = await gk.connect(signers[4]).requestPaidInCapital(hashLock, 'Today is Monday.');

    await tx.wait();

    await expect(tx).to.emit(rom, "CapIncrease").withArgs(BigNumber.from(100), BigNumber.from(5000 * 10 ** 4), 0, BigNumber.from(100));
    console.log(" \u2714 Passed Event Test for rom.CapIncrease(). \n");

    await expect(tx).to.emit(rom, "ChangeAmtOfMember").withArgs(BigNumber.from(4), BigNumber.from(5000 * 10 ** 4), 0, true);
    console.log(" \u2714 Passed Event Test for rom.ChangeAmtOfMember(). \n");

    await expect(tx).to.emit(ros, "PayInCapital").withArgs(BigNumber.from(4), BigNumber.from(5000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.PayInCapital(). \n");

    // ==== Withdraw Locked Capital ====

    hashLock = ethers.utils.id('Today is Tuesday.');

    tx = await gk.connect(signers[1]).setPayInAmt(4, 5000 * 10 ** 4, expireDate, hashLock);

    await increaseTime(86400 * 3);

    tx = await gk.connect(signers[1]).withdrawPayInAmt(hashLock, 4);

    await expect(tx).to.emit(ros, "WithdrawPayInAmt").withArgs(BigNumber.from(4), BigNumber.from(5000 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.WithdrawPayInAmt(). \n");

    // ==== Pay In Capital in ETH ====

    const centPrice = await gk.getCentPrice();
    let value = 150n * 5000n * BigInt(centPrice);

    tx = await gk.connect(signers[4]).payInCapital(4, 5000 * 10 ** 4, {value: value + 100n});

    await royaltyTest(rc.address, signers[4].address, signers[0].address, tx, 36n, "gk.payInCapital().");

    await expect(tx).to.emit(gk, "SaveToCoffer");
    console.log(" \u2714 Passed Event Test for gk.SaveToCoffer(). \n");

    const romKeeper = await readContract("ROMKeeper", ROMKeeper);

    await expect(tx).to.emit(romKeeper, "PayInCapital");
    console.log(" \u2714 Passed Event Test for romKeeper.PayInCapital(). \n");
    
    let share = parseShare(await ros.getShare(4));

    expect(share.body.paid).to.equal("20,000.0");
    console.log(" \u2714 Passed Result Verify Test for gk.payInCapital(). \n");
    
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
