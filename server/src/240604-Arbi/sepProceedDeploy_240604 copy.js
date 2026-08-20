// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("./deployTool");
const addrOfRC = '0xb91C1e3fD4e3C481c135dD414c106a25fD99f517';

async function main() {

	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		signers[0].address
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	let libraries = {};
	let params = [];

	params = [addrOfRC, 10000];
	await deployTool(signers[0], "FuelTank", libraries, params);

};


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
