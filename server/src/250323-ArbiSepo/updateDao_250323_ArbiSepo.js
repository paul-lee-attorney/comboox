// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { 
	RegCenter, USDC, 
} = require("./contracts-address-consolidated.json")
const { readContract } = require("../../../scripts/readTool");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress(), "\n"
	);
	console.log("Account balance:", (await signers[0].getBalance()).toString());

	const rc = await readContract("RegCenter", RegCenter);

	const usdc = await readContract("IUSDC", USDC);

	const addrOfGK = (await rc.getDocByUserNo(8)).body;
	const gk = await readContract("GeneralKeeper", addrOfGK); 

	let addrOfDoc = '';

	// ==== Add Keepers ====

	// ---- Create Doc Tool ----

	const getSnOfDoc = async (typeOfDoc) => {
		let version = await rc.counterOfVersions(typeOfDoc);
		let snOfDoc =  `0x${typeOfDoc.toString(16).padStart(8, '0') + version.toString(16).padStart(8, '0') + '0'.padStart(48, '0')}`;	

		return snOfDoc;
	}

	const createDoc = async (typeOfDoc) => {
		const snOfDoc = await getSnOfDoc(typeOfDoc);
		const tx = await rc.createDoc(snOfDoc, signers[0].address);
		const receipt = await tx.wait();
		const addr = '0x' + receipt.logs[0].topics[2].substring(26);

		console.log('addr of Doc:', addr, '\n');
		return addr;
	}

	// ---- USDKeeper ----

	addrOfDoc = await createDoc(30); // usdKeeper;
	const usdKeeper = await readContract("USDKeeper", addrOfDoc);

	let tx = await usdKeeper.initKeepers(gk.address, gk.address);
	console.log("init keepers of UsdKeeper.\n");

	tx = await gk.connect(signers[1]).regKeeper(15, usdKeeper.address);
	console.log("reg keeper of UsdKeeper.\n");

	// ---- UsdRomKeeper ----

	addrOfDoc = await createDoc(31); // usdRomKeeper;
	const usdRomKeeper = await readContract("UsdROMKeeper", addrOfDoc);

	tx = await usdRomKeeper.initKeepers(usdKeeper.address, gk.address);
	console.log("init keepers of UsdRomKeeper.\n");

	tx = await gk.connect(signers[1]).regKeeper(11, usdRomKeeper.address);
	console.log("reg keeper of UsdRomKeeper.\n");

	// ---- UsdRoaKeeper ----

	addrOfDoc = await createDoc(32); // usdRoaKeeper;
	const usdRoaKeeper = await readContract("UsdROAKeeper", addrOfDoc);

	tx = await usdRoaKeeper.initKeepers(usdKeeper.address, gk.address);
	console.log("init keepers of UsdRoaKeeper. \n");

	tx = await gk.connect(signers[1]).regKeeper(12, usdRoaKeeper.address);
	console.log("reg keeper of UsdRoaKeeper. \n");
	
	// ---- UsdLooKeeper ----

	addrOfDoc = await createDoc(33); 
	const usdLooKeeper = await readContract("UsdLOOKeeper", addrOfDoc);

	tx = await usdLooKeeper.initKeepers(usdKeeper.address, gk.address);
	console.log("init keepers of UsdLooKeeper. \n");

	tx = await gk.connect(signers[1]).regKeeper(13, usdLooKeeper.address);
	console.log("reg keeper of UsdLooKeeper. \n");

	// ---- UsdRooKeeper ----

	addrOfDoc = await createDoc(34); 
	const usdRooKeeper = await readContract("UsdROOKeeper", addrOfDoc);

	tx = await usdRooKeeper.initKeepers(usdKeeper.address, gk.address);
	console.log("init keepers of UsdRooKeeper. \n");

	tx = await gk.connect(signers[1]).regKeeper(14, usdRooKeeper.address);
	console.log("reg keeper of UsdRooKeeper. \n");

	// ---- LOOKeeper ----
	addrOfDoc = await createDoc(10); 
	const looKeeper = await readContract("LOOKeeper", addrOfDoc);

	tx = await looKeeper.initKeepers(gk.address, gk.address);
	console.log("init keeper of LOOKeeper. \n");

	tx = await gk.connect(signers[1]).regKeeper(10, looKeeper.address);
	console.log("reg keeper of looKeeper. \n");	

	// ---- LOO ----
	addrOfDoc = await createDoc(19); 
	const loo = await readContract("ListOfOrders", addrOfDoc);

	tx = await loo.initKeepers(looKeeper.address, gk.address);
	console.log("init keeper of LOO. \n");

	tx = await gk.connect(signers[1]).regBook(10, loo.address);
	console.log("reg Book of LOO. \n")

	// ---- ROOKeeper ----
	addrOfDoc = await createDoc(7); 
	const rooKeeper = await readContract("ROOKeeper", addrOfDoc);

	tx = await rooKeeper.initKeepers(gk.address, gk.address);
	console.log("init keeper of ROOKeeper. \n");

	tx = await gk.connect(signers[1]).regKeeper(7, rooKeeper.address);
	console.log("reg keeper of rooKeeper. \n");

	// ---- ROO ----
	addrOfDoc = await createDoc(16); 
	const roo = await readContract("RegisterOfOptions", addrOfDoc);

	tx = await roo.initKeepers(rooKeeper.address, gk.address);
	console.log("init keepers of ROO. \n");

	tx = await gk.connect(signers[1]).regBook(7, roo.address);
	console.log("reg Book of ROO. \n");

	// ---- ROAKeeper ----
	addrOfDoc = await createDoc(6); 
	const roaKeeper = await readContract("ROAKeeper", addrOfDoc);

	tx = await roaKeeper.initKeepers(gk.address, gk.address);
	console.log("init keeper of ROAKeeper. \n");

	const addrOfROAKeeper_0 = await gk.getKeeper(6);
	const roaKeeper_0 = await readContract("ROAKeeper", addrOfROAKeeper_0);
	const addrOfROA_0 = await gk.getBook(6);
	const roa_0 = await readContract("RegisterOfAgreements", addrOfROA_0);

	await gk.connect(signers[1]).takeBackKeys(addrOfROAKeeper_0);
	await roaKeeper_0.connect(signers[1]).takeBackKeys(addrOfROA_0);
	
	await roa_0.connect(signers[1]).setDirectKeeper(roaKeeper.address);
	await roaKeeper_0.connect(signers[1]).setDirectKeeper(gk.address);

	tx = await gk.connect(signers[1]).regKeeper(6, roaKeeper.address);
	console.log("reg keeper of roaKeeper. \n");
	
	// ---- Cashier ----

	addrOfDoc = await createDoc(28); 
	const cashier = await readContract("Cashier", addrOfDoc);

	tx = await cashier.initKeepers(usdKeeper.address, gk.address);
	console.log("init keepers of Cashier. \n");

	tx = await gk.connect(signers[1]).regBook(11, cashier.address);
	console.log("reg book of Cashier. \n");

	// ---- USDC ----

	tx = await gk.connect(signers[1]).regBook(12, usdc.address);
	console.log("reg book of USDC. \n");
	
	// ---- LOU ----

	addrOfDoc = await createDoc(29); 
	const lou = await readContract("UsdListOfOrders", addrOfDoc);

	tx = await lou.initKeepers(usdLooKeeper.address, gk.address);
	console.log("init keepers of LOU. \n");

	tx = await gk.connect(signers[1]).regBook(13, lou.address);
	console.log("reg book of LOU. \n");

	// ==== Replace Boox ====

	// ---- Copy info of Ros_0 ----

	const parseShare = (share) => {
		return({
			head: {
				class: share[0][0],
				seqOfShare: share[0][1],
				preSeq: share[0][2],
				issueDate: share[0][3],
				shareholder: share[0][4],
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

	// ---- Get ROS_0 ----

	const addrOfRos = await gk.getBook(9);
	const ros_0 = await readContract("RegisterOfShares", addrOfRos);
	
	let share_0 = await ros_0.getShareZero();

	let sharesList = [];
	sharesList.push(parseShare(share_0));

	let shares = await ros_0.getSharesList();
	let len = shares.length;
	let i = 0;
	while(i < len) {
		sharesList.push(parseShare(shares[i]));
		i++;
	}

	len = await ros_0.counterOfClasses();
	i = 1;

	let infoList = [];
	while (i <= len) {
		let info = await ros_0.getInfoOfClass(i);
		infoList.push(parseShare(info));
		i++;
	}

	console.log('sharesList: ', sharesList, '\n');
	console.log('infoList: ', infoList, '\n');

	// ---- Create Ros_1 ----

	addrOfDoc = await createDoc(18); 
	const ros_1 = await readContract("RegisterOfShares", addrOfDoc);
	
	tx = await ros_1.initKeepers(signers[0].address, gk.address);
	console.log("init keepers of ROS_1. \n");

	tx = await gk.connect(signers[1]).regBook(9, ros_1.address);
	console.log("reg book of ROS_1. \n");

	
	// ---- Restore Data into Ros_1 ----

	ros_1.restoreShares(sharesList, infoList);
	console.log('restore shares of ROS', '\n');

	shares = await ros_1.getSharesList();
	shares = shares.map(v => parseShare(v));
	console.log('ros_1 shares:', shares, '\n');

	share_0 = await ros_1.getShareZero();
	share_0 = parseShare(share_0);
	console.log('ros_1 share0:', share_0, '\n');

	i = 1;
	while (i <= len) {
		let info = await ros_1.getInfoOfClass(i);
		console.log('ros_1 info of class[', i, ']: ', parseShare(info), '\n');
		i++;
	}

	// ---- Get Rom_0 ----
	addrOfDoc = await gk.getBook(4);
	const rom_0 = await readContract("RegisterOfMembers", addrOfDoc);
	
	// ---- Create Rom_1 ----
	
	addrOfDoc = await createDoc(14); 
	const rom_1 = await readContract("RegisterOfMembers", addrOfDoc);
	
	tx = await rom_1.initKeepers(signers[0].address, gk.address);
	console.log("init keepers of ROM_1. \n");

	tx = await gk.connect(signers[1]).regBook(4, rom_1.address);
	console.log("reg book of ROM_1. \n");

	// ---- Restore SharesInRom ----

	await rom_1.restoreSharesInRom(sharesList.slice(1));
	console.log('restored shares into ROM_1. \n');

	// ---- Restore TopChain ----


	const [topChain, para] = await rom_0.getSnapshot();

	const parseTopChain = (chain) => {
		return (chain.map(v => ({
			prev: v[0],
			next: v[1],
			ptr: v[2],
			amt: v[3],
			sum: v[4],
			cat: v[5],
		})));
	}
	
	let objChain = parseTopChain(topChain);

	const parsePara = (v) => {
		return ({
			tail: v[0],
			head: v[1],
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

	console.log('get topChain snapshot from rom_0: ', objChain, '\n');
	console.log('get para from rom_0: ', objPara, '\n');

	await rom_1.restoreTopChainInRom(objChain, objPara);
	console.log('restore topChain in Rom_1 \n');

	// ---- Restore Ownership Votes History -----

	const parseCheckpoint = (cp) => {
		return({
			timestamp: cp[0],
			rate: cp[1],
			paid: cp[2],
			par: cp[3],
			points: cp[4],
		});
	}

	let votesList = await rom_0.ownersEquityHistory();
	votesList = votesList.map(v => parseCheckpoint(v));
	
	let distrPts = await rom_0.ownersPoints();
	distrPts = parseCheckpoint(distrPts);

	console.log('obtained ownersEquityHistory of Rom_0: ', votesList, '\n');
	console.log('obtained distrPts of Rom_0: ', distrPts, '\n');

	await rom_1.restoreVotesHistoryInRom(0, votesList, distrPts);
	console.log('restored ownersEquityHistory and distrPts into Rom_1. \n');

	let outVotesList = await rom_1.ownersEquityHistory();
	outVotesList = outVotesList.map(v => parseCheckpoint(v));

	let outDistrPts = await rom_1.ownersPoints();
	outDistrPts = parseCheckpoint(outDistrPts);

	console.log('obtained ownersEquityHistory of Rom_1: ', outVotesList, '\n');
	console.log('obtained distrPts of Rom_1: ', outDistrPts, '\n');

	// ---- Members Votes ----

	let memberSeqList = await rom_0.membersList();
	memberSeqList = memberSeqList.map(v => Number(v));

	len = memberSeqList.length;
	i = 0;

	while (i < len) {
		let acct = memberSeqList[i];
		
		votesList = await rom_0.votesHistory(acct);
		votesList = votesList.map(v => parseCheckpoint(v));

		distrPts = await rom_0.pointsOfMember(acct);
		distrPts = parseCheckpoint(distrPts);

		await rom_1.restoreVotesHistoryInRom(acct, votesList, distrPts);
		console.log('restored votesHistory and distrPts of acct:', acct, ' into Rom_1. \n');
		
		outVotesList = await rom_1.votesHistory(acct);
		outVotesList = outVotesList.map(v => parseCheckpoint(v));
	
		outDistrPts = await rom_1.pointsOfMember(acct);
		outDistrPts = parseCheckpoint(outDistrPts);
	
		console.log('obtained votesHistor for acct', acct, ' of Rom_1: ', outVotesList, '\n');
		console.log('obtained points for acct', acct, ' of Rom_1: ', outDistrPts, '\n');
	
		i++;
	}

	// ==== transfer DK to Keepers ====
	const addrOfROMK = await gk.getKeeper(4);

	await ros_1.setDirectKeeper(addrOfROMK);
	console.log("transfer DK of Ros_1 to ROMKeeper \n");

	await rom_1.setDirectKeeper(addrOfROMK);
	console.log("transfer DK of Rom_1 to ROMKeeper \n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
