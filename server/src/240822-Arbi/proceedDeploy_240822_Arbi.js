// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

/*
	2024-08-22
	revised ETH transfer functions in smart contracts of GK, FT and LOP.  
	And, add a new lib of Address, to introduce the Address concerned funcs
	into the platform. 
*/

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_240815_Arbi");
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
	const libAddress = await deployTool(signers[0], "Address", libraries, params);

	let rc_2 = await readContract("RegCenter_2", addrs.RegCenter_2);
	console.log("get RegCenter_2 at:", rc_2.address);

	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"Address": libAddress.address
	}

	let gk_4 = await deployTool(signers[0], "GeneralKeeper_4", libraries, params);

	libraries = {
		"TeamsRepo": addrs.TeamsRepo,
	};
	let lop_2 = await deployTool(signers[0], "ListOfProjects_2", libraries, params);

	libraries = {};
	params = [rc_2.address, 10000];
	let ft_2 = 	await deployTool(signers[0], "FuelTank_2", libraries, params);

	// ==== SetTemplate ====

	await rc_2.connect(signers[1]).setTemplate( 20, gk_4.address, 1);
	console.log("set template for GK_4 at address: ", gk_4.address, "\n");
	
	await rc_2.connect(signers[1]).setTemplate( 27, lop_2.address, 1);
	console.log("set template for LOP_2 at address: ", lop_2.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
