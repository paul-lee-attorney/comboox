// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { getGK, getROM, getLOO, getROS, } = require("./boox");
const { parseShare, parseHeadOfShare } = require("./ros");
const { parseNode, parseOrder } = require("./loo");

async function main() {

    console.log('********************************');
    console.log('**         Deposits           **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const loo = await getLOO();
    const ros = await getROS();
    const rom = await getROM();

    // ==== Events Listeners ====
    
    ros.on("IssueShare", (sn, paid, par)=>{
      const head = parseHeadOfShare(sn);
      console.log('Share', head.seqOfShare);
      console.log('with Paid', ethers.utils.formatUnits(paid.toString(), 4));
      console.log('and Par', ethers.utils.formatUnits(par.toString(), 4));
      console.log('issued to User', head.shareholder, '\n');
    });

    rom.on("AddShareToMember", async (seqOfShare, acct)=>{
      console.log('Share', parseShare(await ros.getShare(seqOfShare), '\n', 'transferred to User', acct.toString(), '\n'));
    });

    gk.on("SaveToCoffer", (acct, value, reason) => {
      console.log('ETH amount to', ethers.utils.formatUnits(value.toString(), 18), 'deposit to account of User', acct.toString(), 'for reason of', ethers.utils.parseBytes32String(reason), '\n');
    });

    gk.on("SaveToCoffer", (acct, value, reason) => {
      console.log('ETH amount to', ethers.utils.formatUnits(value.toString(), 18), 'deposit to account of User', acct.toString(), 'for reason of', ethers.utils.parseBytes32String(reason), '\n');
    });

    gk.on("ReceivedCash", (acct, value) => {
      console.log('ETH amount to', ethers.utils.formatUnits(value.toString(), 18), 'received from', acct.toString(), '\n');
    });

    gk.on("ReleaseCustody", (from, to, amt, reason) => {
      console.log('Custody ETH amount to', ethers.utils.formatUnits(amt.toString(), 18), 'released from', from.toString(), 'to', to.toString(), 'for reason of', ethers.utils.parseBytes32String(reason), '\n');
    });

    // ==== Order Print ====

    const printOrder = async (isOffer) => {
      const list = await loo.getOrders(2, isOffer);
      const seqOfOrder = list.length - 1;
      const order = parseOrder(await loo.getOrder(2, seqOfOrder, isOffer));
      console.log(isOffer ? 'Sell Order': 'Buy Order', seqOfOrder, 'is created as', order, '\n');
      return seqOfOrder;
    }  

    const printOrdersList = async (isOffer) => {
      const list = (await loo.getOrders(2, isOffer)).map(v => parseOrder(v));
      console.log(isOffer ? 'Sell Orders List': 'Buy Orders List', '\n', list);
      return list;
    }  

    // ==== List Initial Offer ====

    await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024);
    await printOrder(true);

    await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 3.8 * 10 ** 4, 1024);
    await printOrder(true);

    await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 4 * 10 ** 4, 1024);
    let seqOfOrder = await printOrder(true);

    await gk.withdrawInitialOffer(2, seqOfOrder, 1024);
    console.log('Init Offer', seqOfOrder, 'is withdrawn \n');   

    // ==== Place Buy Order ====

    const centPrice = await gk.getCentPrice();
    let value = 370n * 80n * BigInt(centPrice) + 100n;
    await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 3.7 * 10 ** 4, 1, {value: value});
    console.log('placed 1st buy order.\n');

    value = 390n * 80n * BigInt(centPrice) + 100n;
    await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 3.9 * 10 ** 4, 1, {value: value});
    console.log('placed 2nd buy order.\n');

    value = 400n * 80n * BigInt(centPrice) + 100n;
    await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 4 * 10 ** 4, 1, {value: value});
    console.log('placed 3rd buy order.\n');

    value = 420n * 80n * BigInt(centPrice) + 100n;
    await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 4.2 * 10 ** 4, 1, {value: value});
    console.log('placed 4th buy order.\n');

    let ordersList = await printOrdersList(false);
    seqOfOrder = ordersList.length - 1;

    await gk.connect(signers[1]).withdrawBuyOrder(2, seqOfOrder);
    console.log('4th buy order withdrawn.\n');

    // ==== Place Sell Order ====

    await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 4 * 10 ** 4, 1024);
    console.log('placed 1st sell order.\n');

    await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.8 * 10 ** 4, 1024);
    console.log('placed 2nd sell order.\n');

    await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024);
    console.log('placed 3rd sell order.\n');

    await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.4 * 10 ** 4, 1024);
    console.log('placed 4th sell order.\n');    
    
    ordersList = await printOrdersList(true);
    seqOfOrder = ordersList.length - 1;

    await gk.connect(signers[3]).withdrawSellOrder(2, seqOfOrder);
    console.log('the 4th sell order is withdrawn \n');    

    // ==== Place Market Buy Order ====

    value = 390n * 80n * BigInt(centPrice) + 100n;
    await gk.connect(signers[1]).placeBuyOrder(2, 1, 80 * 10 ** 4, 0, {value: value});
    console.log('placed market buy order.\n');
    
    // ==== Place Market Sell Order ====

    value = 400n * 80n * BigInt(centPrice) + 100n;
    await gk.connect(signers[1]).placeBuyOrder(2, 1, 80 * 10 ** 4, 4 * 10 ** 4, {value: value});
    console.log('placed buy order.\n');

    await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 0, 1024);
    console.log('placed sell order.\n');

    await printOrdersList(true);
    await printOrdersList(false);

    ros.off("IssueShare");
    rom.off("AddShareToMember");
    gk.off("SaveToCoffer");
    gk.off("ReceivedCash");
    gk.off("ReleaseCustody");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
