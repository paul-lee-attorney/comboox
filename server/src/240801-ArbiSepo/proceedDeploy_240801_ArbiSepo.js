// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_240713_ArbiSepo");
const { readContract } = require("../../../scripts/readTool");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress()
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	let libraries = {};
	let params = [];

	// ==== Libraries ====		
	const libArrayUtils = await deployTool(signers[0], "ArrayUtils", libraries, params);

	libraries = {
		"BallotsBox": addrs.BallotsBox,
		"DelegateMap": addrs.DelegateMap,
		"EnumerableSet": addrs.EnumerableSet,
		"RulesParser": addrs.RulesParser
	};
	const libMotionsRepo = await deployTool(signers[0], "MotionsRepo", libraries, params);

	let rc = await readContract("RegCenter_2", addrs.RegCenter_2);

	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"RulesParser": addrs.RulesParser,
		"ArrayUtils": libArrayUtils.address,
	}
	let gmmKeeper_4 = await deployTool(signers[0], "GMMKeeper_4", libraries, params);
	let bmmKeeper_4 = await deployTool(signers[0], "BMMKeeper_4", libraries, params);

	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"MotionsRepo": libMotionsRepo.address
	}
	let mm_2 = await deployTool(signers[0], "MeetingMinutes", libraries, params);

	await rc.connect(signers[1]).setTemplate( 3, bmmKeeper_4.address, 1);
	console.log("set template for BMMKeeper_4 at address: ", bmmKeeper_4.address, "\n");

	await rc.connect(signers[1]).setTemplate( 5, gmmKeeper_4.address, 1);
	console.log("set template for GMMKeeper_4 at address: ", gmmKeeper_4.address, "\n");

	await rc.connect(signers[1]).setTemplate( 13, mm_2.address, 1);
	console.log("set template for MM_2 at address: ", mm_2.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
