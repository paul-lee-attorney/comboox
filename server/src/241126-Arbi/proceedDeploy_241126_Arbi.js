// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_241111_Arbi");
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

	const romKeeper = await deployTool(signers[0], "ROMKeeper", libraries, params);

	// ==== Reg Templates ====

	await rc.connect(signers[1]).setTemplate( 4, romKeeper.address, 8);
	console.log("set template for ROMKeeper at address: ", romKeeper.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
