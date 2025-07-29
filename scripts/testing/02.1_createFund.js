// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// First step to use ComBoox system is to set up a Records-Keeping System for
// the fund. This section displays how the manager of a fund creates the 
// entire Records-Keeping System for its fund in ComBoox. 

// Scenarios for testing included in this section:
// (1) User_1 creates the entire Records-Keeping System in ComBoox with 
//     appointing User_2 as "the secretary" of the fund;
// (2) User_2 (as the secretary) sets the following general information of the
//     company: 
//       A.the maximum quantity of members: 50; 
//       B.the symbol of the company: “COMBOOX Fund”; and
//       C.the full name of the company: “ComBoox DAO LLC”.
// (3) User_2 (as the secretary) sets up the initial status of the "Register of
//     Shares" (the "ROS") of the company.
//    __________________________________________________________ 
//    |  Share   | Shareholder | Paid Amt |  Par Amt |  Class  |
//    | Share_1  |    User_1   |   $100   |   $100   |    1    |
//    ----------------------------------------------------------
// (4) User_2 (as the secretary) turns over the Direct Keeper rights of ROS and
//     the "Register of Members" (the "ROM") back to ROMKeeper. 

// Write APIs tested in this section:
// 1. CreateNewFund
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

// Events verified in this scetion:
// 1. RegCenter
// 1.1 event CreateDoc(bytes32 indexed snOfDoc, address indexed body);

// 2. Access Control
// 2.2 event SetDirectKeeper(address indexed keeper);

// 3. Register of Shares
// 3.1 event IssueShare(bytes32 indexed shareNumber, uint indexed paid, uint indexed par);

// 4. Register of Members
// 4.1 event AddMember(uint256 indexed acct, uint indexed qtyOfMembers);
// 4.2 event CapIncrease(uint indexed votingWeight, uint indexed paid, uint indexed par, uint distrWeight);
// 4.3 event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

const { BigNumber, ethers } = require("ethers");
const { expect } = require("chai");
const { saveBooxAddr, setUserCBP, setUserDepo } = require("./saveTool");
const { codifyHeadOfShare, printShares } = require('./ros');
const { getROM, getROS, getRC, refreshBoox, getUSDC, getCNF, getFK, } = require("./boox");
const { now  } = require("./utils");
const { parseCompInfo } = require("./gk");
const { cbpOfUsers } = require("./rc");

async function main() {

    console.log('\n');
    console.log('*******************************');
    console.log('**    02.1 Create Fund Boox  **');
    console.log('*******************************');
    console.log('\n');
    
    // ==== Get Instances ====

	  const signers = await hre.ethers.getSigners();
    const cnf = await getCNF();
    const rc = await getRC();

    // ==== Create Company ====

    let tx = await cnf.createComp(signers[1].address);
    let receipt = await tx.wait();

    await expect(tx).to.emit(rc, "CreateDoc");
    console.log(" \u2714 Passed Event Test for rc.CreateDoc(). \n");

    const FK = ethers.utils.getAddress(`0x${receipt.logs[0].topics[2].substring(26)}`);
    saveBooxAddr("FundKeeper", FK);

    const gk = await getFK(FK);
    
    await expect(tx).to.emit(gk, "SetDirectKeeper").withArgs(signers[1].address);
    console.log(" \u2714 Passed Event Test for gk.SetDirectKeeper(). \n");

    setUserCBP("8", 0n); // No rewards will be granted for CA User;

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

    const ROP = await gk.getROP();
    saveBooxAddr("ROP", ROP);

    const ROS = await gk.getROS();
    saveBooxAddr("ROS", ROS);

    const LOO = await gk.getLOO();
    saveBooxAddr("LOO", LOO);

    const ROI = await gk.getROI();
    saveBooxAddr("ROI", ROI);

    const Cashier = await gk.getCashier();
    saveBooxAddr("Cashier", Cashier);

    const USDC = await gk.getBank();
    saveBooxAddr("USDC", USDC);

    const ROR = await gk.getROR();
    saveBooxAddr("ROR", ROR);

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

    const ROPKeeper = await gk.getKeeper(8);
    saveBooxAddr("ROPKeeper", ROPKeeper);

    const LOOKeeper = await gk.getKeeper(10);
    saveBooxAddr("LOOKeeper", LOOKeeper);

    const ROIKeeper = await gk.getKeeper(11);
    saveBooxAddr("ROIKeeper", ROIKeeper);

    const Accountant = await gk.getKeeper(12);
    saveBooxAddr("Accountant", Accountant);

    const RORKeeper = await gk.getKeeper(16);
    saveBooxAddr("RORKeeper", RORKeeper);

    refreshBoox();

    // ==== Mint Mock USDC to users ====

    let usdc = await getUSDC();

    for (i=0; i<7; i++) {
      await usdc.mint(signers[i].address, 10n ** 12n);
      let balance = await usdc.balanceOf(signers[i].address);
      balance = ethers.utils.formatUnits(balance, 6);
      expect(balance).to.equal('1000000.0');
    }

    // ==== Config Comp ====

    const symbol = ethers.utils.hexlify(ethers.utils.toUtf8Bytes("COMBOOX")).padEnd(40, '0');
    
    await expect(gk.setCompInfo(0, symbol, "ComBoox Fund")).to.be.revertedWith("AC.onlyDK: not");
    console.log(" \u2714 Passed Access Control Test for ac.OnlyDK(). \n");
    
    await gk.connect(signers[1]).setCompInfo(0, symbol, "ComBoox Fund");
    
    const info = parseCompInfo(await gk.getCompInfo());

    expect(info.regNum).to.equal(8);
    expect(info.currency).to.equal('USD');
    expect(info.symbol).to.equal('COMBOOX');
    expect(info.name).to.equal("ComBoox Fund");

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

    tx = await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), issueDate, 100 * 10 ** 4, 100 * 10 ** 4, 100);
    
    await expect(tx).to.emit(ros, "IssueShare").withArgs(codifyHeadOfShare(head), BigNumber.from(100 * 10 ** 4), BigNumber.from(100 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.IssueShare(). \n");

    await expect(tx).to.emit(rom, "AddMember").withArgs(BigNumber.from(1), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for rom.AddMember(). \n");

    await expect(tx).to.emit(rom, "CapIncrease").withArgs(BigNumber.from(100), BigNumber.from(100 * 10 ** 4), BigNumber.from(100 * 10 ** 4), BigNumber.from(100));
    console.log(" \u2714 Passed Event Test for rom.CapIncrease(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(1), BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    // ==== Turn Over Direct Keeper Rights ====

    await ros.connect(signers[1]).setDirectKeeper(ROMKeeper);

    let dk = await ros.getDK();
    expect(dk).to.equal(ROMKeeper);
    console.log(" \u2714 Passed Result Verify Test for ros.setDirectKeeper(). \n");
    
    await rom.connect(signers[1]).setDirectKeeper(ROMKeeper);
    
    dk = await rom.getDK();
    expect(dk).to.equal(ROMKeeper);
    console.log(" \u2714 Passed Result Verify Test for rom.setDirectKeeper(). \n");
    
    setUserDepo("1", 0n);
    setUserDepo("2", 0n);
    setUserDepo("3", 0n);
    setUserDepo("4", 0n);
    setUserDepo("5", 0n);
    setUserDepo("6", 0n);
    setUserDepo("7", 0n);
    setUserDepo("8", 0n);

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
