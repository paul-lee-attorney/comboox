// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2026 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import { network } from "hardhat";
import { readTool } from "../../../scripts/readTool";
import { getAllUsers } from "../../../scripts/testing/rc";

const addrs = {
	"RC": "0xca8824A0254540547944E38A61C9801075E2E101",
	"ROS": "0x88844a809bcd4c159a8ec6fdf2511421abb1ee17",
	"ROM": "0x8290ca1062d4d6b0cedf213992d74940a10b685f",
	"ROS2": "0xb39580b071dd696589e14f445f105657c44492d0",
	"ROM2": "0x65e8f5e03ca4794bfc5694dcd871838bdb70a114",
};

async function main() {
	
	const { ethers } = await network.connect();

	const signers = await ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress()
	);

	const rc = await readTool("RegCenter", addrs.RC);
	const users = await getAllUsers(rc, 1);

	console.log("Account balance:", (await ethers.provider.getBalance(signers[0])).toString());

	const ros_1 = await readTool("RegisterOfShares", addrs.ROS);
	const rom_1 = await readTool("RegisterOfMembers", addrs.ROM);

	const ros_2 = await readTool("RegisterOfShares", addrs.ROS2);
	const rom_2 = await readTool("RegisterOfMembers", addrs.ROM2);

	// ==== Copy ROS ====

	let share0 = await ros_1.getShareZero();
	let shares = await ros_1.getSharesList();
	
	let sharesList = [];
	
	const getUserNo = (seq) => {
		seq = Number(seq);		

		const res = seq > 0
					? seq < 3
						? users[seq - 1]
						: seq == 7
							? users[2]
							: users[seq]
					: 0;

		return res;
	}

	const parseShare = (share) => {
		return({
			head: {
				class: share[0][0],
				seqOfShare: share[0][1],
				preSeq: share[0][2],
				issueDate: share[0][3],
				shareholder: getUserNo(share[0][4]),
				priceOfPaid: share[0][5],
				priceOfPar: share[0][6],
				votingWeight: share[0][7],
				argu: share[0][8],
			},
			body: {
				payInDeadline: share[1][0],
				paid: share[1][1],
				par: share[1][2],
				cleanPaid: share[1][3],
				distrWeight:share[1][4],
			},
		});
	}

	// share0 = {
	// 	head: {
	// 		class: 2,
	// 		seqOfShare: 12,
	// 		preSeq: 0,
	// 		issueDate: 0,
	// 		shareholder: 0,
	// 		priceOfPaid: 0,
	// 		priceOfPar: 0,
	// 		votingWeight: 0,
	// 		argu: 0,
	// 	},
	// 	body: {
	// 		payInDeadline: 0,
	// 		paid: ethers.BigNumber.from(0),
	// 		par: ethers.BigNumber.from(0),
	// 		cleanPaid: ethers.BigNumber.from(0),
	// 		distrWeight:0,
	// 	},
	// };

	// // input premium of 959910 i.e. 0x0ea5a6 into share0.body
	// share0.body.distrWeight = 42406;
	// share0.body.cleanPaid = hre.ethers.BigNumber.from(14);

	sharesList.push(parseShare(share0));

	let len = shares.length;
	let i = 0;
	while (i < len) {
		sharesList.push(parseShare(shares[i]));
		i++;
	}
	
	len = await ros_1.counterOfClasses();
	i = 1;

	let infoList = [];
	while (i <= len) {
		let info = await ros_1.getInfoOfClass(i);
		infoList.push(parseShare(info));
		i++;
	}

	console.log('sharesList: ', sharesList);
	console.log('infoList: ', infoList);
	
	await ros_2.connect(signers[1]).restoreShares(sharesList, infoList);

	shares = await ros_2.getSharesList();
	shares = shares.map(v => parseShare(v));
	console.log('ros_2 shares:', shares, '\n');

	share0 = await ros_2.getShareZero();
	share0 = parseShare(share0);
	console.log('ros_2 share0:', share0, '\n');

	i = 1;
	while (i <= len) {
		let info = await ros_2.getInfoOfClass(i);
		console.log('ros_2 info of class[', i, ']: ', parseShare(info), '\n');
		i++;
	}

	// ==== Copy ROM ====
	
	await rom_2.connect(signers[1]).restoreSharesInRom(sharesList.slice(1));
	console.log('restored shares into ROM_2. \n');

	const [topChain, para] = await rom_1.getSnapshot();

	const parseTopChain = (chain) => {
		return (chain.map(v => ({
			prev: getUserNo(v[0]),
			next: getUserNo(v[1]),
			ptr: getUserNo(v[2]),
			amt: v[3],
			sum: v[4],
			cat: v[5],
		})));
	}
	
	let objChain = parseTopChain(topChain);

	const parsePara = (v) => {
		return ({
			tail: getUserNo(v[0]),
			head: getUserNo(v[1]),
			maxQtyOfMembers: v[2],
			minVoteRatioOnChain: v[3],
			qtyOfSticks: v[4],
			qtyOfBranches: v[5],
			qtyOfMembers: v[6],
			para: v[7],
			argu: v[8]		
		});
	}

	let objPara = parsePara(para);

	console.log('get topChain snapshot from rom_1: ', objChain);
	console.log('get para from rom_1: ', objPara);

	await rom_2.connect(signers[1]).restoreTopChainInRom(objChain, objPara);
	console.log('restore topChain in Rom_2 \n');

	// ---- Owners Equity ----

	const parseCheckpoint = (cp) => {
		return({
			timestamp: cp[0],
			rate: cp[1],
			paid: cp[2],
			par: cp[3],
			points: cp[4],
		});
	}

	let votesList = await rom_1.ownersEquityHistory();

	// let votesList = []

	// let timestamps = [1732767261, 1732768206, 1732768366, 1732768652, 1732768818, 1732769078, 1732769147,  1732769414];
	// let cp = {};

	// len = timestamps.length;
	// i = 0;
	
	// while (i < len) {
	// 	cp = await rom_1.capAtDate(timestamps[i]);
	// 	votesList.push(parseCheckpoint(cp));	
	// 	i++;
	// }

	let distrPts = await rom_1.ownersPoints();

	votesList = votesList.map(v => parseCheckpoint(v));
	distrPts = parseCheckpoint(distrPts);

	console.log('obtained ownersEquityHistory of Rom_1: ', votesList, '\n');
	console.log('obtained distrPts of Rom_1: ', distrPts, '\n');

	await rom_2.connect(signers[1]).restoreVotesHistoryInRom(0, votesList, distrPts);
	console.log('restored ownersEquityHistory and distrPts into Rom_2. \n');

	let outVotesList = await rom_2.ownersEquityHistory();
	outVotesList = outVotesList.map(v => parseCheckpoint(v));

	let outDistrPts = await rom_2.ownersPoints();
	outDistrPts = parseCheckpoint(outDistrPts);

	console.log('obtained ownersEquityHistory of Rom_2: ', outVotesList, '\n');
	console.log('obtained distrPts of Rom_2: ', outDistrPts, '\n');

	// ---- Members Votes ----

	let memberSeqList = await rom_1.membersList();
	memberSeqList = memberSeqList.map(v => Number(v));

	len = memberSeqList.length;
	i = 0;

	while (i < len) {
		let acct = memberSeqList[i];
		
		votesList = await rom_1.votesHistory(acct);
		votesList = votesList.map(v => parseCheckpoint(v));

		distrPts = await rom_1.pointsOfMember(acct);
		distrPts = parseCheckpoint(distrPts);

		const user = getUserNo(acct);

		await rom_2.connect(signers[1]).restoreVotesHistoryInRom(user, votesList, distrPts);
		console.log('restored votesHistory and distrPts of acct:', user, ' into Rom_2. \n');
		
		outVotesList = await rom_2.votesHistory(user);
		outVotesList = outVotesList.map(v => parseCheckpoint(v));
	
		outDistrPts = await rom_2.pointsOfMember(user);
		outDistrPts = parseCheckpoint(outDistrPts);
	
		console.log('obtained votesHistor for acct', user, ' of Rom_2: ', outVotesList, '\n');
		console.log('obtained points for acct', user, ' of Rom_2: ', outDistrPts, '\n');
	
		i++;
	}
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
