

import { keccak256, toUtf8Bytes } from 'ethers';

const sigsAndTitles = [
  // ROCKeeper
  { sig: "createSHA(uint256)", title: 1 },
  { sig: "circulateSHA(address,bytes32,bytes32)", title: 1 },
  { sig: "signSHA(address,bytes32)", title: 1 },
  { sig: "activateSHA(address)", title: 1 },
  { sig: "acceptSHA(bytes32)", title: 1 },
  // RODKeeper
  { sig: "takeSeat(uint256,uint256)", title: 2 },
  { sig: "removeDirector(uint256,uint256)", title: 2 },
  { sig: "takePosition(uint256,uint256)", title: 2 },
  { sig: "removeOfficer(uint256,uint256)", title: 2 },
  { sig: "quitPosition(uint256)", title: 2 },
  // BMMKeeper
  { sig: "nominateOfficer(uint256,uint256)", title: 3 },
  { sig: "createMotionToRemoveOfficer(uint256)", title: 3 },
  { sig: "createMotionToApproveDoc(uint256,uint256,uint256)", title: 3 },
  { sig: "proposeToTransferFundWithBoard(address,bool,uint256,uint256,uint256,uint256)", title: 3 },
  { sig: "createAction(uint256,address[],uint256[],bytes[],bytes32,uint256)", title: 3 },
  { sig: "entrustDelegaterForBoardMeeting(uint256,uint256)", title: 3 },
  { sig: "proposeMotionToBoard(uint256)", title: 3 },
  { sig: "castVote(uint256,uint256,bytes32)", title: 3 },
  { sig: "voteCounting(uint256)", title: 3 },
  { sig: "execAction(uint256,address[],uint256[],bytes[],bytes32,uint256)", title: 3 },
  // ROMKeeper
  { sig: "setMaxQtyOfMembers(uint256)", title: 4 },
  { sig: "setPayInAmt(uint256,uint256,uint256,bytes32)", title: 4 },
  { sig: "requestPaidInCapital(bytes32,string)", title: 4 },
  { sig: "withdrawPayInAmt(bytes32,uint256)", title: 4 },
  { sig: "payInCapital((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256)", title: 4 },
  { sig: "decreaseCapital(uint256,uint256,uint256,uint256)", title: 4 },
  { sig: "updatePaidInDeadline(uint256,uint256)", title: 4 },
  // GMMKeeper
  { sig: "nominateDirector(uint256,uint256)", title: 5 },
  { sig: "createMotionToRemoveDirector(uint256)", title: 5 },
  { sig: "proposeDocOfGM(uint256,uint256,uint256)", title: 5 },
  { sig: "proposeToDistributeUsd(uint256,uint256,uint256,uint256,uint256,uint256)", title: 5 },
  { sig: "proposeToTransferFundWithGM(address,bool,uint256,uint256,uint256,uint256)", title: 5 },
  { sig: "createActionOfGM(uint256,address[],uint256[],bytes[],bytes32,uint256)", title: 5 },
  { sig: "entrustDelegaterForGeneralMeeting(uint256,uint256)", title: 5 },
  { sig: "proposeMotionToGeneralMeeting(uint256)", title: 5 },
  { sig: "castVoteOfGM(uint256,uint256,bytes32)", title: 5 },
  { sig: "voteCountingOfGM(uint256)", title: 5 },
  { sig: "execActionOfGM(uint256,address[],uint256[],bytes[],bytes32,uint256)", title: 5 },
  // ROAKeeper
  { sig: "createIA(uint256)", title: 6 },
  { sig: "circulateIA(address,bytes32,bytes32)", title: 6 },
  { sig: "signIA(address,bytes32)", title: 6 },
  { sig: "pushToCoffer(address,uint256,bytes32,uint256)", title: 6 },
  { sig: "closeDeal(address,uint256,string)", title: 6 },
  { sig: "transferTargetShare(address,uint256)", title: 6 },
  { sig: "issueNewShare(address,uint256)", title: 6 },
  { sig: "terminateDeal(address,uint256)", title: 6 },
  { sig: "payOffApprovedDeal((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),address,uint256,address)", title: 6 },
  // ROOKeeper
  { sig: "updateOracle(uint256,uint256,uint256,uint256)", title: 7 },
  { sig: "execOption(uint256)", title: 7 },
  { sig: "createSwap(uint256,uint256,uint256,uint256)", title: 7 },
  { sig: "payOffSwap((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,address)", title: 7 },
  { sig: "terminateSwap(uint256,uint256)", title: 7 },
  // ROPKeeper
  { sig: "createPledge(bytes32,uint256,uint256,uint256,uint256)", title: 8 },
  { sig: "transferPledge(uint256,uint256,uint256,uint256)", title: 8 },
  { sig: "refundDebt(uint256,uint256,uint256)", title: 8 },
  { sig: "extendPledge(uint256,uint256,uint256)", title: 8 },
  { sig: "lockPledge(uint256,uint256,bytes32)", title: 8 },
  { sig: "releasePledge(uint256,uint256,string)", title: 8 },
  { sig: "execPledge(uint256,uint256,uint256,uint256)", title: 8 },
  { sig: "revokePledge(uint256,uint256)", title: 8 },
  // SHAKeeper
  { sig: "execAlongRight(address,bytes32,bytes32)", title: 9 },
  { sig: "acceptAlongDeal(address,uint256,bytes32)", title: 9 },
  { sig: "execAntiDilution(address,uint256,uint256,bytes32)", title: 9 },
  { sig: "takeGiftShares(address,uint256)", title: 9 },
  { sig: "execFirstRefusal(uint256,uint256,address,uint256,bytes32)", title: 9 },
  { sig: "computeFirstRefusal(address,uint256)", title: 9 },
  // LOOKeeper
  { sig: "placeInitialOffer(uint256,uint256,uint256,uint256,uint256)", title: 10 },
  { sig: "withdrawInitialOffer(uint256,uint256,uint256)", title: 10 },
  { sig: "placeSellOrder(uint256,uint256,uint256,uint256,uint256)", title: 10 },
  { sig: "withdrawSellOrder(uint256,uint256)", title: 10 },
  { sig: "placeBuyOrder((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,uint256,uint256)", title: 10 },
  { sig: "placeMarketBuyOrder((address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32),uint256,uint256,uint256)", title: 10 },
  { sig: "withdrawBuyOrder(uint256,uint256)", title: 10 },
  // ROIKeeper
  { sig: "pause(uint256)", title: 11 },
  { sig: "unPause(uint256)", title: 11 },
  { sig: "freezeShare(uint256,uint256,uint256,bytes32)", title: 11 },
  { sig: "unfreezeShare(uint256,uint256,uint256,bytes32)", title: 11 },
  { sig: "forceTransfer(uint256,uint256,uint256,address,bytes32)", title: 11 },
  { sig: "regInvestor(address,uint256,bytes32)", title: 11 },
  { sig: "approveInvestor(uint256,uint256)", title: 11 },
  { sig: "revokeInvestor(uint256,uint256)", title: 11 },
  // Accountant
  { sig: "initClass(uint256)", title: 12 },
  { sig: "distrProfits(uint256,uint256,uint256,uint256)", title: 12 },
  { sig: "distrIncome(uint256,uint256,uint256,uint256,uint256)", title: 12 },
  { sig: "transferFund(bool,address,bool,uint256,uint256,uint256)", title: 12 },
  // RORKeeper
  { sig: "addRedeemableClass(uint256)", title: 16 },
  { sig: "removeRedeemableClass(uint256)", title: 16 },
  { sig: "updateNavPrice(uint256,uint256)", title: 16 },
  { sig: "requestForRedemption(uint256,uint256)", title: 16 },
  { sig: "redeem(uint256,uint256)", title: 16 }
];

// 计算 selector（bytes4）并加入数据
const calcSelector = sig => '0x' + keccak256(toUtf8Bytes(sig)).slice(2, 10);

const sigObjArr = sigsAndTitles.map(item => ({
  selector: calcSelector(item.sig),
  title: item.title
}));

// 按 selector 升序排序
sigObjArr.sort((a, b) =>
  a.selector.localeCompare(b.selector)
);

// 输出 Solidity 数组代码
const sigsArr = sigObjArr.map(it => it.selector).join(',\n    ');
const titlesArr = sigObjArr.map(it => it.title).join(', ');

console.log(`bytes4[] sigs = [
    ${sigsArr}
];`);
console.log(`uint8[] titles = [
    ${titlesArr}
];`);