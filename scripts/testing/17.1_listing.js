// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// This section shows and tests how to trade equity shares by listing on the List
// of USD Orders (the “LOO”).

// Companies may set out their listing rules in SHA. Thereafter, the authorized
// officer may place initial offers on the List of USD Orders, and, Members of the class
// of shares concerned may place limited sell orders with intended sell price or
// market sell order. Accredited Investors approved by the authorized officers may
// place limited buy orders with specific bid price or market buy order. 

// Listed trades are settled via USDC as consideration. Buyers pay USDC together with
// placing buy orders. In case of closing, the consideration USDC will be
// automatically saved to the seller's deposit account, and the remaining amount of
// USDC will be refunded to the buyer's deposit account. As for the listed buy order,
// the paid USDC will be stored in the buyer's deposit account, and will be released
// to the seller in case of closing, or refunded back to the buyer in case of
// expiration.

// The scenario for testing in this section are as follows:
// (1) User_1 as Chairman of the DAO places and withdraws initial offers as per the
//     listing rule;
// (2) User_2 as an accredited Investor places and withdraws limited buy orders
//     with the LOO, thus, matching and closing certain initial offers. Upon
//     closing, USDC paid by User_2 will be saved in Cashier as capital
//     contribution income of the DAO, and certain new Shares will be issued to
//     User_2;
// (3) Balance of the limited buy orders placed by User_2 will be listed on the
//     List of Orders, and, the USDC paid will be stored in the custody account
//     of User_2;
// (4) User_3 as Member of the DAO, places and withdraws limited sell orders with
//     the List of Orders. Thereafter, some of the sell orders will be matched with
//     the listed buy orders placed by User_2.  Upon closing, the shares of the
//     sell order will be transferred to User_2, and the USDC under custody will be
//     released to User_3 as consideration, or be released to User_2 as refunded
//     balance amount.
// (5) User_2 places market buy order so as to purchase off listed offers from the LOO;
// (6) User_3 places market sell order so as to match off listed bids from the LOO; 

// The Write APIs tested in this section include:
// 1. USDKeper
// 1.1 function placeInitialOffer(uint classOfShare,uint execHours, uint paid, 
//     uint price,uint seqOfLR) external;
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

// 2. List of USD Orders
// 2.1 event OrderPlaced(bytes32 indexed order, bool indexed isOffer);
// 2.2 event OrderWithdrawn(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer);
// 2.3 event DealClosed(bytes32 indexed fromSn, bytes32 indexed toSn, bytes32 qtySn, 
//     uint indexed consideration);
// 2.4 event OrderExpired(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer);

// 3. Cashier
// 3.1 event CustodyUsd(address indexed from, uint indexed amt, bytes32 indexed remark);
// 3.2 event ReleaseUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark);

const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { getROS, getRC, getUSDC, getCashier, getLOO, getFK } = require("./boox");
const { getLatestShare, printShares } = require("./ros");

const { royaltyTest, cbpOfUsers } = require("./rc");
const { transferCBP } = require("./saveTool");
const { parseFromSn, parseQtySn, parseToSn, parseNode, parseData } = require("./loo");
const { AddrZero, trimAddr, longDataParser, } = require("./utils");
const { generateAuth } = require("./sigTools");
const { parseDrop } = require("./cashier");

async function main() {

    console.log('\n');
    console.log('********************************');
    console.log('**   17.1  Listing LPS Deals  **');
    console.log('********************************');
    console.log('\n');

	  const signers = await hre.ethers.getSigners();

    const rc = await getRC();
    const gk = await getFK();
    const usdc = await getUSDC();
    const cashier = await getCashier();
    const loo = await getLOO();
    const ros = await getROS();

    // ==== Parse Logs ====

    const parseUsdLogs = async (tx) => {
      const receipt = await tx.wait();
      
      let journal = [];

      const eventAbi = [
        "event ReceiveUsd(address indexed from, uint indexed amt)",
        "event ForwardUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark)",
        "event CustodyUsd(address indexed from, uint indexed amt, bytes32 indexed remark)",
        "event ReleaseUsd(address indexed from, address indexed to, uint indexed amt, bytes32 remark)",
        "event TransferUsd(address indexed to, uint indexed amt, bytes32 indexed remark)",
      ];
      
      const iface = new ethers.utils.Interface(eventAbi);

      receipt.logs.forEach((log) => {

        if (log.address == cashier.address) {
          try {
            const parsedLog = iface.parseLog(log);

            if (parsedLog.name == "ReceiveUsd") {

              journal.push({
                from: parsedLog.args[0].toString(),
                to: cashier.address,
                amt: ethers.utils.formatUnits(parsedLog.args[1].toString(), 6),
                remark: "ReceivedUsd",
              });

            } else if (parsedLog.name == "ForwardUsd") {

              journal.push({
                from: parsedLog.args[0].toString(), 
                to: parsedLog.args[1].toString(), 
                amt: ethers.utils.formatUnits(parsedLog.args[2].toString(), 6),
                remark: ethers.utils.parseBytes32String(parsedLog.args[3]),
              });

            } else if (parsedLog.name == "CustodyUsd") {

              journal.push({
                from: parsedLog.args[0].toString(),
                amt: ethers.utils.formatUnits(parsedLog.args[1].toString(), 6),
                remark: ethers.utils.parseBytes32String(parsedLog.args[2]),
              });

            } else if (parsedLog.name == "ReleaseUsd") {

              journal.push({
                from: parsedLog.args[0].toString(), 
                to: parsedLog.args[1].toString(), 
                amt: ethers.utils.formatUnits(parsedLog.args[2].toString(), 6),
                remark: ethers.utils.parseBytes32String(parsedLog.args[3]),
              });

            } else if (parsedLog.name == "TransferUsd") {

              journal.push({
                from: cashier.address, 
                to: parsedLog.args[0].toString(), 
                amt: ethers.utils.formatUnits(parsedLog.args[1].toString(), 6),
                remark: ethers.utils.parseBytes32String(parsedLog.args[2]),
              });

            }


          } catch (err) {

            console.log('parse EthLogs error:', err);

          }
        }

      });

      return journal;
    }

    const parseOrderLogs = async (tx) => {
      const receipt = await tx.wait();

      let seqOfOrder = 0;
      let orderPlaced = [];
      let orderWithdrawn = {};
      let orderExpired = [];
      let dealClosed = [];
      
      const eventAbi = [
        "event OrderPlaced(bytes32 indexed fromSn, bytes32 indexed toSn, bytes32 indexed qtySn, bool isOffer)",
        "event OrderWithdrawn(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer)",
        "event DealClosed(bytes32 indexed fromSn, bytes32 indexed toSn, bytes32 qtySn, uint indexed consideration)",
        "event OrderExpired(bytes32 indexed head, bytes32 indexed body, bool indexed isOffer)",
      ];
      
      const iface = new ethers.utils.Interface(eventAbi);

      receipt.logs.forEach((log) => {

        if (log.address == loo.address) {
          try {
            const parsedLog = iface.parseLog(log);

            if (parsedLog.name == "OrderPlaced") {

              orderPlaced.push({
                from: parseFromSn(parsedLog.args[0]),
                to: parseToSn(parsedLog.args[1]),
                qty: parseQtySn(parsedLog.args[2]),
                isOffer: parsedLog.args[3],
              });

            } else if (parsedLog.name == "OrderWithdrawn") {

              orderWithdrawn = {
                head: parseNode(parsedLog.args[0]), 
                body: parseData(parsedLog.args[1]), 
                isOffer: parsedLog.args[2],
              };

            } else if (parsedLog.name == "DealClosed") {

              dealClosed.push({
                from: parseFromSn(parsedLog.args[0]),
                to: parseToSn(parsedLog.args[1]),
                qty: parseQtySn(parsedLog.args[2]),
                isOffer: parsedLog.args[3],
              });

            } else if (parsedLog.name == "OrderExpired") {

              orderExpired.push({
                head: parseNode(parsedLog.args[0]), 
                body: parseData(parsedLog.args[1]), 
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

    let share = {};

    let journal = [];

    // ==== List Initial Offer ====

    await expect(gk.connect(signers[3]).placeInitialOffer(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024)).to.be.revertedWith("LOOK.placeIO: not GP");
    console.log(" \u2714 Passed Access Control Test for gk.placeInitialOffer(). \n");

    await expect(gk.placeInitialOffer(1, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024)).to.be.revertedWith("LOOK.placeIO: wrong class");
    console.log(" \u2714 Passed Class Type Test for gk.placeInitialOffer(). \n");

    await expect(gk.placeInitialOffer(2, 1, 20 * 10 ** 12, 3.6 * 10 ** 4, 1024)).to.be.revertedWith("LOOK.placeIO: paid overflow");
    console.log(" \u2714 Passed Paid Quota Test for gk.placeInitialOffer(). \n");

    let tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024);

    await royaltyTest(rc.address, signers[0].address, gk.address, tx, 18n, "gk.placeInitialOffer().");

    transferCBP("1", "8", 18n);

    await expect(tx).to.emit(ros, "IncreaseEquityOfClass");
    console.log(" \u2714 Passed Event Test for ros.IncreaseEquityOfClass(). \n");

    await expect(tx).to.emit(loo, "OrderPlaced");
    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].from.from).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].from.buyer).to.equal(0);
    expect(orderPlaced[0].from.groupRep).to.equal(0);
    expect(orderPlaced[0].from.classOfShare).to.equal(2);

    expect(orderPlaced[0].to.to).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].to.seller).to.equal(1);
    expect(orderPlaced[0].to.state).to.equal(0);
    expect(orderPlaced[0].to.inEth).to.equal(false);
    expect(orderPlaced[0].to.isOffer).to.equal(true);

    expect(orderPlaced[0].qty.paid).to.equal("100.0");
    expect(orderPlaced[0].qty.price).to.equal("3.6");
    expect(orderPlaced[0].qty.votingWeight).to.equal(100);
    expect(orderPlaced[0].qty.distrWeight).to.equal(100);
    expect(orderPlaced[0].qty.consideration).to.equal("0.0");

    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). Init_Order_1 \n");

    tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 3.8 * 10 ** 4, 1024);

    transferCBP("1", "8", 18n);

    tx = await gk.placeInitialOffer(2, 1, 100 * 10 ** 4, 4 * 10 ** 4, 1024);

    transferCBP("1", "8", 18n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    tx = await gk.withdrawInitialOffer(2, seqOfOrder, 1024);

    transferCBP("1", "8", 18n);
    
    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderWithdrawn.head.issuer).to.equal(1);
    expect(orderWithdrawn.head.paid).to.equal("100.0");
    expect(orderWithdrawn.head.price).to.equal("4.0");
    expect(orderWithdrawn.head.isOffer).to.equal(true);

    expect(orderWithdrawn.body.classOfShare).to.equal(2);
    expect(orderWithdrawn.body.groupRep).to.equal(0);
    expect(orderWithdrawn.body.votingWeight).to.equal(100);
    expect(orderWithdrawn.body.distrWeight).to.equal(100);
    expect(orderWithdrawn.body.margin).to.equal("0.0");
    expect(orderWithdrawn.body.inEth).to.equal(false);

    console.log(" \u2714 Passed Event Test for loo.OrderWithdrawn(). \n");

    // ==== Place Buy Order ====

    let auth = await generateAuth(signers[1], cashier.address, 8 * 37);
    tx = await gk.connect(signers[1]).placeBuyOrder(auth, 2, 80 * 10 ** 4, 3.7 * 10 ** 4, 1);  

    await royaltyTest(rc.address, signers[1].address, gk.address, tx, 88n, "gk.placeBuyOrder().");

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(dealClosed[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(dealClosed[0].from.buyer).to.equal(2);
    expect(dealClosed[0].from.groupRep).to.equal(2);
    expect(dealClosed[0].from.classOfShare).to.equal(2);

    expect(dealClosed[0].to.to).to.equal(trimAddr(AddrZero));
    expect(dealClosed[0].to.seller).to.equal(1);
    expect(dealClosed[0].to.inEth).to.equal(false);

    expect(dealClosed[0].qty.paid).to.equal("80.0");
    expect(dealClosed[0].qty.price).to.equal("3.6");
    expect(dealClosed[0].qty.votingWeight).to.equal(100);
    expect(dealClosed[0].qty.distrWeight).to.equal(100);
    expect(dealClosed[0].qty.consideration).to.equal("288.0");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].amt).to.equal('296.0');
    expect(journal[0].remark).to.equal("CustodyValueOfBid");

    expect(journal[1].from).to.equal(signers[1].address);
    expect(journal[1].to).to.equal(cashier.address);
    expect(journal[1].amt).to.equal('288.0');
    expect(journal[1].remark).to.equal("CloseBidAgainstInitOffer");

    expect(journal[2].from).to.equal(signers[1].address);
    expect(journal[2].to).to.equal(signers[1].address);
    expect(journal[2].amt).to.equal('8.0');
    expect(journal[2].remark).to.equal("RefundBalanceOfBidOrder");

    console.log(" \u2714 Passed Cashier Event Test for looKeeper.DealClosed(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('3.6');
    expect(share.body.paid).to.equal('80.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");

    // ---- Buy Order 2 ----

    auth = await generateAuth(signers[1], cashier.address, 8 * 39);
    tx = await gk.connect(signers[1]).placeBuyOrder(auth, 2, 80 * 10 ** 4, 3.9 * 10 ** 4, 1);  

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(dealClosed[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(dealClosed[0].from.buyer).to.equal(2);
    expect(dealClosed[0].from.groupRep).to.equal(2);
    expect(dealClosed[0].from.classOfShare).to.equal(2);

    expect(dealClosed[0].to.to).to.equal(trimAddr(AddrZero));
    expect(dealClosed[0].to.seller).to.equal(1);
    expect(dealClosed[0].to.inEth).to.equal(false);

    expect(dealClosed[0].qty.paid).to.equal("60.0");
    expect(dealClosed[0].qty.price).to.equal("3.8");
    expect(dealClosed[0].qty.votingWeight).to.equal(100);
    expect(dealClosed[0].qty.distrWeight).to.equal(100);
    expect(dealClosed[0].qty.consideration).to.equal("228.0");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].amt).to.equal('312.0');
    expect(journal[0].remark).to.equal("CustodyValueOfBid");

    expect(journal[1].from).to.equal(signers[1].address);
    expect(journal[1].to).to.equal(cashier.address);
    expect(journal[1].amt).to.equal('228.0');
    expect(journal[1].remark).to.equal("CloseBidAgainstInitOffer");

    console.log(" \u2714 Passed Cashier Event Test for ReleaseUsd \n");

    expect(dealClosed[1].from.from).to.equal(trimAddr(signers[1].address));
    expect(dealClosed[1].from.buyer).to.equal(2);
    expect(dealClosed[1].from.groupRep).to.equal(2);
    expect(dealClosed[1].from.classOfShare).to.equal(2);

    expect(dealClosed[1].to.to).to.equal(trimAddr(AddrZero));
    expect(dealClosed[1].to.seller).to.equal(1);
    expect(dealClosed[1].to.inEth).to.equal(false);

    expect(dealClosed[1].qty.paid).to.equal("20.0");
    expect(dealClosed[1].qty.price).to.equal("3.6");
    expect(dealClosed[1].qty.votingWeight).to.equal(100);
    expect(dealClosed[1].qty.distrWeight).to.equal(100);
    expect(dealClosed[1].qty.consideration).to.equal("72.0");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    expect(journal[2].from).to.equal(signers[1].address);
    expect(journal[2].amt).to.equal('72.0');
    expect(journal[2].remark).to.equal("CloseBidAgainstInitOffer");

    console.log(" \u2714 Passed Cashier Event Test for CloseBidAgainstInitOffer to Cashier \n");

    expect(journal[3].from).to.equal(signers[1].address);
    expect(journal[3].to).to.equal(signers[1].address);
    expect(journal[3].amt).to.equal('12.0');
    expect(journal[3].remark).to.equal("RefundBalanceOfBidOrder");

    console.log(" \u2714 Passed Cashier Event Test for RefundBalanceOfBidOrder \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('3.6');
    expect(share.body.paid).to.equal('20.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");

    // ---- Buy Order 3 ----

    auth = await generateAuth(signers[1], cashier.address, 8 * 40);
    tx = await gk.connect(signers[1]).placeBuyOrder(auth, 2, 80 * 10 ** 4, 4 * 10 ** 4, 1);

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(dealClosed[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(dealClosed[0].from.buyer).to.equal(2);
    expect(dealClosed[0].from.groupRep).to.equal(2);
    expect(dealClosed[0].from.classOfShare).to.equal(2);

    expect(dealClosed[0].to.to).to.equal(trimAddr(AddrZero));
    expect(dealClosed[0].to.seller).to.equal(1);
    expect(dealClosed[0].to.inEth).to.equal(false);

    expect(dealClosed[0].qty.paid).to.equal("40.0");
    expect(dealClosed[0].qty.price).to.equal("3.8");
    expect(dealClosed[0].qty.votingWeight).to.equal(100);
    expect(dealClosed[0].qty.distrWeight).to.equal(100);
    expect(dealClosed[0].qty.consideration).to.equal("152.0");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    expect(orderPlaced[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(orderPlaced[0].from.buyer).to.equal(2);
    expect(orderPlaced[0].from.groupRep).to.equal(2);
    expect(orderPlaced[0].from.classOfShare).to.equal(2);

    expect(orderPlaced[0].to.to).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].to.seller).to.equal(0);
    expect(orderPlaced[0].to.state).to.equal(0);
    expect(orderPlaced[0].to.inEth).to.equal(false);
    expect(orderPlaced[0].to.isOffer).to.equal(false);

    expect(orderPlaced[0].qty.paid).to.equal("40.0");
    expect(orderPlaced[0].qty.price).to.equal("4.0");
    expect(orderPlaced[0].qty.votingWeight).to.equal(0);
    expect(orderPlaced[0].qty.distrWeight).to.equal(0);
    expect(orderPlaced[0].qty.consideration).to.equal("168.0");

    expect(orderPlaced[0].isOffer).to.equal(false);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].amt).to.equal('320.0');
    expect(journal[0].remark).to.equal("CustodyValueOfBid");

    expect(journal[1].from).to.equal(signers[1].address);
    expect(journal[1].to).to.equal(cashier.address);
    expect(journal[1].amt).to.equal('152.0');
    expect(journal[1].remark).to.equal("CloseBidAgainstInitOffer");

    console.log(" \u2714 Passed Cashier Event Test for looKeeper.DealClosed(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('3.8');
    expect(share.body.paid).to.equal('40.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");

    // ---- Buy Order 4 ----

    auth = await generateAuth(signers[1], cashier.address, 8 * 42);
    tx = await gk.connect(signers[1]).placeBuyOrder(auth, 2, 80 * 10 ** 4, 4.2 * 10 ** 4, 1);

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(orderPlaced[0].from.buyer).to.equal(2);
    expect(orderPlaced[0].from.groupRep).to.equal(2);
    expect(orderPlaced[0].from.classOfShare).to.equal(2);

    expect(orderPlaced[0].to.to).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].to.seller).to.equal(0);
    expect(orderPlaced[0].to.state).to.equal(0);
    expect(orderPlaced[0].to.inEth).to.equal(false);
    expect(orderPlaced[0].to.isOffer).to.equal(false);

    expect(orderPlaced[0].qty.paid).to.equal("80.0");
    expect(orderPlaced[0].qty.price).to.equal("4.2");
    expect(orderPlaced[0].qty.votingWeight).to.equal(0);
    expect(orderPlaced[0].qty.distrWeight).to.equal(0);
    expect(orderPlaced[0].qty.consideration).to.equal("336.0");

    expect(orderPlaced[0].isOffer).to.equal(false);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].amt).to.equal('336.0');
    expect(journal[0].remark).to.equal("CustodyValueOfBid");

    console.log(" \u2714 Passed Cashier Event Test for CustodyUsd(). \n");

    // ---- Withdraw BuyOrder_4 ----

    tx = await gk.connect(signers[1]).withdrawBuyOrder(2, seqOfOrder);

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderWithdrawn.head.issuer).to.equal(2);
    expect(orderWithdrawn.head.paid).to.equal("80.0");
    expect(orderWithdrawn.head.price).to.equal("4.2");
    expect(orderWithdrawn.head.isOffer).to.equal(false);

    expect(orderWithdrawn.body.classOfShare).to.equal(2);
    expect(orderWithdrawn.body.groupRep).to.equal(2);
    expect(orderWithdrawn.body.votingWeight).to.equal(0);
    expect(orderWithdrawn.body.distrWeight).to.equal(0);
    expect(orderWithdrawn.body.margin).to.equal("336.0");
    expect(orderWithdrawn.body.inEth).to.equal(false);

    console.log(" \u2714 Passed Event Test for loo.OrderWithdrawn(). \n");

    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].to).to.equal(signers[1].address);
    expect(journal[0].amt).to.equal('336.0');
    expect(journal[0].remark).to.equal("RefundValueOfBidOrder");

    console.log(" \u2714 Passed Cashier Event Test for ReleaseUsd(). \n");

    // ==== Place Sell Order ====

    // ---- Sell Order 1 ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 4.2 * 10 ** 4, 1024);

    await royaltyTest(rc.address, signers[3].address, gk.address, tx, 58n, "gk.placeSellOrder().");    

    transferCBP("3", "8", 58n);

    await expect(tx).to.emit(ros, "DecreaseCleanPaid");
    console.log(" \u2714 Passed Event Test for ros.DecreaseCleanPaid(). \n");

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].from.from).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].from.buyer).to.equal(0);
    expect(orderPlaced[0].from.groupRep).to.equal(0);
    expect(orderPlaced[0].from.classOfShare).to.equal(2);

    expect(orderPlaced[0].to.to).to.equal(trimAddr(signers[3].address));
    expect(orderPlaced[0].to.seller).to.equal(3);
    expect(orderPlaced[0].to.inEth).to.equal(false);
    expect(orderPlaced[0].to.isOffer).to.equal(true);

    expect(orderPlaced[0].qty.paid).to.equal("100.0");
    expect(orderPlaced[0].qty.price).to.equal("4.2");
    expect(orderPlaced[0].qty.votingWeight).to.equal(100);
    expect(orderPlaced[0].qty.distrWeight).to.equal(100);
    expect(orderPlaced[0].qty.consideration).to.equal("0.0");

    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    // ---- Sell Order 2 ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 4 * 10 ** 4, 1024);

    transferCBP("3", "8", 58n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(dealClosed[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(dealClosed[0].from.buyer).to.equal(2);
    expect(dealClosed[0].from.groupRep).to.equal(2);
    expect(dealClosed[0].from.classOfShare).to.equal(2);

    expect(dealClosed[0].to.to).to.equal(trimAddr(signers[3].address));
    expect(dealClosed[0].to.seller).to.equal(3);
    expect(dealClosed[0].to.inEth).to.equal(false);

    expect(dealClosed[0].qty.paid).to.equal("40.0");
    expect(dealClosed[0].qty.price).to.equal("4.0");
    expect(dealClosed[0].qty.votingWeight).to.equal(100);
    expect(dealClosed[0].qty.distrWeight).to.equal(100);
    expect(dealClosed[0].qty.consideration).to.equal("160.0");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");
    
    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].to).to.equal(signers[3].address);
    expect(journal[0].amt).to.equal('160.0');
    expect(journal[0].remark).to.equal("CloseOfferAgainstBid");

    expect(journal[1].from).to.equal(signers[1].address);
    expect(journal[1].to).to.equal(signers[1].address);
    expect(journal[1].amt).to.equal('8.0');
    expect(journal[1].remark).to.equal("RefundValueOfBidOrder");

    console.log(" \u2714 Passed Event Test for cashier. - Sell Order 2 \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('4.0');
    expect(share.body.paid).to.equal('40.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedSellOrder(). share issued \n");

    expect(orderPlaced[0].from.from).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].from.buyer).to.equal(0);
    expect(orderPlaced[0].from.groupRep).to.equal(0);
    expect(orderPlaced[0].from.classOfShare).to.equal(2);

    expect(orderPlaced[0].to.to).to.equal(trimAddr(signers[3].address));
    expect(orderPlaced[0].to.seller).to.equal(3);
    expect(orderPlaced[0].to.inEth).to.equal(false);
    expect(orderPlaced[0].to.isOffer).to.equal(true);

    expect(orderPlaced[0].qty.paid).to.equal("60.0");
    expect(orderPlaced[0].qty.price).to.equal("4.0");
    expect(orderPlaced[0].qty.votingWeight).to.equal(100);
    expect(orderPlaced[0].qty.distrWeight).to.equal(100);
    expect(orderPlaced[0].qty.consideration).to.equal("0.0");

    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");
    
    // ---- Sell Order 3 ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.8 * 10 ** 4, 1024);

    transferCBP("3", "8", 58n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].from.from).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].from.buyer).to.equal(0);
    expect(orderPlaced[0].from.groupRep).to.equal(0);
    expect(orderPlaced[0].from.classOfShare).to.equal(2);

    expect(orderPlaced[0].to.to).to.equal(trimAddr(signers[3].address));
    expect(orderPlaced[0].to.seller).to.equal(3);
    expect(orderPlaced[0].to.inEth).to.equal(false);
    expect(orderPlaced[0].to.isOffer).to.equal(true);

    expect(orderPlaced[0].qty.paid).to.equal("100.0");
    expect(orderPlaced[0].qty.price).to.equal("3.8");
    expect(orderPlaced[0].qty.votingWeight).to.equal(100);
    expect(orderPlaced[0].qty.distrWeight).to.equal(100);
    expect(orderPlaced[0].qty.consideration).to.equal("0.0");

    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    // ---- Sell Order 4 ----

    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 100 * 10 ** 4, 3.6 * 10 ** 4, 1024);

    transferCBP("3", "8", 58n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].from.from).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].from.buyer).to.equal(0);
    expect(orderPlaced[0].from.groupRep).to.equal(0);
    expect(orderPlaced[0].from.classOfShare).to.equal(2);

    expect(orderPlaced[0].to.to).to.equal(trimAddr(signers[3].address));
    expect(orderPlaced[0].to.seller).to.equal(3);
    expect(orderPlaced[0].to.inEth).to.equal(false);
    expect(orderPlaced[0].to.isOffer).to.equal(true);

    expect(orderPlaced[0].qty.paid).to.equal("100.0");
    expect(orderPlaced[0].qty.price).to.equal("3.6");
    expect(orderPlaced[0].qty.votingWeight).to.equal(100);
    expect(orderPlaced[0].qty.distrWeight).to.equal(100);
    expect(orderPlaced[0].qty.consideration).to.equal("0.0");

    expect(orderPlaced[0].isOffer).to.equal(true);

    console.log(" \u2714 Passed Result Verify Test for gk.placeSellOrder(). Sell Order 4 \n");    

    // ---- Withdraw Order 2 ----

    tx = await gk.connect(signers[3]).withdrawSellOrder(2, seqOfOrder);

    transferCBP("3", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderWithdrawn.head.issuer).to.equal(3);
    expect(orderWithdrawn.head.paid).to.equal("100.0");
    expect(orderWithdrawn.head.price).to.equal("3.6");
    expect(orderWithdrawn.head.isOffer).to.equal(true);

    expect(orderWithdrawn.body.classOfShare).to.equal(2);
    expect(orderWithdrawn.body.groupRep).to.equal(0);
    expect(orderWithdrawn.body.votingWeight).to.equal(100);
    expect(orderWithdrawn.body.distrWeight).to.equal(100);
    expect(orderWithdrawn.body.margin).to.equal("0.0");
    expect(orderWithdrawn.body.inEth).to.equal(false);

    console.log(" \u2714 Passed Event Test for loo.OrderWithdrawn(). Sell Order 4 \n");

    // ==== Place Market Buy Order ====

    auth = await generateAuth(signers[1], cashier.address, 4 * 160);
    tx = await gk.connect(signers[1]).placeMarketBuyOrder(auth, 2, 160 * 10 ** 4, 1);

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(dealClosed[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(dealClosed[0].from.buyer).to.equal(2);
    expect(dealClosed[0].from.groupRep).to.equal(2);
    expect(dealClosed[0].from.classOfShare).to.equal(2);

    expect(dealClosed[0].to.to).to.equal(trimAddr(signers[3].address));
    expect(dealClosed[0].to.seller).to.equal(3);
    expect(dealClosed[0].to.inEth).to.equal(false);

    expect(dealClosed[0].qty.paid).to.equal("60.0");
    expect(dealClosed[0].qty.price).to.equal("4.0");
    expect(dealClosed[0].qty.votingWeight).to.equal(100);
    expect(dealClosed[0].qty.distrWeight).to.equal(100);
    expect(dealClosed[0].qty.consideration).to.equal("240.0");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). deal-0\n");

    expect(dealClosed[1].from.from).to.equal(trimAddr(signers[1].address));
    expect(dealClosed[1].from.buyer).to.equal(2);
    expect(dealClosed[1].from.groupRep).to.equal(2);
    expect(dealClosed[1].from.classOfShare).to.equal(2);

    expect(dealClosed[1].to.to).to.equal(trimAddr(signers[3].address));
    expect(dealClosed[1].to.seller).to.equal(3);
    expect(dealClosed[1].to.inEth).to.equal(false);

    expect(dealClosed[1].qty.paid).to.equal("100.0");
    expect(dealClosed[1].qty.price).to.equal("3.8");
    expect(dealClosed[1].qty.votingWeight).to.equal(100);
    expect(dealClosed[1].qty.distrWeight).to.equal(100);
    expect(dealClosed[1].qty.consideration).to.equal("380.0");
    
    console.log(" \u2714 Passed Event Test for loo.DealClosed(). deal-1 \n");

    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].amt).to.equal('640.0');
    expect(journal[0].remark).to.equal("CustodyValueOfBid");

    expect(journal[1].from).to.equal(signers[1].address);
    expect(journal[1].to).to.equal(signers[3].address);
    expect(journal[1].amt).to.equal('240.0');
    expect(journal[1].remark).to.equal("CloseBidAgainstOffer");

    expect(journal[2].from).to.equal(signers[1].address);
    expect(journal[2].to).to.equal(signers[3].address);
    expect(journal[2].amt).to.equal('380.0');
    expect(journal[2].remark).to.equal("CloseBidAgainstOffer");

    expect(journal[3].from).to.equal(signers[1].address);
    expect(journal[3].to).to.equal(signers[1].address);
    expect(journal[3].amt).to.equal('20.0');
    expect(journal[3].remark).to.equal("RefundBalanceOfBidOrder");

    console.log(" \u2714 Passed Cashier Event Test for cashier. -- Market Buy Order \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('3.8');
    expect(share.body.paid).to.equal('100.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");
    
    // ==== Place Buy Order 5 ====

    auth = await generateAuth(signers[1], cashier.address, 80 * 4);
    tx = await gk.connect(signers[1]).placeBuyOrder(auth, 2, 80 * 10 ** 4, 4 * 10 ** 4, 1);

    transferCBP("2", "8", 88n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(orderPlaced[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(orderPlaced[0].from.buyer).to.equal(2);
    expect(orderPlaced[0].from.groupRep).to.equal(2);
    expect(orderPlaced[0].from.classOfShare).to.equal(2);

    expect(orderPlaced[0].to.to).to.equal(trimAddr(AddrZero));
    expect(orderPlaced[0].to.seller).to.equal(0);
    expect(orderPlaced[0].to.inEth).to.equal(false);
    expect(orderPlaced[0].to.isOffer).to.equal(false);

    expect(orderPlaced[0].qty.paid).to.equal("80.0");
    expect(orderPlaced[0].qty.price).to.equal("4.0");
    expect(orderPlaced[0].qty.votingWeight).to.equal(0);
    expect(orderPlaced[0].qty.distrWeight).to.equal(0);
    expect(orderPlaced[0].qty.consideration).to.equal("320.0");

    expect(orderPlaced[0].isOffer).to.equal(false);

    console.log(" \u2714 Passed Event Test for loo.OrderPlaced(). \n");

    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].amt).to.equal('320.0');
    expect(journal[0].remark).to.equal("CustodyValueOfBid");

    console.log(" \u2714 Passed Cashier Event Test for looKeeper.PlaceBuyOrder(). \n");

    // ---- Market Sell Order ----
    
    tx = await gk.connect(signers[3]).placeSellOrder(2, 1, 80 * 10 ** 4, 0, 1024);

    transferCBP("3", "8", 58n);

    [seqOfOrder, orderPlaced, orderWithdrawn, orderExpired, dealClosed] = await parseOrderLogs(tx);

    expect(dealClosed[0].from.from).to.equal(trimAddr(signers[1].address));
    expect(dealClosed[0].from.buyer).to.equal(2);
    expect(dealClosed[0].from.groupRep).to.equal(2);
    expect(dealClosed[0].from.classOfShare).to.equal(2);

    expect(dealClosed[0].to.to).to.equal(trimAddr(signers[3].address));
    expect(dealClosed[0].to.seller).to.equal(3);
    expect(dealClosed[0].to.inEth).to.equal(false);

    expect(dealClosed[0].qty.paid).to.equal("80.0");
    expect(dealClosed[0].qty.price).to.equal("4.0");
    expect(dealClosed[0].qty.votingWeight).to.equal(100);
    expect(dealClosed[0].qty.distrWeight).to.equal(100);
    expect(dealClosed[0].qty.consideration).to.equal("320.0");

    console.log(" \u2714 Passed Event Test for loo.DealClosed(). \n");

    journal = await parseUsdLogs(tx);

    expect(journal[0].from).to.equal(signers[1].address);
    expect(journal[0].amt).to.equal('320.0');
    expect(journal[0].remark).to.equal("CloseOfferAgainstBid");

    console.log(" \u2714 Passed Cashier Event Test for looKeeper.DealClosed(). \n");

    share = await getLatestShare(ros);

    expect(share.head.shareholder).to.equal(2);
    expect(share.head.priceOfPaid).to.equal('4.0');
    expect(share.body.paid).to.equal('80.0');

    console.log(" \u2714 Passed Result Verify Test for gk.placedBuyOrder(). share issued \n");

    // ==== Place Buy Order To Close all Sell Orders ====

    auth = await generateAuth(signers[1], cashier.address, 100 * 5);
    tx = await gk.connect(signers[1]).placeBuyOrder(auth, 2, 100 * 10 ** 4, 5 * 10 ** 4, 1);
    transferCBP("2", "8", 88n);

    // ==== Init Class 2 ====

    tx = await gk.connect(signers[1]).initClass(2);

    let seaInfo = parseDrop(await cashier.getGulfInfo(2));
    console.log('InitSeaInfo: ', seaInfo);

    await expect(tx).to.emit(cashier, "InitClass").withArgs(BigNumber.from(2), BigNumber.from(20200 * 10 ** 4), BigNumber.from(seaInfo.distrDate));
    console.log(" \u2714 Passed Event Test for cashier.InitClass(2). \n");
  
    // ==== print shares and balances ====

    await printShares(ros);
    await cbpOfUsers(rc, gk.address);

    const getUsdOf = async (signerNo) => {
      let balance = await usdc.balanceOf(signers[signerNo].address);
      console.log("balaneOf User", signerNo, ":", longDataParser(ethers.utils.formatUnits(balance, 6)));
    }

    await getUsdOf(1);
    await getUsdOf(2);
    await getUsdOf(3);

    console.log("balance of Comp:", longDataParser( 
      ethers.utils.formatUnits(await usdc.balanceOf(cashier.address), 6)
    ));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
