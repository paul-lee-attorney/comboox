// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { readContract } = require("../../../scripts/readTool");
const { addrs } = require("./addrs_240618_sepo");

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
		"RolesRepo": addrs.RolesRepo
	};
	params = [];
	let gk_3 = await deployTool(signers[0], "GeneralKeeper_3", libraries, params);


	let rc = await readContract("RegCenter", addrs.RegCenter);

	// ==== SetTemplate ====

	// await rc.connect(signers[1]).setTemplate( 1, rocKeeper_2.address, 1);
	// console.log("set template for ROCKeeper_2 at address: ", rocKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 2, rodKeeper_2.address, 1);
	// console.log("set template for RODKeeper_2 at address: ", rodKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 3, bmmKeeper_2.address, 1);
	// console.log("set template for BMMKeeper_2 at address: ", bmmKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 3, bmmKeeper_3.address, 1);
	// console.log("set template for BMMKeeper_3 at address: ", bmmKeeper_3.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 4, romKeeper_2.address, 1);
	// console.log("set template for ROMKeeper_2 at address: ", romKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 4, romKeeper_3.address, 1);
	// console.log("set template for ROMKeeper_3 at address: ", romKeeper_3.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 5, gmmKeeper_2.address, 1);
	// console.log("set template for GMMKeeper_2 at address: ", gmmKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 5, gmmKeeper_3.address, 1);
	// console.log("set template for GMMKeeper_3 at address: ", gmmKeeper_3.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 6, roaKeeper_2.address, 1);
	// console.log("set template for ROAKeeper_2 at address: ", roaKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 6, roaKeeper_3.address, 1);
	// console.log("set template for ROAKeeper_3 at address: ", roaKeeper_3.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 7, rooKeeper_2.address, 1);
	// console.log("set template for ROOKeeper_2 at address: ", rooKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 8, ropKeeper_2.address, 1);
	// console.log("set template for ROPKeeper_2 at address: ", ropKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 9, shaKeeper_2.address , 1);
	// console.log("set template for SHAKeeper_2 at address: ", shaKeeper_2.address , "\n");

	// await rc.connect(signers[1]).setTemplate( 10, looKeeper_2.address, 1);
	// console.log("set template for LOOKeeper_2 at address: ", looKeeper_2.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 10, looKeeper_3.address, 1);
	// console.log("set template for LOOKeeper_3 at address: ", looKeeper_3.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 11, addrs.RegisterOfConstitution, 1);
	// console.log("set template for ROC at address: ", addrs.RegisterOfConstitution, "\n");

	// await rc.connect(signers[1]).setTemplate( 12, addrs.RegisterOfDirectors, 1);
	// console.log("set template for ROD at address: ", addrs.RegisterOfDirectors, "\n");

	// await rc.connect(signers[1]).setTemplate( 13, addrs.MeetingMinutes, 1);
	// console.log("set template for MM at address: ", addrs.MeetingMinutes, "\n");

	// await rc.connect(signers[1]).setTemplate( 14, addrs.RegisterOfMembers, 1);
	// console.log("set template for ROM at address: ", addrs.RegisterOfMembers, "\n");

	// await rc.connect(signers[1]).setTemplate( 15, addrs.RegisterOfAgreements, 1);
	// console.log("set template for ROA at address: ", addrs.RegisterOfAgreements, "\n");

	// await rc.connect(signers[1]).setTemplate( 16, addrs.RegisterOfOptions, 1);
	// console.log("set template for ROO at address: ", addrs.RegisterOfOptions, "\n");

	// await rc.connect(signers[1]).setTemplate( 17, addrs.RegisterOfPledges, 1);
	// console.log("set template for ROP at address: ", addrs.RegisterOfPledges, "\n");

	// await rc.connect(signers[1]).setTemplate( 18, ros.address, 1);
	// console.log("set template for ROS at address: ", ros.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 19, addrs.ListOfOrders, 1);
	// console.log("set template for LOO at address: ", addrs.ListOfOrders, "\n");

	await rc.connect(signers[1]).setTemplate( 20, gk_3.address, 8);
	console.log("set template for GK_3 at address: ", gk_3.address, "\n");
	
	// await rc.connect(signers[1]).setTemplate( 21, addrs.InvestmentAgreement, 1);
	// console.log("set template for IA at address: ", addrs.InvestmentAgreement, "\n");

	// await rc.connect(signers[1]).setTemplate( 22, addrs.ShareholdersAgreement, 1);
	// console.log("set template for SHA at address: ", addrs.ShareholdersAgreement, "\n");

	// await rc.connect(signers[1]).setTemplate( 23, addrs.AntiDilution, 1);
	// console.log("set template for AD at address: ", addrs.AntiDilution, "\n");

	// await rc.connect(signers[1]).setTemplate( 24, lu.address, 1);
	// console.log("set template for LU at address: ", lu.address, "\n");

	// await rc.connect(signers[1]).setTemplate( 25, addrs.Alongs, 1);
	// console.log("set template for AL at address: ", addrs.Alongs, "\n");

	// await rc.connect(signers[1]).setTemplate( 26, addrs.Options, 1);
	// console.log("set template for OP at address: ", addrs.Options, "\n");

	// await rc.connect(signers[1]).setTemplate( 27, addrs.ListOfProjects, 1);
	// console.log("set template for LOP at address: ", addrs.ListOfProjects, "\n");

	// await rc.connect(signers[1]).setPriceFeed(0, addrs.MockFeedRegistry);
	// console.log("set MOCK price feed at address: ", addrs.MockFeedRegistry, "\n");

};


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
