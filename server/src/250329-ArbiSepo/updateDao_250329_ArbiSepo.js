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

	const usdKeeperAddr = await gk.getKeeper(15);

	const usdKeeper = await readContract("USDKeeper", usdKeeperAddr);

	await gk.connect(signers[1]).takeBackKeys(usdKeeper.address);


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

	let orgKeeperAddr = await gk.getKeeper(13);
	let orgKeeper = await readContract("UsdLOOKeeper", orgKeeperAddr);
	let orgBookAddr = await gk.getBook(13);
	let orgBook = await readContract("UsdListOfOrders", orgBookAddr);

	usdKeeper.connect(signers[1]).takeBackKeys(orgKeeperAddr);
	orgKeeper.connect(signers[1]).takeBackKeys(orgBookAddr);

	orgBook.connect(signers[1]).setDirectKeeper(usdLooKeeper.address);
	orgKeeper.connect(signers[1]).setDirectKeeper(usdKeeper.address);

	tx = await gk.connect(signers[1]).regKeeper(13, usdLooKeeper.address);
	console.log("reg keeper of UsdLooKeeper. \n");

	// ---- UsdRooKeeper ----

	addrOfDoc = await createDoc(34); 
	const usdRooKeeper = await readContract("UsdROOKeeper", addrOfDoc);

	tx = await usdRooKeeper.initKeepers(usdKeeper.address, gk.address);
	console.log("init keepers of UsdRooKeeper. \n");

	tx = await gk.connect(signers[1]).regKeeper(14, usdRooKeeper.address);
	console.log("reg keeper of UsdRooKeeper. \n");

	// ---- Cashier ----

	addrOfDoc = await createDoc(28); 
	const cashier = await readContract("Cashier", addrOfDoc);

	tx = await cashier.initKeepers(usdKeeper.address, gk.address);
	console.log("init keepers of Cashier. \n");

	tx = await gk.connect(signers[1]).regBook(11, cashier.address);
	console.log("reg book of Cashier. \n");

	// ---- restore DK of UsdKeeper ----

	usdKeeper.connect(signers[1]).setDirectKeeper(gk.address);
	console.log("restore DK of UsdKeeper. \n");

	
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
