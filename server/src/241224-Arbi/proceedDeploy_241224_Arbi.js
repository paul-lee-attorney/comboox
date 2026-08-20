// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { readContract } = require("../../../scripts/readTool");
const { RegCenter, EnumerableSet, TopChain, LockersRepo, } = require("../241220-Arbi/contracts-address-consolidated.json");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress()
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	const rc = await readContract("RegCenter", RegCenter);

	let libraries = {};
	let params = [];

	// ---- Lib ----

	const libCheckpoints = await deployTool(signers[0], "Checkpoints", libraries, params);

	libraries = {
		"EnumerableSet": EnumerableSet,
	};
	const libSharesRepo = await deployTool(signers[0], "SharesRepo", libraries, params);

	libraries = {
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": EnumerableSet,
		"TopChain": TopChain
	};
	const libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries, params);

	// ---- Template ----

	libraries = {
		"LockersRepo": LockersRepo,
		"SharesRepo": libSharesRepo.address
	}
	const ros = await deployTool(signers[0], "RegisterOfShares", libraries, params);

	libraries = {
		"Checkpoints": libCheckpoints.address,
		"MembersRepo": libMembersRepo.address,
		"TopChain": TopChain
	}
	const rom = await deployTool(signers[0], "RegisterOfMembers", libraries, params);

	// ---- Registration ----

	await rc.connect(signers[1]).setTemplate( 14, rom.address, 8);
	console.log("set template for ROM at address: ", rom.address, "\n");

	await rc.connect(signers[1]).setTemplate( 18, ros.address, 8);
	console.log("set template for ROS at address: ", ros.address, "\n");
	
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
