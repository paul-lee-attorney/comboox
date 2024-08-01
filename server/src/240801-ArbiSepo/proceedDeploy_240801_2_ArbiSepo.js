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

	libraries = {
		"EnumerableSet": addrs.EnumerableSet,
	};	
	const libFilesRepo = await deployTool(signers[0], "FilesRepo", libraries, params);

	let rc = await readContract("RegCenter_2", addrs.RegCenter_2);

	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"DTClaims": addrs.DTClaims,
		"FilesRepo": libFilesRepo.address,
		"FRClaims": addrs.FRClaims,
		"TopChain": addrs.TopChain
	}
	let roa_2 = await deployTool(signers[0], "RegisterOfAgreements", libraries, params);

	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"FilesRepo": libFilesRepo.address
	}
	let roc_2 = await deployTool(signers[0], "RegisterOfConstitution", libraries, params);

	await rc.connect(signers[1]).setTemplate( 11, roc_2.address, 1);
	console.log("set template for ROC_2 at address: ", roc_2.address, "\n");

	await rc.connect(signers[1]).setTemplate( 15, roa_2.address, 1);
	console.log("set template for ROA_2 at address: ", roa_2.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
