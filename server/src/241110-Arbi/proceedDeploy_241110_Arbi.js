// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_240918_Arbi");
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

	const libFRClaims = await deployTool(signers[0], "FRClaims", libraries, params);

	// ==== update boox ====

	libraries = {
		"DTClaims": addrs.DTClaims,
		"FilesRepo": addrs.FilesRepo,
		"FRClaims": libFRClaims.address,
		"TopChain": addrs.TopChain,
	}
	const roa = await deployTool(signers[0], "RegisterOfAgreements", libraries, params);

	// ==== update Keepers ====

	libraries = {
		"DocsRepo": addrs.DocsRepo,
		"RulesParser": addrs.RulesParser,		
	}
	const roaKeeper = await deployTool(signers[0], "ROAKeeper", libraries, params);


	libraries = {
		"RulesParser": addrs.RulesParser,		
	}
	const shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries, params);

	// ==== Reg Templates ====

	await rc.connect(signers[1]).setTemplate( 15, roa.address, 8);
	console.log("set template for ROA at address: ", roa.address, "\n");

	await rc.connect(signers[1]).setTemplate( 6, roaKeeper.address, 8);
	console.log("set template for ROAKeeper at address: ", roaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 9, shaKeeper.address, 8);
	console.log("set template for SHAKeeper at address: ", shaKeeper.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
