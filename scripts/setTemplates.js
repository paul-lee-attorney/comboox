// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const path = require("path");
const fs = require("fs");
const tempsDir = path.join(__dirname, "..", "server", "src", "contracts");

async function main() {

  const fileNameOfContractAddrList = path.join(tempsDir, "contracts-address.json");
	const Smart = JSON.parse(fs.readFileSync(fileNameOfContractAddrList,"utf-8"));

	const signers = await hre.ethers.getSigners();
	// console.log(
	// 	"Deploying the contracts with the account:",
	// 	await signers[0].getAddress()
	// );

	// console.log("Account balance:", (await signers[0].getBalance()).toString());

	console.log(
		"Set Templates with the account:",
		await signers[1].getAddress()
	);

	console.log("Account balance:", (await signers[1].getBalance()).toString());

	const artRC = hre.artifacts.readArtifactSync("RegCenter");
	const rc = await ethers.getContractAt(artRC.abi, Smart.RegCenter);
	console.log("Defined RegCenter Obj at: ", rc.address);

	await rc.connect(signers[1]).setTemplate( 1, Smart.ROCKeeper, 1);
	console.log("set template for ROCKeeper at address: ", Smart.ROCKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 2, Smart.RODKeeper, 1);
	console.log("set template for RODKeeper at address: ", Smart.RODKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 3, Smart.BMMKeeper, 1);
	console.log("set template for BMMKeeper at address: ", Smart.BMMKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 4, Smart.ROMKeeper, 1);
	console.log("set template for ROMKeeper at address: ", Smart.ROMKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 5, Smart.GMMKeeper, 1);
	console.log("set template for GMMKeeper at address: ", Smart.GMMKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 6, Smart.ROAKeeper, 1);
	console.log("set template for ROAKeeper at address: ", Smart.ROAKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 7, Smart.ROOKeeper, 1);
	console.log("set template for ROOKeeper at address: ", Smart.ROOKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 8, Smart.ROPKeeper, 1);
	console.log("set template for ROPKeeper at address: ", Smart.ROPKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 9, Smart.SHAKeeper, 1);
	console.log("set template for SHAKeeper at address: ", Smart.SHAKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 10, Smart.LOOKeeper, 1);
	console.log("set template for LOOKeeper at address: ", Smart.LOOKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 11, Smart.RegisterOfConstitution, 1);
	console.log("set template for RegisterOfConstitution at address: ", Smart.RegisterOfConstitution, "\n");

	await rc.connect(signers[1]).setTemplate( 12, Smart.RegisterOfDirectors, 1);
	console.log("set template for RegisterOfDirectors at address: ", Smart.RegisterOfConstitution, "\n");

	await rc.connect(signers[1]).setTemplate( 13, Smart.MeetingMinutes, 1);
	console.log("set template for MeetingMinutes at address: ", Smart.MeetingMinutes, "\n");

	await rc.connect(signers[1]).setTemplate( 14, Smart.RegisterOfMembers, 1);
	console.log("set template for RegisterOfMembers at address: ", Smart.RegisterOfMembers, "\n");

	await rc.connect(signers[1]).setTemplate( 15, Smart.RegisterOfAgreements, 1);
	console.log("set template for RegisterOfAgreements at address: ", Smart.RegisterOfAgreements, "\n");

	await rc.connect(signers[1]).setTemplate( 16, Smart.RegisterOfOptions, 1);
	console.log("set template for RegisterOfOptions at address: ", Smart.RegisterOfOptions, "\n");

	await rc.connect(signers[1]).setTemplate( 17, Smart.RegisterOfPledges, 1);
	console.log("set template for RegisterOfPledges at address: ", Smart.RegisterOfPledges, "\n");

	await rc.connect(signers[1]).setTemplate( 18, Smart.RegisterOfShares, 1);
	console.log("set template for RegisterOfShares at address: ", Smart.RegisterOfShares, "\n");

	await rc.connect(signers[1]).setTemplate( 19, Smart.ListOfOrders, 1);
	console.log("set template for ListOfOrders at address: ", Smart.ListOfOrders, "\n");

	await rc.connect(signers[1]).setTemplate( 20, Smart.GeneralKeeper, 1);
	console.log("set template for GeneralKeeper at address: ", Smart.GeneralKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 21, Smart.InvestmentAgreement, 1);
	console.log("set template for InvestmentAgreement at address: ", Smart.InvestmentAgreement, "\n");
	
	await rc.connect(signers[1]).setTemplate( 22, Smart.ShareholdersAgreement, 1);
	console.log("set template for ShareholdersAgreement at address: ", Smart.ShareholdersAgreement, "\n");

	await rc.connect(signers[1]).setTemplate( 23, Smart.AntiDilution, 1);
	console.log("set template for AntiDilution at address: ", Smart.AntiDilution, "\n");

	await rc.connect(signers[1]).setTemplate( 24, Smart.LockUp, 1);
	console.log("set template for LockUp at address: ", Smart.LockUp, "\n");

	await rc.connect(signers[1]).setTemplate( 25, Smart.Alongs, 1);
	console.log("set template for Alongs at address: ", Smart.Alongs, "\n");

	await rc.connect(signers[1]).setTemplate( 26, Smart.Options, 1);
	console.log("set template for Options at address: ", Smart.Options, "\n");

	await rc.connect(signers[1]).setFeedRegistry(Smart.MockFeedRegistry);
	console.log("set MOCK feed registry at address: ", Smart.MockFeedRegistry, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
