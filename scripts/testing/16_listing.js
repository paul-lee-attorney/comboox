// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { getGK, getROM, getLOO, getROS, } = require("./boox");
const { parseShare, parseHeadOfShare } = require("./ros");
const { parseNode, parseOrder, parseDeal, parseData } = require("./loo");
const { longDataParser } = require("./utils");

async function main() {

    console.log('********************************');
    console.log('**        Listing Deals       **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const loo = await getLOO();
    const ros = await getROS();
    const rom = await getROM();

    // ==== Events Listeners ====
    
    ros.on("IssueShare", (sn, paid, par)=>{
      const head = parseHeadOfShare(sn);
      console.log('Share', head.seqOfShare, 'with Paid', ethers.utils.formatUnits(paid.toString(), 4), 'and Par', ethers.utils.formatUnits(par.toString(), 4), 'issued to User', head.shareholder, '\n');
    });

    rom.on("AddShareToMember", async (seqOfShare, acct)=>{
      console.log('Share', parseShare(await ros.getShare(seqOfShare)), '\n', 'transferred to User', acct.toString(), '\n');
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

    // ==== Parse Logs ====

    const parseLogs = async (tx) => {
      const receipt = await tx.wait();

      let seqOfOrder = 0;
      let orderPlaced = {};
      let orderWithdrawn = [];
      let orderExpired = [];
      let dealClosed = [];
      
      const eventAbi = [
        "event OrderPlaced(bytes32 indexed order, bool indexed isOffer)",
        "event OrderWithdrawn(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer)",
        "event DealClosed(bytes32 indexed deal, uint indexed consideration)",
        "event OrderExpired(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer)",
      ];
      
      const iface = new ethers.utils.Interface(eventAbi);

      receipt.logs.forEach((log) => {

        if (log.address.toLowerCase() == loo.address.toLowerCase()) {
          try {
            const parsedLog = iface.parseLog(log);

            if (parsedLog.name == "OrderPlaced") {

              orderPlaced = {
                order: parseDeal(parsedLog.args[0]), 
                isOffer: parsedLog.args[1],
              };

            } else if (parsedLog.name == "OrderWithdrawn") {

              orderWithdrawn.push({
                node: parseNode(parsedLog.args[0]), 
                data: parseData(parsedLog.args[1]), 
                isOffer: parsedLog.args[2],
              });

            } else if (parsedLog.name == "DealClosed") {

              dealClosed.push({
                deal: parseDeal(parsedLog.args[0]),
                consideration: longDataParser(ethers.utils.formatUnits(parsedLog.args[1].toString(), 18)),
              });

            } else if (parsedLog.name == "OrderExpired") {

              orderExpired.push({
                node: parseNode(parsedLog.args[0]),
                data: parseData(parsedLog.args[1]), 
                isOffer: parsedLog.args[2],
              });

            }

          } catch (err) {

            console.log('parse logs error:', err);

          }
        }

      });

      if (orderPlaced?.order?.paid > '0.0') {
        seqOfOrder = await loo.counterOfOrders(2, orderPlaced.isOffer);
        orderPlaced.seqOfOrder = seqOfOrder;
        console.log('Order Placed: \n', orderPlaced, '\n');
      }

      if (orderWithdrawn.length > 0) 
        console.log('Orders withdrawn: \n', orderWithdrawn, '\n');

      if (orderExpired.length > 0) 
        console.log('Orders expired: \n', orderExpired, '\n');

      if (dealClosed.length > 0) 
        console.log('Deals closed: \n', dealClosed, '\n');

      return seqOfOrder;
    }

    let seqOfOrder = 0;

    // ==== List Initial Offer ====

    let tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024);
    // await printOrder(true);
    await parseLogs(tx);

    tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 3.8 * 10 ** 4, 1024);
    // await printOrder(true);
    await parseLogs(tx);

    tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 4 * 10 ** 4, 1024);
    // await printOrder(true);
    seqOfOrder = await parseLogs(tx);

    if (seqOfOrder > 0)
      tx = await gk.withdrawInitialOffer(2, seqOfOrder, 1024);
    // console.log('Init Offer', seqOfOrder, 'is withdrawn \n');   
    await parseLogs(tx);

    // ==== Place Buy Order ====

    const centPrice = await gk.getCentPrice();
    let value = 370n * 80n * BigInt(centPrice) + 100n;
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 3.7 * 10 ** 4, 1, {value: value});
    // console.log('placed 1st buy order.\n');
    await parseLogs(tx);

    value = 390n * 80n * BigInt(centPrice) + 100n;
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 3.9 * 10 ** 4, 1, {value: value});
    // console.log('placed 2nd buy order.\n');
    await parseLogs(tx);

    value = 400n * 80n * BigInt(centPrice) + 100n;
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 4 * 10 ** 4, 1, {value: value});
    // console.log('placed 3rd buy order.\n');
    await parseLogs(tx);

    value = 420n * 80n * BigInt(centPrice) + 100n;
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 4.2 * 10 ** 4, 1, {value: value});
    // console.log('placed 4th buy order.\n');
    seqOfOrder = await parseLogs(tx);

    // let ordersList = await printOrdersList(false);
    // seqOfOrder = ordersList.length - 1;

    if (seqOfOrder > 0)
      tx = await gk.connect(signers[1]).withdrawBuyOrder(2, seqOfOrder);
    // console.log('4th buy order withdrawn.\n');
    await parseLogs(tx);

    // ==== Place Sell Order ====

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 4.2 * 10 ** 4, 1024);
    // console.log('placed 1st sell order.\n');
    await parseLogs(tx);


    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 4 * 10 ** 4, 1024);
    // console.log('placed 2nd sell order.\n');
    await parseLogs(tx);

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.8 * 10 ** 4, 1024);
    // console.log('placed 3rd sell order.\n');
    await parseLogs(tx);

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024);
    // console.log('placed 4th sell order.\n');    
    seqOfOrder = await parseLogs(tx);
    
    // ordersList = await printOrdersList(true);
    // seqOfOrder = ordersList.length - 1;

    if (seqOfOrder > 0)
        tx = await gk.connect(signers[3]).withdrawSellOrder(2, seqOfOrder);
    // console.log('the 4th sell order is withdrawn \n');    
    await parseLogs(tx);

    // ==== Place Market Buy Order ====

    value = 390n * 80n * BigInt(centPrice) + 100n;
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 1, 80 * 10 ** 4, 0, {value: value});
    // console.log('placed market buy order.\n');
    await parseLogs(tx);
    
    // ==== Place Market Sell Order ====

    value = 400n * 80n * BigInt(centPrice) + 100n;
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 1, 80 * 10 ** 4, 4 * 10 ** 4, {value: value});
    // console.log('placed buy order.\n');
    await parseLogs(tx);

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 0, 1024);
    // console.log('placed sell order.\n');
    await parseLogs(tx);

    // await printOrdersList(true);
    // await printOrdersList(false);

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
