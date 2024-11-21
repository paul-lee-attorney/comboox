// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to execute Call/Put Options sepecified in SHA.

// A call option in the context of a shareholders’ agreement is a contractual right
// granted to a party (the “option holder”) to purchase equity shares from another 
// shareholder or the company at a pre-agreed price or formula, within a specified 
// time period or upon the occurrence of certain predefined events.

// Call options are often used to provide flexibility for investors, founders, or 
// strategic partners to increase their ownership stake under specific circumstances, 
// such as meeting performance milestones, resolving shareholder disputes, or upon a 
// shareholder’s exit.

// While the call option grants the right to purchase shares, it does not impose an 
// obligation to do so, allowing the option holder to exercise this right at their 
// discretion during the option period.

// A put option in a shareholders’ agreement is a contractual right granted to a 
// shareholder (the “option holder”) to sell their equity shares to another party 
// (such as another shareholder or the company) at a pre-agreed price or valuation 
// formula, within a specified time frame or upon the occurrence of certain events.

// Put options are typically included to protect shareholders, particularly minority 
// shareholders or investors, by providing a guaranteed exit mechanism. They are often
// triggered in scenarios such as disputes, breach of agreement terms, significant 
// changes in the company’s structure, or upon the occurrence of specific events like 
// the shareholder’s retirement, disability, or death.

// This right ensures that the option holder can sell their shares at a fair value, 
// even if there is no open market or willing buyer, mitigating potential liquidity 
// risks.

// The scenario for testing in this section are as follows:
// 1. User_2 as secretary of the Company input oracle data indicating the general 
//    revenue and net profits into the system;
// 2. Due the trigger condition is satisfied (i.e. general revenue is greater than
//    $5,500,000 and net profits is greater than $550,000), User_3 as the operating
//    Member of the Company executes his Put Option to sell his shares at a price of
//    $1.80 per share to the controlling Members User_1 and User_2;
// 3. User_3 creates a Put Option Swap to sell Share_3 amount to $500, and set Share_2
//    as Pledge to the Put Option;
// 4. After the expiration of the Swap, User_3 terminate the Swap by obtaining the 
//    Pledged shares by the difference value between the target share's issue value 
//    and the value calculated based on the Put Option price;
// 5. Whe another trigger condition is satisfied (i.e. general revenue is lower than
//    $1,000,000 or net profits is lower than $100,000), User_2 as the controlling
//    Members of the Company executes his Call Option to purchase shares of User_3
//    at a lower price of $1.20 per share so as to adjust their investment cost;
// 6. User_2 create a Call Option Swap to purchase Share_3 amount to $500, and set
//    his Share_2 as Pledge to guarantee the Swap.
// 7. User_2 pay off the Put Option Swap, so that get the $500 target shares by 
//    paying at the Call Option price of $1.20 per share.

// The Write APIs tested in this section include:
// 1. General Keper
// 1.1 function updateOracle(uint256 seqOfOpt, uint d1, uint d2, uint d3) external;
// 1.2 function execOption(uint256 seqOfOpt) external;
// 1.3 function createSwap(uint256 seqOfOpt, uint seqOfTarget, uint paidOfTarget,
//     uint seqOfPledge) external;
// 1.4 function payOffSwap(uint256 seqOfOpt, uint256 seqOfSwap) external payable;
// 1.5 function terminateSwap(uint256 seqOfOpt, uint256 seqOfSwap) external;

const { expect } = require("chai");
const { BigNumber } = require("ethers");

const { getGK, getROS, getROO, getRC, getROM, } = require("./boox");
const { increaseTime, } = require("./utils");
const { getLatestShare } = require("./ros");
const { parseOption, parseOracle, parseSwap } = require("./roo");
const { royaltyTest } = require("./rc");

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

    await expect(tx).to.emit(roo, "ExecOpt").withArgs(BigNumber.from(1));
    console.log(" \u2714 Passed Event Test for roo.ExecOpt(). \n");

    let opt = parseOption(await roo.getOption(1));

    expect(opt.body.state).to.equal("Executed");
    
    console.log(" \u2714 Passed Result Verify Test for gk.execOption(). \n");

    // ==== Update Oracles & Exec Option 2 ====

    await gk.connect(signers[1]).updateOracle(2, 800 * 10 ** 4, 120 * 10 ** 4, 0);
    await gk.connect(signers[1]).execOption(2);

    // ==== Create Swap ====
    
    await expect(gk.connect(signers[1]).createSwap(1, 3, 500 * 10 ** 4, 2)).to.be.revertedWith("OR.mf.onlyRightholder: not");
    console.log(" \u2714 Passed Access Control Test for gk.createSwap(). \n");  

    tx = await gk.connect(signers[3]).createSwap(1, 3, 500 * 10 ** 4, 2);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 36n, "gk.createSwap().");

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

    swap = parseSwap(await roo.getSwap(2, 1));

    expect(swap.seqOfSwap).to.equal(1);
    expect(swap.seqOfTarget).to.equal(3);
    expect(swap.paidOfTarget).to.equal("500.0");
    expect(swap.priceOfDeal).to.equal("1.1");
    expect(swap.seqOfPledge).to.equal(2);

    console.log(" \u2714 Passed Result Verify Test for gk.execOption(). CallOption \n");

    // ==== Exec Call Option ====

    const centPrice = await gk.getCentPrice();
    let value = 110n * 500n * BigInt(centPrice) - 100n;

    await expect(gk.connect(signers[1]).payOffSwap(2, 1, {value:value})).to.be.revertedWith("SWR.payOffSwap: insufficient amt");
    console.log(" \u2714 Passed Value Check Test for gk.payOffSwap(). \n");  

    value += 200n;

    await expect(gk.payOffSwap(2, 1, {value:value})).to.be.revertedWith("ROOK.payOffSwap: wrong payer");    
    console.log(" \u2714 Passed Access Control Test for gk.payOffSwap(). \n");  

    tx = await gk.connect(signers[1]).payOffSwap(2, 1, {value:value});

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 58n, "gk.payOffSwap().");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid").withArgs(BigNumber.from(3), BigNumber.from(500 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    await expect(tx).to.emit(ros, "SubAmountFromShare").withArgs(BigNumber.from(3), BigNumber.from(500 * 10 ** 4), BigNumber.from(500 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.SubAmountFromShare(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(24), BigNumber.from(2));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    let share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(24);
    expect(share.head.shareholder).to.equal(2);
    expect(share.body.paid).to.equal("500.0");
    expect(share.body.cleanPaid).to.equal("500.0");

    console.log(" \u2714 Passed Result Verify Test for rom.payOffSwap(). \n");

    // ==== Exec Put Option ====

    await increaseTime(86400 * 4);

    tx = await gk.connect(signers[3]).terminateSwap(1, 1);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.payOffSwap().");

    await expect(tx).to.emit(ros, "IncreaseCleanPaid");
    console.log(" \u2714 Passed Event Test for ros.IncreaseCleanPaid(). \n");

    await expect(tx).to.emit(ros, "SubAmountFromShare").withArgs(BigNumber.from(2), BigNumber.from(300 * 10 ** 4), BigNumber.from(300 * 10 ** 4));
    console.log(" \u2714 Passed Event Test for ros.SubAmountFromShare(). \n");

    await expect(tx).to.emit(rom, "AddShareToMember").withArgs(BigNumber.from(25), BigNumber.from(3));
    console.log(" \u2714 Passed Event Test for rom.AddShareToMember(). \n");

    share = await getLatestShare(ros);

    expect(share.head.seqOfShare).to.equal(25);
    expect(share.head.shareholder).to.equal(3);
    expect(share.body.paid).to.equal("300.0");
    expect(share.body.cleanPaid).to.equal("300.0");

    console.log(" \u2714 Passed Result Verify Test for rom.terminateSwap(). \n");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
