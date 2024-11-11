// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_241110_Arbi");
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

	// ==== update libs ====

	libraries = {
		"RulesParser": addrs.RulesParser,		
	}
	const shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries, params);

	// ==== Reg Templates ====

	await rc.connect(signers[1]).setTemplate( 9, shaKeeper.address, 8);
	console.log("set template for SHAKeeper at address: ", shaKeeper.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
