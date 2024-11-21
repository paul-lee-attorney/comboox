// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */
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
