// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2026 LI LI of JINGTIAN & GONGCHENG.
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

import { network } from "hardhat";
import { getAddress, formatUnits, hexlify, toUtf8Bytes } from "ethers";
import { expect } from "chai";
import { saveBooxAddr, setUserCBP, setUserDepo } from "./saveTool";
import { codifyHeadOfShare, printShares } from './ros';
import { getROM, getROS, getRC, refreshBoox, getUSDC, getCNC, getGK } from "./boox";
import { now } from "./utils";
import { parseCompInfo } from "./gk";
import { cbpOfUsers, getAllUsers } from "./rc";

async function main() {

    console.log('\n');
    console.log('*******************************');
    console.log('**    02.1 Create Fund Boox  **');
    console.log('*******************************');
    console.log('\n');
    
    // ==== Get Instances ====

    const { ethers } = await network.connect();
	  const signers = await ethers.getSigners();
    const cnc = await getCNC();
    const rc = await getRC();

    const users = await getAllUsers(rc, 6);

    // ==== Create Company ====

    let tx = await cnc.createComp(9, signers[1].address);
    let receipt = await tx.wait();

    await expect(tx).to.emit(rc, "ProxyDoc");
    console.log(" \u2714 Passed Event Test for rc.ProxyDoc(). \n");

    // ==== Get FK Addresses ====

    const eventLogs = receipt.logs
      .filter((log) =>
        log.address.toLowerCase() === rc.target.toLowerCase() && 
        log.topics[0] === rc.interface.getEvent('ProxyDoc').topicHash &&
        log.topics[1].substring(0, 10) == '0x25586efd'
      );

    const addrGK = `0x${eventLogs[0].topics[2].substring(26)}`;

    let gk = await getGK(addrGK);
    const userFund = parseCompInfo(await gk.getCompInfo()).regNum;
    console.log("userFund:", userFund, "\n");

    saveBooxAddr("GK", addrGK);

    // const FK = getAddress(`0x${receipt.logs[0].topics[2].substring(26)}`);
    // saveBooxAddr("FundKeeper", FK);

    // const gk = await getFK(FK);
    
    await expect(tx).to.emit(gk, "SetDirectKeeper").withArgs(signers[1].address);
    console.log(" \u2714 Passed Event Test for gk.SetDirectKeeper(). \n");

    setUserCBP(userFund, 0n); // No rewards will be granted for CA User;

    const ROC = await gk.getBook(1);
    saveBooxAddr("ROC", ROC);

    const ROD = await gk.getBook(2);
    saveBooxAddr("ROD", ROD);

    const BMM = await gk.getBook(3);
    saveBooxAddr("BMM", BMM);

    const ROM = await gk.getBook(4);
    saveBooxAddr("ROM", ROM);

    const GMM = await gk.getBook(5);
    saveBooxAddr("GMM", GMM);

    const ROA = await gk.getBook(6);
    saveBooxAddr("ROA", ROA);

    const ROP = await gk.getBook(8);
    saveBooxAddr("ROP", ROP);

    const ROS = await gk.getBook(9);
    saveBooxAddr("ROS", ROS);

    const LOO = await gk.getBook(10);
    saveBooxAddr("LOO", LOO);

    const ROI = await gk.getBook(11);
    saveBooxAddr("ROI", ROI);

    const Cashier = await gk.getBook(15);
    saveBooxAddr("Cashier", Cashier);

    const USDC = await gk.getBook(12);
    saveBooxAddr("USDC", USDC);

    const ROR = await gk.getBook(16);
    saveBooxAddr("ROR", ROR);

    refreshBoox();

    // ==== Mint Mock USDC to users ====

    let usdc = await getUSDC();

    for (let i=0; i<7; i++) {
      await usdc.mint(await signers[i].getAddress(), 10n ** 12n);
      let balance = await usdc.balanceOf(await signers[i].getAddress());
      balance = formatUnits(balance, 6);
      expect(balance).to.equal('1000000.0');
    }

    // ==== Config Comp ====

    const symbol = hexlify(toUtf8Bytes("COMBOOX")).padEnd(38, '0');
    
    // await expect(gk.setCompInfo(0, symbol, "ComBoox Fund")).to.be.revertedWith("AC.onlyDK: not");
    console.log(" \u2714 Passed Access Control Test for ac.OnlyDK(). \n");
    
    await gk.connect(signers[1]).setCompInfo(0, symbol, "ComBoox Fund");
    
    const info = parseCompInfo(await gk.getCompInfo());

    expect(info.regNum).to.equal(userFund);
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
      shareholder: users[0],
      priceOfPaid: 1,
      priceOfPar: 0,
      votingWeight: 100,
    };

    tx = await ros.connect(signers[1]).issueShare(codifyHeadOfShare(head), issueDate, 100 * 10 ** 4, 100 * 10 ** 4, 100);
    
    await expect(tx).to.emit(ros, "IssueShare").withArgs(codifyHeadOfShare(head), 100 * 10 ** 4, 100 * 10 ** 4);
    console.log(" \u2714 Passed Event Test for ros.IssueShare(). \n");

    await expect(tx).to.emit(rom, "AddMember").withArgs(users[0], 1n);
    console.log(" \u2714 Passed Event Test for rom.AddMember(). \n");

    await expect(tx).to.emit(rom, "CapIncrease").withArgs(100n, 100 * 10 ** 4, 100 * 10 ** 4, 100n);
    console.log(" \u2714 Passed Event Test for rom.CapIncrease(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(1n, users[0]);
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    // ==== Turn Over Direct Keeper Rights ====

    await ros.connect(signers[1]).setDirectKeeper(addrGK);

    let dk = (await ros.getDK()).toLowerCase();
    expect(dk).to.equal(addrGK);
    console.log(" \u2714 Passed Result Verify Test for ros.setDirectKeeper(). \n");
    
    await rom.connect(signers[1]).setDirectKeeper(addrGK);
    
    dk = (await rom.getDK()).toLowerCase();
    expect(dk).to.equal(addrGK);
    console.log(" \u2714 Passed Result Verify Test for rom.setDirectKeeper(). \n");
    
    // setUserDepo("1", 0n);
    // setUserDepo("2", 0n);
    // setUserDepo("3", 0n);
    // setUserDepo("4", 0n);
    // setUserDepo("5", 0n);
    // setUserDepo("6", 0n);
    // setUserDepo("7", 0n);
    // setUserDepo("8", 0n);

    await printShares(ros);
    await cbpOfUsers(rc, gk.target, userFund);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
