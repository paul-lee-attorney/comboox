// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { readContract } = require("../../../scripts/readTool");
const { addrs } = require("./addrs_240426_arbi");
// const { sites } = require("./sites_240517_arbi");

async function main() {

	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		signers[0].address
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	let libraries = {};
	let params = [];

	// ==== Libraries ====
	
	libraries = {
		"LockersRepo": addrs.LockersRepo
	};
	let libUsersRepo = await deployTool(signers[0], "UsersRepo", libraries, params);	

	// let libUsersRepo = await readContract("UsersRepo", "0xFFf807D4760078BEB7BFE9320924dD594D244849");


	// ==== Deploy RegCenter ====
	
	libraries = {
		"DocsRepo": addrs.DocsRepo,
		"UsersRepo": libUsersRepo.address,
		"LockersRepo": addrs.LockersRepo
	};

	params = [signers[1].address];

	let rc = await deployTool(signers[0], "RegCenter", libraries, params);

	console.log("deployed RC with owner: ", await rc.getOwner(), "\n");
	console.log("Bookeeper of RC: ", await rc.getBookeeper(), "\n");

	await rc.regUser();
	await rc.connect(signers[1]).regUser();

	console.log("Registered User No.1 on RC: ", await rc.getMyUserNo(), "\n");
	console.log("Registered User No.2 on RC: ", await rc.connect(signers[1]).getMyUserNo(), "\n");

	// let rc = await readContract("RegCenter", sites.RegCenter);

	libraries = {};
	params=[];

	let cnc = await deployTool(signers[0], "CreateNewComp", libraries, params);
	await cnc.init(signers[0].address, rc.address);

	// let cnc = await readContract("CreateNewComp", "0x98aA44921763f91218a68389b8192Badec367462");

	// ==== Deploy Templates ====

	libraries = {
		"ArrayUtils": addrs.ArrayUtils,
		"EnumerableSet": addrs.EnumerableSet,
		"RolesRepo": addrs.RolesRepo
	};
	params = [];
	let lu = await deployTool(signers[0], "LockUp", libraries, params);

	// let lu = await readContract("LockUp", "0xa0De7C3D136804BAab6C2b889d8E2c289717f6Fc");

	// ==== Keepers ====

	libraries = {
		"RolesRepo": addrs.RolesRepo
	};
	params = [];
	let rooKeeper = await deployTool(signers[0], "ROOKeeper", libraries, params);
	
	// let rooKeeper = await readContract("LOOKeeper", "0x317962F047F60705AEBC9437E68B4D21E5A9Ac68");

	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"RulesParser": addrs.RulesParser
	};
	params = [];
	let shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries, params);
	let gmmKeeper = await deployTool(signers[0], "GMMKeeper", libraries, params);
	let bmmKeeper = await deployTool(signers[0], "BMMKeeper", libraries, params);
	let looKeeper = await deployTool(signers[0], "LOOKeeper", libraries, params);

	// let shaKeeper = await readContract("SHAKeeper", "0x9422b3EFEf6ada7C7b3fd28F0FD69adc0Cb03D35");
	// let gmmKeeper = await readContract("GMMKeeper", "0xA837c747d45F3A431c54144787E6243B516d31ec");
	// let bmmKeeper = await readContract("BMMKeeper", "0xA2B5F7eC6bA64Bb9Aee0E61f392D77E60b677Bbc");
	// let looKeeper = await readContract("LOOKeeper", "0x9ACbE2cb3Fcb84408143f38961d441948F64D06e");


	libraries = {
		"DocsRepo": addrs.DocsRepo,
		"RolesRepo": addrs.RolesRepo,
		"RulesParser": addrs.RulesParser		
	}
	let roaKeeper = await deployTool(signers[0], "ROAKeeper", libraries, params);

	// let roaKeeper = await readContract("ROAKeeper", "0xeEB8e3ddFd3b0aB58EBd90c10Eda78114884ECA9");


	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"PledgesRepo": addrs.PledgesRepo,
	}
	let ropKeeper = await deployTool(signers[0], "ROPKeeper", libraries, params);

	// ==== Books ====

	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"LockersRepo": addrs.LockersRepo,
		"SharesRepo": addrs.SharesRepo
	}
	let ros = await deployTool(signers[0], "RegisterOfShares", libraries, params);

	libraries = {};
	params = [rc.address, 10000];
	let ft = 	await deployTool(signers[0], "FuleTank", libraries, params);

	// ==== SetTemplate ====

	await rc.connect(signers[1]).setTemplate( 1, addrs.ROCKeeper, 1);
	console.log("set template for ROCKeeper at address: ", addrs.ROCKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 2, addrs.RODKeeper, 1);
	console.log("set template for RODKeeper at address: ", addrs.RODKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 3, bmmKeeper.address, 1);
	console.log("set template for BMMKeeper at address: ", bmmKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 4, addrs.ROMKeeper, 1);
	console.log("set template for ROMKeeper at address: ", addrs.ROMKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 5, gmmKeeper.address, 1);
	console.log("set template for GMMKeeper at address: ", gmmKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 6, roaKeeper.address, 1);
	console.log("set template for ROAKeeper at address: ", roaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 7, rooKeeper.address, 1);
	console.log("set template for ROOKeeper at address: ", rooKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 8, ropKeeper.address, 1);
	console.log("set template for ROPKeeper at address: ", ropKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 9, shaKeeper.address , 1);
	console.log("set template for SHAKeeper at address: ", shaKeeper.address , "\n");

	await rc.connect(signers[1]).setTemplate( 10, looKeeper.address, 1);
	console.log("set template for LOOKeeper at address: ", looKeeper.address, "\n");

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

	await rc.connect(signers[1]).setTemplate( 18, ros.address, 1);
	console.log("set template for ROS at address: ", ros.address, "\n");

	await rc.connect(signers[1]).setTemplate( 19, addrs.ListOfOrders, 1);
	console.log("set template for LOO at address: ", addrs.ListOfOrders, "\n");

	await rc.connect(signers[1]).setTemplate( 20, addrs.GeneralKeeper, 1);
	console.log("set template for GK at address: ", addrs.GeneralKeeper, "\n");
	
	await rc.connect(signers[1]).setTemplate( 21, addrs.InvestmentAgreement, 1);
	console.log("set template for IA at address: ", addrs.InvestmentAgreement, "\n");

	await rc.connect(signers[1]).setTemplate( 22, addrs.ShareholdersAgreement, 1);
	console.log("set template for SHA at address: ", addrs.ShareholdersAgreement, "\n");

	await rc.connect(signers[1]).setTemplate( 23, addrs.AntiDilution, 1);
	console.log("set template for AD at address: ", addrs.AntiDilution, "\n");

	await rc.connect(signers[1]).setTemplate( 24, lu.address, 1);
	console.log("set template for LU at address: ", lu.address, "\n");

	await rc.connect(signers[1]).setTemplate( 25, addrs.Alongs, 1);
	console.log("set template for AL at address: ", addrs.Alongs, "\n");

	await rc.connect(signers[1]).setTemplate( 26, addrs.Options, 1);
	console.log("set template for OP at address: ", addrs.Options, "\n");

	await rc.connect(signers[1]).setTemplate( 27, addrs.ListOfProjects, 1);
	console.log("set template for LOP at address: ", addrs.ListOfProjects, "\n");

	// await rc.connect(signers[1]).setPriceFeed(0, addrs.MockFeedRegistry);
	// console.log("set MOCK price feed at address: ", addrs.MockFeedRegistry, "\n");

};


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
