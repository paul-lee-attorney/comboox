// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_240912_Arbi");
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

	libraries = {
		"BallotsBox": addrs.BallotsBox,
		"DelegateMap": addrs.DelegateMap,
		"EnumerableSet": addrs.EnumerableSet,
		"RulesParser": addrs.RulesParser
	};
	const libMotionsRepo = await deployTool(signers[0], "MotionsRepo", libraries, params);

	// ==== Deploy RegCenter ====

	let rc = await readContract("RegCenter", addrs.RegCenter);

	libraries = {
		"MotionsRepo": libMotionsRepo.address
	}
	let mm = await deployTool(signers[0], "MeetingMinutes", libraries, params);

	// ==== SetTemplate ====

	await rc.connect(signers[1]).setTemplate(13, mm.address, 8);
	console.log("set template for MM at address: ", mm.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
