// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_240801_Arbi");
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

	let rc = await readContract("RegCenter_2", addrs.RegCenter_2);
	console.log("get RegCenter_2 at:", rc.address);

	libraries = {
		"ArrayUtils": addrs.ArrayUtils,
		"DocsRepo": addrs.DocsRepo,
		"RolesRepo": addrs.RolesRepo,
		"RulesParser": addrs.RulesParser		
	}
	let rocKeeper_3 = await deployTool(signers[0], "ROCKeeper_3", libraries, params);

	await rc.connect(signers[1]).setTemplate( 1, rocKeeper_3.address, 1);
	console.log("set template for ROCKeeper_3 at address: ", rocKeeper_3.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
