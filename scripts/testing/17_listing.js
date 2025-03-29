// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to trade equity shares by listing on the List
// of Orders (the “LOO”).

// Companies may set out their listing rules in SHA. Thereafter, the authorized
// officer may place initial offers on the List of Orders, and, Members of the class
// of shares concerned may place limited sell orders with intended sell price or
// market sell order. Accredited Investors approved by the authorized officers may
// place limited buy orders with specific bid price or market buy order. 

// Listed trades are settled via ETH as consideration. Buyers pay ETH together with
// placing buy orders. In case of closing, the consideration ETH will be
// automatically saved to the seller's deposit account, and the remaining amount of
// ETH will be refunded to the buyer's deposit account. As for the listed buy order,
// the paid ETH will be stored in the buyer's deposit account, and will be released
// to the seller in case of closing, or refunded back to the buyer in case of
// expiration.

// Exchange rate between ETH and the booking currencies is retrieved from the
// reliable oracle provider of crypto market prices like ChainLink. 

// The scenario for testing in this section are as follows:
// (1) User_1 as Chairman of the DAO places and withdraws initial offers as per the
//     listing rule;
// (2) User_2 as an accredited Investor places and withdraws limited buy orders
//     with the LOO, thus, matching and closing certain initial offers. Upon
//     closing, ETH paid by User_2 will be saved in General Keeper as capital
//     contribution income of the DAO, and certain new Shares will be issued to
//     User_2;
// (3) Balance of the limited buy orders placed by User_2 will be listed on the
//     List of Orders, and, the ETH paid will be stored in the custody account
//     of User_2;
// (4) User_3 as Member of the DAO, places and withdraws limited sell orders with
//     the List of Orders. Thereafter, some of the sell orders will be matched with
//     the listed buy orders placed by User_2.  Upon closing, the shares of the
//     sell order will be transferred to User_2, and the ETH under custody will be
//     released to User_3 as consideration, or be released to User_2 as refunded
//     balance amount.
// (5) User_2 places market buy order so as to purchase off listed offers from the LOO;
// (6) User_3 places market sell order so as to match off listed bids from the LOO; 

// The Write APIs tested in this section include:
// 1. General Keper
// 1.1 function placeInitialOffer(uint classOfShare, uint execHours, uint paid, uint price,
//     uint seqOfLR) external;
// 1.2 function withdrawInitialOffer(uint classOfShare, uint seqOfOrder, 
//     uint seqOfLR) external;
// 1.3 function placeSellOrder(uint seqOfClass, uint execHours, uint paid,
//     uint price, uint seqOfLR) external;
// 1.4 function withdrawSellOrder(uint classOfShare, uint seqOfOrder) external;    
// 1.5 function placeBuyOrder(uint classOfShare, uint paid, uint price,
//     uint execHours) external payable;
// 1.6 function withdrawBuyOrder(uint classOfShare, uint seqOfOrder) external;

// Events verified in this section:
// 1. Register of Shares
// 1.1 event IncreaseEquityOfClass(bool indexed isIncrease, uint indexed class, uint indexed amt);

// 2. List of Orders
// 2.1 event OrderPlaced(bytes32 indexed order, bool indexed isOffer);
// 2.2 event OrderWithdrawn(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer);
// 2.3 event DealClosed(bytes32 indexed deal, uint indexed consideration);
// 2.4 event OrderExpired(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer);

// 3. General Keeper
// 3.1 event SaveToCoffer(uint indexed acct, uint256 indexed value, bytes32 indexed reason);
// 3.2 event ReleaseCustody(uint indexed from, uint indexed to, uint indexed amt, bytes32 reason);

// 4. LOO Keeper
// 4.1 event CloseBidAgainstInitOffer(uint indexed buyer, uint indexed amt)


const { expect } = require("chai");
const { getGK, getLOO, getROS, getRC, getLOOKeeper, } = require("./boox");
const { getLatestShare, printShares } = require("./ros");
const { parseNode, parseDeal, parseData } = require("./loo");
const { royaltyTest, cbpOfUsers } = require("./rc");
const { getDealValue } = require("./roa");
const { depositOfUsers } = require("./gk");
const { transferCBP, addEthToUser } = require("./saveTool");

async function main() {

    console.log('\n********************************');
    console.log('**    17.  Listing Deals      **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getGK();
    const loo = await getLOO();
    const ros = await getROS();
    const looKeeper = await getLOOKeeper();

    // ==== Parse Logs ====

    const parseEthLogs = async (tx) => {
      const receipt = await tx.wait();
      
      let toComp = [];
      let toCoffer = [];
      let fromCustody = [];

      const eventAbi = [
        "event SaveToCoffer(uint indexed acct, uint256 indexed value, bytes32 indexed reason)",
        "event ReleaseCustody(uint indexed from, uint indexed to, uint indexed amt, bytes32 reason)", 
        "event CloseBidAgainstInitOffer(uint indexed buyer, uint indexed amt)",
        "event ChargeRoyalty(uint indexed typeOfDoc, uint version, uint indexed rate, uint indexed user, uint author)",
      ];
      
      const iface = new ethers.utils.Interface(eventAbi);

      receipt.logs.forEach((log) => {

        if (log.address == gk.address) {
          try {
            const parsedLog = iface.parseLog(log);

            if (parsedLog.name == "SaveToCoffer") {

              toCoffer.push({
                acct: parseInt(parsedLog.args[0].toString()),
                value: BigInt(parsedLog.args[1].toString()),
                reason: ethers.utils.parseBytes32String(parsedLog.args[2]),
              });

            } else if (parsedLog.name == "ReleaseCustody") {

              fromCustody.push({
                from: parseInt(parsedLog.args[0].toString()), 
                to: parseInt(parsedLog.args[1].toString()), 
                value: BigInt(parsedLog.args[2].toString()),
                reason: ethers.utils.parseBytes32String(parsedLog.args[3]),
              });

            }

          } catch (err) {

            console.log('parse EthLogs error:', err);

          }
        }

        if (log.address == looKeeper.address) {
          try {
            
            const parsedLog = iface.parseLog(log);

            if (parsedLog.name == "CloseBidAgainstInitOffer") {

              toComp.push({
                buyer: parseInt(parsedLog.args[0].toString()),
                value: BigInt(parsedLog.args[1].toString()),
              });

            } 

          } catch (err) {
            console.log('parse EthLogs error:', err);
          }
        }

      });

      return [toComp, toCoffer, fromCustody];
    }

    const parseOrderLogs = async (tx) => {
      const receipt = await tx.wait();

      let seqOfOrder = 0;
      let orderPlaced = [];
      let orderWithdrawn = {};
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

        if (log.address == loo.address) {
          try {
            const parsedLog = iface.parseLog(log);

            if (parsedLog.name == "OrderPlaced") {

              orderPlaced.push({
                order: parseDeal(parsedLog.args[0]), 
                isOffer: parsedLog.args[1],
              });

            } else if (parsedLog.name == "OrderWithdrawn") {

              orderWithdrawn = {
                node: parseNode(parsedLog.args[0]), 
                data: parseData(parsedLog.args[1]), 
                isOffer: parsedLog.args[2],
              };

            } else if (parsedLog.name == "DealClosed") {

              dealClosed.push({
                deal: parseDeal(parsedLog.args[0]),
                consideration: BigInt(parsedLog.args[1].toString()),
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

      if (orderPlaced.length > 0) {
        seqOfOrder = await loo.counterOfOrders(2, orderPlaced[0].isOffer);
      }

      return [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed];
    }

    let seqOfOrder = 0;
    let orderPlaced = [];
    let orderWithdrawn = {};
    let orderExpired = [];
    let dealClosed = [];  
    let deal = {};
    let consideration = 0n;
    let value = 0n;
    let share = {};

    let toComp = [];
    let toCoffer = [];
    let fromCustody = [];

    // ==== List Initial Offer ====

    await expect(gk.connect(signers[1]).placeInitialOffer(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024)).to.be.revertedWith("LOOK.placeIO: not entitled");
    console.log(" \u2714 Passed Access Control Test for gk.placeInitialOffer(). \n");

    await expect(gk.placeInitialOffer(1, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024)).to.be.revertedWith("LOOK.placeIO: wrong class");
    console.log(" \u2714 Passed Parameter Control Test for gk.placeInitialOffer(). classOfShare \n");

    await expect(gk.placeInitialOffer(2, 1, 20 * 10 ** 10, 3.6 * 10 ** 4, 1024)).to.be.revertedWith("LOOK.placeIO: paid overflow");
    console.log(" \u2714 Passed Parameter Control Test for gk.placeInitialOffer(). paid \n");

    let tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.placeInitialOffer().");

    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(ros, "IncreaseEquityOfClass");
    console.log(" \u2714 Passed Event Test for ros.IncreaseEquityOfClass(). \n");

    await expect(tx).to.emit(loo, "OrderPlaced");
    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].order.classOfShare).to.equal(2);
    expect(orderPlaced[0].order.seqOfShare).to.equal(0);
    expect(orderPlaced[0].order.buyer).to.equal(0);
    expect(orderPlaced[0].order.paid).to.equal("100.0");
    expect(orderPlaced[0].order.price).to.equal("3.6");
    expect(orderPlaced[0].order.votingWeight).to.equal(100);
    expect(orderPlaced[0].order.distrWeight).to.equal(100);
    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 3.8 * 10 ** 4, 1024);

    transferCBP("1", "8", 18n);

    tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 4 * 10 ** 4, 1024);

    transferCBP("1", "8", 18n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    tx = await gk.withdrawInitialOffer(2, seqOfOrder, 1024);

    transferCBP("1", "8", 18n);
    
    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderWithdrawn.node.issuer).to.equal(1);
    expect(orderWithdrawn.node.paid).to.equal("100.0");
    expect(orderWithdrawn.node.price).to.equal("4.0");
    expect(orderWithdrawn.node.isOffer).to.equal(true);

    expect(orderWithdrawn.data.classOfShare).to.equal(2);
    expect(orderWithdrawn.data.seqOfShare).to.equal(0);
    expect(orderWithdrawn.data.groupRep).to.equal(0);
    expect(orderWithdrawn.data.votingWeight).to.equal(100);
    expect(orderWithdrawn.data.distrWeight).to.equal(100);

    console.log(" \u2714 Passed Event Test for loo.OrderWithdrawn(). \n");

    // ==== Place Buy Order ====

    const centPrice = BigInt(await gk.getCentPrice());

    value = getDealValue(370n, 80n, centPrice);
    
    await expect(gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 3.7 * 10 ** 4, 1, {value: value - 200n})).to.be.revertedWith("OR.placeBuyOrder: insufficient msgValue");
    console.log(" \u2714 Passed Value Check Test for gk.placeBuyOrder(). \n");
    
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 3.7 * 10 ** 4, 1, {value: value + 100n});

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 88n, "gk.placeBuyOrder().");
    
    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    deal = dealClosed[0].deal;
    consideration = dealClosed[0].consideration;

    expect(deal.classOfShare).to.equal(2);
    expect(deal.seqOfShare).to.equal(0);
    expect(deal.buyer).to.equal(2);
    expect(deal.paid).to.equal("80.0");
    expect(deal.price).to.equal("3.6");
    expect(deal.votingWeight).to.equal(100);
    expect(deal.distrWeight).to.equal(100);

    expect(consideration).to.equal(getDealValue(360n, 80n, centPrice));

    addEthToUser(consideration, "8");
    
    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);

    expect(toComp[0].buyer).to.equal(2);
    expect(toComp[0].value).to.equal(consideration);

    let balance = value + 100n - consideration;

    expect(toCoffer[0].acct).to.equal(2);
    expect(toCoffer[0].value).to.equal(balance);
    expect(toCoffer[0].reason).to.equal("DepositBalanceOfBidOrder");

    addEthToUser(balance, "2");

    console.log(" \u2714 Passed Event Test for looKeeper.CloseBidAgainstInitOffer() & gk.SaveToCoffer(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('3.6');
    expect(share.body.paid).to.equal('80.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");

    // ---- Buy Order 2 ----

    value = getDealValue(390n, 80n, centPrice);
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 3.9 * 10 ** 4, 1, {value: value + 100n});

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    deal = dealClosed[0].deal;
    consideration = dealClosed[0].consideration;

    expect(deal.classOfShare).to.equal(2);
    expect(deal.seqOfShare).to.equal(0);
    expect(deal.buyer).to.equal(2);
    expect(deal.paid).to.equal("60.0");
    expect(deal.price).to.equal("3.8");
    expect(deal.votingWeight).to.equal(100);
    expect(deal.distrWeight).to.equal(100);

    expect(consideration).to.equal(getDealValue(380n, 60n, centPrice));

    addEthToUser(consideration, "8");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). deals[0] \n");

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);

    expect(toComp[0].buyer).to.equal(2);
    expect(toComp[0].value).to.equal(consideration);

    value -= consideration;

    console.log(" \u2714 Passed Event Test for looKeeper.CloseBidAgainstInitOffer() & gk.SaveToCoffer(). \n");

    deal = dealClosed[1].deal;
    consideration = dealClosed[1].consideration;

    expect(deal.classOfShare).to.equal(2);
    expect(deal.seqOfShare).to.equal(0);
    expect(deal.buyer).to.equal(2);
    expect(deal.paid).to.equal("20.0");
    expect(deal.price).to.equal("3.6");
    expect(deal.votingWeight).to.equal(100);
    expect(deal.distrWeight).to.equal(100);

    expect(consideration).to.equal(getDealValue(360n, 20n, centPrice));

    addEthToUser(consideration, "8");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). deals[1] \n");

    expect(toComp[1].buyer).to.equal(2);
    expect(toComp[1].value).to.equal(consideration);

    balance = value + 100n - consideration;

    expect(toCoffer[0].acct).to.equal(2);
    expect(toCoffer[0].value).to.equal(balance);
    expect(toCoffer[0].reason).to.equal("DepositBalanceOfBidOrder");

    addEthToUser(balance, "2");

    console.log(" \u2714 Passed Event Test for looKeeper.CloseBidAgainstInitOffer() & gk.SaveToCoffer(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('3.6');
    expect(share.body.paid).to.equal('20.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");

    // ---- Buy Order 3 ----

    value = getDealValue(400n, 80n, centPrice);
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 4 * 10 ** 4, 1, {value: value + 100n});

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    deal = dealClosed[0].deal;
    consideration = dealClosed[0].consideration;

    expect(deal.classOfShare).to.equal(2);
    expect(deal.seqOfShare).to.equal(0);
    expect(deal.buyer).to.equal(2);
    expect(deal.paid).to.equal("40.0");
    expect(deal.price).to.equal("3.8");
    expect(deal.votingWeight).to.equal(100);
    expect(deal.distrWeight).to.equal(100);

    expect(consideration).to.equal(getDealValue(380n, 40n, centPrice));

    addEthToUser(consideration, "8");
    
    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    expect(orderPlaced[0].order.classOfShare).to.equal(2);
    expect(orderPlaced[0].order.seqOfShare).to.equal(0);
    expect(orderPlaced[0].order.buyer).to.equal(2);
    expect(orderPlaced[0].order.paid).to.equal("40.0");
    expect(orderPlaced[0].order.price).to.equal("4.0");
    expect(orderPlaced[0].order.votingWeight).to.equal(0);
    expect(orderPlaced[0].order.distrWeight).to.equal(0);
    expect(orderPlaced[0].isOffer).to.equal(false);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);

    expect(toComp[0].buyer).to.equal(2);
    expect(toComp[0].value).to.equal(consideration);

    balance = value + 100n - consideration;

    expect(toCoffer[0].acct).to.equal(parseInt("0x20000000002", 16));
    expect(toCoffer[0].value).to.equal(balance);
    expect(toCoffer[0].reason).to.equal("CustodyValueOfBidOrder");

    console.log(" \u2714 Passed Event Test for looKeeper.CloseBidAgainstInitOffer() & gk.SaveToCoffer(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('3.8');
    expect(share.body.paid).to.equal('40.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");

    // ---- Buy Order 4 ----

    value = getDealValue(420n, 80n, centPrice);
    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 4.2 * 10 ** 4, 1, {value: value + 100n});

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].order.classOfShare).to.equal(2);
    expect(orderPlaced[0].order.seqOfShare).to.equal(0);
    expect(orderPlaced[0].order.buyer).to.equal(2);
    expect(orderPlaced[0].order.paid).to.equal("80.0");
    expect(orderPlaced[0].order.price).to.equal("4.2");
    expect(orderPlaced[0].order.votingWeight).to.equal(0);
    expect(orderPlaced[0].order.distrWeight).to.equal(0);
    expect(orderPlaced[0].isOffer).to.equal(false);

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);

    expect(toCoffer[0].acct).to.equal(parseInt("0x20000000002", 16));
    expect(toCoffer[0].value).to.equal(value + 100n);
    expect(toCoffer[0].reason).to.equal("CustodyValueOfBidOrder");

    // ---- Withdraw Buy Order 4 ----

    tx = await gk.connect(signers[1]).withdrawBuyOrder(2, seqOfOrder);

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderWithdrawn.node.issuer).to.equal(2);
    expect(orderWithdrawn.node.paid).to.equal("80.0");
    expect(orderWithdrawn.node.price).to.equal("4.2");
    expect(orderWithdrawn.node.isOffer).to.equal(false);

    expect(orderWithdrawn.data.classOfShare).to.equal(2);
    expect(orderWithdrawn.data.seqOfShare).to.equal(0);
    expect(orderWithdrawn.data.groupRep).to.equal(2);
    expect(orderWithdrawn.data.votingWeight).to.equal(0);
    expect(orderWithdrawn.data.distrWeight).to.equal(0);

    console.log(" \u2714 Passed Event Test for loo.OrderWithdrawn(). \n");

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);
    
    expect(fromCustody[0].from).to.equal(2);
    expect(fromCustody[0].to).to.equal(2);
    expect(fromCustody[0].value).to.equal(value + 100n);
    expect(fromCustody[0].reason).to.equal("RefundValueOfBidOrder");

    addEthToUser(value + 100n, "2");

    // ==== Place Sell Order ====

    // ---- Sell Order 1 ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 4.2 * 10 ** 4, 1024);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.placeSellOrder().");    

    transferCBP("3", "8", 58n);

    await expect(tx).to.emit(ros, "DecreaseCleanPaid");
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n");

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].order.classOfShare).to.equal(2);
    expect(orderPlaced[0].order.buyer).to.equal(0);
    expect(orderPlaced[0].order.paid).to.equal("100.0");
    expect(orderPlaced[0].order.price).to.equal("4.2");
    expect(orderPlaced[0].order.votingWeight).to.equal(100);
    expect(orderPlaced[0].order.distrWeight).to.equal(100);
    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.placeSellOrder(). Sell Order 1 \n");

    // ---- Sell Order 2 ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 4 * 10 ** 4, 1024);

    transferCBP("3", "8", 58n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    deal = dealClosed[0].deal;
    consideration = dealClosed[0].consideration;

    expect(deal.classOfShare).to.equal(2);
    expect(deal.buyer).to.equal(2);
    expect(deal.paid).to.equal("40.0");
    expect(deal.price).to.equal("4.0");
    expect(deal.votingWeight).to.equal(100);
    expect(deal.distrWeight).to.equal(100);

    expect(consideration).to.equal(getDealValue(400n, 40n, centPrice));

    addEthToUser(consideration, "3");
    
    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);

    expect(fromCustody[0].from).to.equal(2);
    expect(fromCustody[0].to).to.equal(3);
    expect(fromCustody[0].value).to.equal(consideration);
    expect(fromCustody[0].reason).to.equal("CloseOfferAgainstBid");

    balance = getDealValue(400n, 80n, centPrice) + 100n - getDealValue(380n, 40n, centPrice) - consideration;

    expect(fromCustody[1].from).to.equal(2);
    expect(fromCustody[1].to).to.equal(2);
    expect(fromCustody[1].value).to.equal(balance);
    expect(fromCustody[1].reason).to.equal("RefundValueOfBidOrder");

    addEthToUser(balance, "2");

    console.log(" \u2714 Passed Event Test for looKeeper.CloseBidAgainstInitOffer() & gk.SaveToCoffer(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('4.0');
    expect(share.body.paid).to.equal('40.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedSellOrder(). share issued \n");

    expect(orderPlaced[0].order.classOfShare).to.equal(2);
    expect(orderPlaced[0].order.buyer).to.equal(0);
    expect(orderPlaced[0].order.paid).to.equal("60.0");
    expect(orderPlaced[0].order.price).to.equal("4.0");
    expect(orderPlaced[0].order.votingWeight).to.equal(100);
    expect(orderPlaced[0].order.distrWeight).to.equal(100);
    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");
    
    // ---- Sell Order 3 ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.8 * 10 ** 4, 1024);

    transferCBP("3", "8", 58n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].order.classOfShare).to.equal(2);
    expect(orderPlaced[0].order.buyer).to.equal(0);
    expect(orderPlaced[0].order.paid).to.equal("100.0");
    expect(orderPlaced[0].order.price).to.equal("3.8");
    expect(orderPlaced[0].order.votingWeight).to.equal(100);
    expect(orderPlaced[0].order.distrWeight).to.equal(100);
    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.placeSellOrder(). Sell Order 3 \n");

    // ---- Sell Order 4 ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024);

    transferCBP("3", "8", 58n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);
    
    expect(orderPlaced[0].order.classOfShare).to.equal(2);
    expect(orderPlaced[0].order.buyer).to.equal(0);
    expect(orderPlaced[0].order.paid).to.equal("100.0");
    expect(orderPlaced[0].order.price).to.equal("3.6");
    expect(orderPlaced[0].order.votingWeight).to.equal(100);
    expect(orderPlaced[0].order.distrWeight).to.equal(100);
    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.placeSellOrder(). Sell Order 4 \n");    

    tx = await gk.connect(signers[3]).withdrawSellOrder(2, seqOfOrder);

    transferCBP("3", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderWithdrawn.node.issuer).to.equal(3);
    expect(orderWithdrawn.node.paid).to.equal("100.0");
    expect(orderWithdrawn.node.price).to.equal("3.6");
    expect(orderWithdrawn.node.isOffer).to.equal(true);

    expect(orderWithdrawn.data.classOfShare).to.equal(2);
    expect(orderWithdrawn.data.groupRep).to.equal(0);
    expect(orderWithdrawn.data.votingWeight).to.equal(100);
    expect(orderWithdrawn.data.distrWeight).to.equal(100);

    console.log(" \u2714 Passed Event Test for loo.OrderWithdrawn(). \n");

    // ==== Place Market Buy Order ====

    value = getDealValue(400n, 160n, centPrice);

    tx = await gk.connect(signers[1]).placeBuyOrder(2, 160 * 10 ** 4, 0, 1, {value: value + 100n});

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);
    
    deal = dealClosed[0].deal;
    consideration = dealClosed[0].consideration;

    expect(deal.classOfShare).to.equal(2);
    expect(deal.buyer).to.equal(2);
    expect(deal.paid).to.equal("60.0");
    expect(deal.price).to.equal("4.0");
    expect(deal.votingWeight).to.equal(100);
    expect(deal.distrWeight).to.equal(100);

    expect(consideration).to.equal(getDealValue(400n, 60n, centPrice));

    addEthToUser(consideration, "3");
    
    console.log(" \u2714 Passed Event Test for loo.DealClosed(). deal-0 \n");

    deal = dealClosed[1].deal;
    consideration = dealClosed[1].consideration;

    expect(deal.classOfShare).to.equal(2);
    expect(deal.buyer).to.equal(2);
    expect(deal.paid).to.equal("100.0");
    expect(deal.price).to.equal("3.8");
    expect(deal.votingWeight).to.equal(100);
    expect(deal.distrWeight).to.equal(100);

    expect(consideration).to.equal(getDealValue(380n, 100n, centPrice));
    
    addEthToUser(consideration, "3");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). deal-1 \n");

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);

    expect(toCoffer[0].acct).to.equal(3);
    expect(toCoffer[0].value).to.equal(getDealValue(400n, 60n, centPrice));
    expect(toCoffer[0].reason).to.equal("CloseBidAgainstOffer");

    expect(toCoffer[1].acct).to.equal(3);
    expect(toCoffer[1].value).to.equal(getDealValue(380n, 100n, centPrice));
    expect(toCoffer[1].reason).to.equal("CloseBidAgainstOffer");

    balance = value + 100n - getDealValue(380n, 100n, centPrice) - getDealValue(400n, 60n, centPrice);

    expect(toCoffer[2].acct).to.equal(2);
    expect(toCoffer[2].value).to.equal(balance);
    expect(toCoffer[2].reason).to.equal("DepositBalanceOfBidOrder");

    addEthToUser(balance, "2");

    console.log(" \u2714 Passed Event Test for gk.SaveToCoffer(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('3.8');
    expect(share.body.paid).to.equal('100.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");
    
    // ==== Place Buy Order ====

    value = getDealValue(400n, 80n, centPrice);

    tx = await gk.connect(signers[1]).placeBuyOrder(2, 80 * 10 ** 4, 4 * 10 ** 4, 1, {value: value + 100n});

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].order.classOfShare).to.equal(2);
    expect(orderPlaced[0].order.buyer).to.equal(2);
    expect(orderPlaced[0].order.paid).to.equal("80.0");
    expect(orderPlaced[0].order.price).to.equal("4.0");
    expect(orderPlaced[0].order.votingWeight).to.equal(0);
    expect(orderPlaced[0].order.distrWeight).to.equal(0);
    expect(orderPlaced[0].isOffer).to.equal(false);

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);

    expect(toCoffer[0].acct).to.equal(parseInt("0x20000000002", 16));
    expect(toCoffer[0].value).to.equal(value + 100n);
    expect(toCoffer[0].reason).to.equal("CustodyValueOfBidOrder");

    // ---- Market Sell Order ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 80 * 10 ** 4, 0, 1024);

    transferCBP("3", "8", 58n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    deal = dealClosed[0].deal;
    consideration = dealClosed[0].consideration;

    expect(deal.classOfShare).to.equal(2);
    expect(deal.buyer).to.equal(2);
    expect(deal.paid).to.equal("80.0");
    expect(deal.price).to.equal("4.0");
    expect(deal.votingWeight).to.equal(100);
    expect(deal.distrWeight).to.equal(100);

    expect(consideration).to.equal(getDealValue(400n, 80n, centPrice));

    addEthToUser(consideration, "3");
    
    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    [toComp, toCoffer, fromCustody] = await parseEthLogs(tx);

    expect(fromCustody[0].from).to.equal(2);
    expect(fromCustody[0].to).to.equal(3);
    expect(fromCustody[0].value).to.equal(consideration);
    expect(fromCustody[0].reason).to.equal("CloseOfferAgainstBid");

    console.log(" \u2714 Passed Event Test for gk.ReleaseCustody(). \n");

    balance = 100n;

    expect(fromCustody[1].from).to.equal(2);
    expect(fromCustody[1].to).to.equal(2);
    expect(fromCustody[1].value).to.equal(balance);
    expect(fromCustody[1].reason).to.equal("RefundValueOfBidOrder");

    addEthToUser(balance, "2");

    console.log(" \u2714 Passed Event Test for gk.ReleaseCustody(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('4.0');
    expect(share.body.paid).to.equal('80.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");

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
