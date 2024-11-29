// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to execute Call/Put Options stipulated in SHA.

// A Call Option set out in SHA is a contractual right granted to a shareholder 
// (the “option holder”) to purchase equity shares from another shareholder at a
// pre-agreed price or formula, within a specified time period or upon the
// occurrence of certain predefined events. Call options are often used to provide
// flexibility for investors, founders, or strategic partners to increase their
// ownership stake under circumstances, such as meeting performance milestones,
// resolving shareholder disputes, or upon a shareholder’s exit.

// While the call option grants the right to purchase shares, it does not impose
// an obligation to do so, allowing the option holder to exercise this right at
// their discretion during the option period.

// A Put Option in a SHA is a contractual right granted to a shareholder (the
// “option holder”) to sell their equity shares to another shareholder at a
// pre-agreed price or valuation formula, within a specified time frame or upon
// the occurrence of certain events. Put Options are typically included to protect
// shareholders, particularly minority shareholders or investors, by providing a
// guaranteed exit mechanism. They are often triggered in scenarios such as
// disputes, breach of agreement terms, significant changes in the company’s
// structure, or upon the occurrence of specific events like the shareholder’s
// retirement, disability, or death.

// This right ensures that the option holder can sell their shares at a fair
// value, even if there is no open market or willing buyer, mitigating potential
// liquidity risks.

// The scenario for testing in this section are as follows:
// (1) User_2 as secretary of the Company inputs oracle data representing the
//     general revenue and net profits into the Records-Keeping System;
// (2) Due to the trigger condition is satisfied (i.e. general revenue is greater
//     than $5,500,000 and net profits is also greater than $550,000), User_3 (as
//     the operating Member of the Company) executes his Put Option to sell his
//     shares at a price of $1.80 per share to the controlling Members (i.e.
//     User_1 and User_2);
// (3) User_3 creates a Put Option Swap to sell $500 Share_3 to User_2 with its
//     Share_2 as Pledge;
// (4) When the swap expires, User_3 terminates the swap by receiving the pledged
//     Share_2 for an amount equal to the value difference caused by the price
//     difference between the Issue Price of Share_3 ($1.50) and the Put Price
//     ($1.80);
// (5) If another trigger condition is met (i.e. gross revenue is less than
//     $1,000,000 or net profit is less than $100,000), User_2, as the
//     controlling member of the Company, exercises its Call Option to purchase
//     shares of User_3 at the lower price of $1.20 per share to adjust its cost
//     of investment;
// (6) User_2 creates a Call Option Swap to purchase Share_3 amount to $500, and
//     set his Share_2 as Pledge to guarantee the Swap.
// (7) User_2 pay off the Put Option Swap, so that get the $500 target shares by
//     paying at the Call Option price of $1.20 per share.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.1 function updateOracle(uint256 seqOfOpt, uint d1, uint d2, uint d3) external;
// 1.2 function execOption(uint256 seqOfOpt) external;
// 1.3 function createSwap(uint256 seqOfOpt, uint seqOfTarget, uint paidOfTarget,
//     uint seqOfPledge) external;
// 1.4 function payOffSwap(uint256 seqOfOpt, uint256 seqOfSwap) external payable;
// 1.5 function terminateSwap(uint256 seqOfOpt, uint256 seqOfSwap) external;

// Events verified in this section:
// 1. Register of Options
// 1.1 event UpdateOracle(uint256 indexed seqOfOpt, uint indexed data1,
//     uint indexed data2, uint data3);
// 1.2 event ExecOpt(uint256 indexed seqOfOpt);
// 1.3 event RegSwap(uint256 indexed seqOfOpt, bytes32 indexed snOfSwap);

// 2. Register of Shares
// 2.1 event DecreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.2 event IncreaseCleanPaid(uint256 indexed seqOfShare, uint indexed paid);
// 2.3 event SubAmountFromShare(uint256 indexed seqOfShare, uint indexed paid,
//     uint indexed par);

// 3 Register of Members
// 3.1 event AddShareToMember(uint indexed seqOfShare, uint indexed acct);

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROS, getROO, getRC, getROM, } = require("./boox");
const { increaseTime, } = require("./utils");
const { getLatestShare, printShares } = require("./ros");
const { parseOption, parseOracle, parseSwap } = require("./roo");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { depositOfUsers } = require("./gk");
const { transferCBP, addEthToUser } = require("./saveTool");

async function main() {

    console.log('\n********************************');
    console.log('**  15. Call/Put Options      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const roo = await getROO();
    const ros = await getROS();
    const rom = await getROM();
    
    // ==== Update Oracles ====

    await expect(gk.updateOracle(1, 5600 * 10 ** 4, 550 * 10 ** 4, 0)).to.be.revertedWith("AC.onlyDK: not");
    console.log(" \u2714 Passed Access Control Test for gk.updateOracle(). \n");

    let tx = await gk.connect(signers[1]).updateOracle(1, 4500 * 10 ** 4, 550 * 10 ** 4, 0);

    await expect(tx).to.emit(roo, "UpdateOracle").withArgs(BigNumber.from(1), BigNumber.from(4500 * 10 ** 4), BigNumber.from(550 * 10 ** 4), BigNumber.from(0));
    console.log(" \u2714 Passed Event Test for roo.UpdateOracle(). \n");

    let oracle = parseOracle(await roo.getLatestOracle(1)); 

    expect(oracle.data1).to.equal("4,500.0");
    expect(oracle.data2).to.equal("550.0");
    expect(oracle.data3).to.equal("0.0");

    console.log(" \u2714 Passed Result Verify Test for gk.updateOracle(). \n");

        
    // ==== Execute Option ====

    await expect(gk.connect(signers[1]).execOption(1)).to.be.revertedWith("OR.mf.onlyRightholder: not");
    console.log(" \u2714 Passed Access Control Test for gk.execOption(). \n");  

    await expect(gk.connect(signers[3]).execOption(1)).to.be.revertedWith("OR.EO: conds not satisfied");
    console.log(" \u2714 Passed Condition Check Test for gk.execOption(). \n");  

    await gk.connect(signers[1]).updateOracle(1, 5500 * 10 ** 4, 550 * 10 ** 4, 0);

    tx = await gk.connect(signers[3]).execOption(1);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 18n, "gk.execOption().");

    transferCBP("3", "8", 18n);

    await expect(tx).to.emit(roo, "ExecOpt").withArgs(BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for roo.ExecOpt(). \n");

    let opt = parseOption(await roo.getOption(1));

    expect(opt.body.state).to.equal("Executed");
    
    console.log(" \u2714 Passed Result Verify Test for gk.execOption(). \n");

    // ==== Update Oracles & Exec Option 2 ====

    await gk.connect(signers[1]).updateOracle(2, 800 * 10 ** 4, 120 * 10 ** 4, 0);

    await gk.connect(signers[1]).execOption(2);

    transferCBP("2", "8", 18n);

    // ==== Create Swap ====
    
    await expect(gk.connect(signers[1]).createSwap(1, 3, 500 * 10 ** 4, 2)).to.be.revertedWith("OR.mf.onlyRightholder: not");
    console.log(" \u2714 Passed Access Control Test for gk.createSwap(). \n");  

    tx = await gk.connect(signers[3]).createSwap(1, 3, 500 * 10 ** 4, 2);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 36n, "gk.createSwap().");

    transferCBP("3", "8", 36n);

    await expect(tx).to.emit(roo, "RegSwap");
    console.log(" \u2714 Passed Event Test for roo.RegSwap(). \n");

    await expect(tx).to.emit(ros, "DecreaseCleanPaid");
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n");

    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n");

    let swap = parseSwap(await roo.getSwap(1, 1));

    expect(swap.seqOfSwap).to.equal(1);
    expect(swap.seqOfTarget).to.equal(3);
    expect(swap.paidOfTarget).to.equal("500.0");
    expect(swap.priceOfDeal).to.equal("1.8");
    expect(swap.seqOfPledge).to.equal(2);

    console.log(" \u2714 Passed Result Verify Test for gk.execOption(). PutOption \n");
  
    await gk.connect(signers[1]).createSwap(2, 3, 500 * 10 ** 4, 2);

    transferCBP("2", "8", 36n);

    swap = parseSwap(await roo.getSwap(2, 1));

    expect(swap.seqOfSwap).to.equal(1);
    expect(swap.seqOfTarget).to.equal(3);
    expect(swap.paidOfTarget).to.equal("500.0");
    expect(swap.priceOfDeal).to.equal("1.1");
    expect(swap.seqOfPledge).to.equal(2);

    console.log(" \u2714 Passed Result Verify Test for gk.execOption(). CallOption \n");

    // ==== Exec Call Option ====

    const centPrice = await gk.getCentPrice();
    let value = 110n * 500n * BigInt(centPrice);

    await expect(gk.connect(signers[1]).payOffSwap(2, 1, {value:value - 100n})).to.be.revertedWith("SWR.payOffSwap: insufficient amt");
    console.log(" \u2714 Passed Value Check Test for gk.payOffSwap(). \n");  

    await expect(gk.payOffSwap(2, 1, {value:value + 100n})).to.be.revertedWith("ROOK.payOffSwap: wrong payer");    
    console.log(" \u2714 Passed Access Control Test for gk.payOffSwap(). \n");  

    tx = await gk.connect(signers[1]).payOffSwap(2, 1, {value:value + 100n});

    addEthToUser(value, "3");
    addEthToUser(100n, "2");

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 58n, "gk.payOffSwap().");

    transferCBP("2", "8", 58n);

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(3), BigNumber.from(500 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    await expect(tx).to.emit(ros, "SubAmountFromShare").withArgs(BigNumber.from(3), BigNumber.from(500 * 10 ** 4), BigNumber.from(500 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.SubAmountFromShare(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(25), BigNumber.from(2));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    let share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(25);
    expect(share.head.shareholder).to.equal(2);
    expect(share.body.paid).to.equal("500.0");
    expect(share.body.cleanPaid).to.equal("500.0");

    console.log(" \u2714 Passed Result Verify Test for rom.payOffSwap(). \n");

    // ==== Exec Put Option ====

    await increaseTime(86400 * 4);

    tx = await gk.connect(signers[3]).terminateSwap(1, 1);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.payOffSwap().");

    transferCBP("3", "8", 58n);

    await expect(tx).to.emit(ros, "IncreaseCleanPaid");
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    await expect(tx).to.emit(ros, "SubAmountFromShare").withArgs(BigNumber.from(2), BigNumber.from(300 * 10 ** 4), BigNumber.from(300 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.SubAmountFromShare(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(26), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(26);
    expect(share.head.shareholder).to.equal(3);
    expect(share.body.paid).to.equal("300.0");
    expect(share.body.cleanPaid).to.equal("300.0");

    console.log(" \u2714 Passed Result Verify Test for rom.terminateSwap(). \n");

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
