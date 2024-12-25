// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_241128_Arbi");
const { readContract } = require("../../../scripts/readTool");


async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress()
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	const rc = await readContract("RegCenter", addrs.RegCenter);

	let libraries = {};
	let params = [];

	// ---- Lib ----

	libraries = {
		"Checkpoints": addrs.Checkpoints,
		"EnumerableSet": addrs.EnumerableSet,
		"TopChain": addrs.TopChain
	};
	const libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries, params);

	// ---- Boox ----

	libraries = {
		"MembersRepo": libMembersRepo.address,
		"TopChain": addrs.TopChain
	}
	let rom = await deployTool(signers[0], "RegisterOfMembers", libraries, params);

	// ---- Reg Boox ----

	await rc.connect(signers[1]).setTemplate(14, rom.address, 8);
	console.log("set template for ROM at address: ", rom.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
