// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool, copyArtifactsOf } = require("./deployTool");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress()
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	let libraries = {};

	// ==== Libraries ====		
	let libArrayUtils = await deployTool(signers[0], "ArrayUtils", libraries);
	let libBallotsBox = await deployTool(signers[0], "BallotsBox", libraries);
	let libCheckpoints = await deployTool(signers[0], "Checkpoints", libraries);
	let libEnumerableSet = await deployTool(signers[0], "EnumerableSet", libraries);
	let libDelegateMap = await deployTool(signers[0], "DelegateMap", libraries);
	let libFRClaims = await deployTool(signers[0], "FRClaims", libraries);
	let libRolesRepo = await deployTool(signers[0], "RolesRepo", libraries);
	let libRulesParser = await deployTool(signers[0], "RulesParser", libraries);
	let libTopChain = await deployTool(signers[0], "TopChain", libraries);
		
	libraries = {
		"EnumerableSet": libEnumerableSet.address
	};
	
	let libCondsRepo = await deployTool(signers[0], "CondsRepo", libraries);
	let libDealsRepo = await deployTool(signers[0], "DealsRepo", libraries);
	let libDTClaims = await deployTool(signers[0], "DTClaims", libraries);
	let libLockersRepo = await deployTool(signers[0], "LockersRepo", libraries);
	let libPledgesRepo = await deployTool(signers[0], "PledgesRepo", libraries);
	let libSigsRepo = await deployTool(signers[0], "SigsRepo", libraries);
	let libSwapsRepo = await deployTool(signers[0], "SwapsRepo", libraries);

	libraries = {
		"BallotsBox": libBallotsBox.address
	};

	let libMotionsRepo = await deployTool(signers[0], "MotionsRepo", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address
	};

	let libSharesRepo = await deployTool(signers[0], "SharesRepo", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"Checkpoints": libCheckpoints.address,
		"CondsRepo": libCondsRepo.address
	};

	let libOptionsRepo = await deployTool(signers[0], "OptionsRepo", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"SharesRepo": libSharesRepo.address,
		"TopChain": libTopChain.address
	};

	let libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries);
	
	// ==== Deploy RegCenter ====
	libraries = {
		"LockersRepo": libLockersRepo.address
	};
	let rc = await deployTool(signers[0], "RegCenter", libraries);

	// ==== Deploy Templates ====
	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"DealsRepo": libDealsRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};

	let ia = await deployTool(signers[0], "InvestmentAgreement", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};
	let sha = await deployTool(signers[0], "ShareholdersAgreement", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
	};
	let ad = await deployTool(signers[0], "AntiDilution", libraries);
	let lu = await deployTool(signers[0], "LockUp", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address
	};
	let da = await deployTool(signers[0], "DragAlong", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address
	};
	let ta = await deployTool(signers[0], "TagAlong", libraries);
	
	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"OptionsRepo": libOptionsRepo.address
	};
	let op = await deployTool(signers[0], "Options", libraries);

	// ==== Copy Artifacts of ComBoox ====

	await copyArtifactsOf("GeneralKeeper");

	await copyArtifactsOf("BOAKeeper");
	await copyArtifactsOf("BODKeeper");
	await copyArtifactsOf("BOGKeeper");
	await copyArtifactsOf("BOHKeeper");
	await copyArtifactsOf("BOOKeeper");
	await copyArtifactsOf("BOPKeeper");
	await copyArtifactsOf("BOSKeeper");
	await copyArtifactsOf("ROMKeeper");
	await copyArtifactsOf("SHAKeeper");

	await copyArtifactsOf("BookOfIA");
	await copyArtifactsOf("BookOfDirectors");
	await copyArtifactsOf("BookOfGM");
	await copyArtifactsOf("BookOfSHA");
	await copyArtifactsOf("BookOfOptions");
	await copyArtifactsOf("BookOfPledges");
	await copyArtifactsOf("BookOfShares");
	await copyArtifactsOf("RegisterOfMembers");
	await copyArtifactsOf("RegisterOfSwaps");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
