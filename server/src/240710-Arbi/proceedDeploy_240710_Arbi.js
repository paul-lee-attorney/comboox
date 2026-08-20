// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { readContract } = require("../../../scripts/readTool");
const { addrs } = require("./addrs_240618_Arbi");

async function main() {

	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		signers[0].address
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	let libraries = {};
	let params = [];

	// ==== Keepers ====

	libraries = {
		"DocsRepo": addrs.DocsRepo,
		"UsersRepo": addrs.UsersRepo,
		"LockersRepo": addrs.LockersRepo
	};

	params = [signers[1].address];

	let rc = await deployTool(signers[0], "RegCenter_2", libraries, params);
	console.log("deployed RC with owner: ", await rc.getOwner(), "\n");
	console.log("Bookeeper of RC: ", await rc.getBookeeper(), "\n");

	libraries = {
		"RolesRepo": addrs.RolesRepo
	}
	params = [];

	let gk = await deployTool(signers[0], "GeneralKeeper_3", libraries, params);

	libraries = {};
	params=[];

	let cnc = await deployTool(signers[0], "CreateNewComp", libraries, params);
	await cnc.init(signers[0].address, rc.address);

	libraries = {};
	params = [rc.address];
	let pc = await deployTool(signers[0], "PriceConsumer_3", libraries, params);

	params = [rc.address, 10000];
	let ft = 	await deployTool(signers[0], "FuelTank", libraries, params);

	// ==== SetTemplate ====

	await rc.connect(signers[1]).setTemplate( 1, addrs.ROCKeeper_2, 1);
	console.log("set template for ROCKeeper_2 at address: ", addrs.ROCKeeper_2, "\n");

	await rc.connect(signers[1]).setTemplate( 2, addrs.RODKeeper_2, 1);
	console.log("set template for RODKeeper_2 at address: ", addrs.RODKeeper_2, "\n");

	await rc.connect(signers[1]).setTemplate( 3, addrs.BMMKeeper_3, 1);
	console.log("set template for BMMKeeper_3 at address: ", addrs.BMMKeeper_3, "\n");

	await rc.connect(signers[1]).setTemplate( 4, addrs.ROMKeeper_3, 1);
	console.log("set template for ROMKeeper_3 at address: ", addrs.ROMKeeper_3, "\n");

	await rc.connect(signers[1]).setTemplate( 5, addrs.GMMKeeper_3, 1);
	console.log("set template for GMMKeeper_3 at address: ", addrs.GMMKeeper_3, "\n");

	await rc.connect(signers[1]).setTemplate( 6, addrs.ROAKeeper_3, 1);
	console.log("set template for ROAKeeper_3 at address: ", addrs.ROAKeeper_3, "\n");

	await rc.connect(signers[1]).setTemplate( 7, addrs.ROOKeeper_2, 1);
	console.log("set template for ROOKeeper_2 at address: ", addrs.ROOKeeper_2, "\n");

	await rc.connect(signers[1]).setTemplate( 8, addrs.ROPKeeper_2, 1);
	console.log("set template for ROPKeeper_2 at address: ", addrs.ROPKeeper_2, "\n");

	await rc.connect(signers[1]).setTemplate( 9, addrs.SHAKeeper_2, 1);
	console.log("set template for SHAKeeper_2 at address: ", addrs.SHAKeeper_2, "\n");

	await rc.connect(signers[1]).setTemplate( 10, addrs.LOOKeeper_3, 1);
	console.log("set template for LOOKeeper_3 at address: ", addrs.LOOKeeper_3, "\n");

	await rc.connect(signers[1]).setTemplate( 11, addrs.RegisterOfConstitution, 1);
	console.log("set template for ROC at address: ", addrs.RegisterOfConstitution, "\n");

	await rc.connect(signers[1]).setTemplate( 12, addrs.RegisterOfDirectors, 1);
	console.log("set template for ROD at address: ", addrs.RegisterOfDirectors, "\n");

	await rc.connect(signers[1]).setTemplate( 13, addrs.MeetingMinutes, 1);
	console.log("set template for MM at address: ", addrs.MeetingMinutes, "\n");

	await rc.connect(signers[1]).setTemplate( 14, addrs.RegisterOfMembers, 1);
	console.log("set template for ROM at address: ", addrs.RegisterOfMembers, "\n");

	await rc.connect(signers[1]).setTemplate( 15, addrs.RegisterOfAgreements, 1);
	console.log("set template for ROA at address: ", addrs.RegisterOfAgreements, "\n");

	await rc.connect(signers[1]).setTemplate( 16, addrs.RegisterOfOptions, 1);
	console.log("set template for ROO at address: ", addrs.RegisterOfOptions, "\n");

	await rc.connect(signers[1]).setTemplate( 17, addrs.RegisterOfPledges, 1);
	console.log("set template for ROP at address: ", addrs.RegisterOfPledges, "\n");

	await rc.connect(signers[1]).setTemplate( 18, addrs.RegisterOfShares, 1);
	console.log("set template for ROS at address: ", addrs.RegisterOfShares, "\n");

	await rc.connect(signers[1]).setTemplate( 19, addrs.ListOfOrders, 1);
	console.log("set template for LOO at address: ", addrs.ListOfOrders, "\n");

	await rc.connect(signers[1]).setTemplate( 20, gk.address, 1);
	console.log("set template for GK_3 at address: ", gk.address, "\n");
	
	await rc.connect(signers[1]).setTemplate( 21, addrs.InvestmentAgreement, 1);
	console.log("set template for IA at address: ", addrs.InvestmentAgreement, "\n");

	await rc.connect(signers[1]).setTemplate( 22, addrs.ShareholdersAgreement, 1);
	console.log("set template for SHA at address: ", addrs.ShareholdersAgreement, "\n");

	await rc.connect(signers[1]).setTemplate( 23, addrs.AntiDilution, 1);
	console.log("set template for AD at address: ", addrs.AntiDilution, "\n");

	await rc.connect(signers[1]).setTemplate( 24, addrs.LockUp, 1);
	console.log("set template for LU at address: ", addrs.LockUp, "\n");

	await rc.connect(signers[1]).setTemplate( 25, addrs.Alongs, 1);
	console.log("set template for AL at address: ", addrs.Alongs, "\n");

	await rc.connect(signers[1]).setTemplate( 26, addrs.Options, 1);
	console.log("set template for OP at address: ", addrs.Options, "\n");

	await rc.connect(signers[1]).setTemplate( 27, addrs.ListOfProjects, 1);
	console.log("set template for LOP at address: ", addrs.ListOfProjects, "\n");

	await rc.connect(signers[1]).setOracle(pc.address);
	console.log("set Oracle at address: ", pc.address, "\n");

};


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
