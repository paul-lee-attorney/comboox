// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_241126_ArbiSepo");
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

	const libTopChain = await deployTool(signers[0], "TopChain", libraries, params);

	libraries = {
		"Checkpoints": addrs.Checkpoints,
		"EnumerableSet": addrs.EnumerableSet,
		"TopChain": libTopChain.address
	};
	const libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries, params);

	// ---- Boox ----

	libraries = {
		"DTClaims": addrs.DTClaims,
		"FilesRepo": addrs.FilesRepo,
		"FRClaims": addrs.FRClaims,
		"TopChain": libTopChain.address
	}
	let roa = await deployTool(signers[0], "RegisterOfAgreements", libraries, params);


	libraries = {
		"MembersRepo": libMembersRepo.address,
		"TopChain": libTopChain.address
	}
	let rom = await deployTool(signers[0], "RegisterOfMembers", libraries, params);

	// ---- Reg Boox ----

	await rc.connect(signers[1]).setTemplate( 14, rom.address, 8);
	console.log("set template for ROM at address: ", rom.address, "\n");

	await rc.connect(signers[1]).setTemplate( 15, roa.address, 8);
	console.log("set template for ROA at address: ", roa.address, "\n");


};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
