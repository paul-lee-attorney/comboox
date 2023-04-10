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
	const libArrayUtils = await deployTool(signers[0], "ArrayUtils", libraries);
	const libBallotsBox = await deployTool(signers[0], "BallotsBox", libraries);
	const libCheckpoints = await deployTool(signers[0], "Checkpoints", libraries);
	const libDelegateMap = await deployTool(signers[0], "DelegateMap", libraries);
	const libEnumerableSet = await deployTool(signers[0], "EnumerableSet", libraries);
	const libFRClaims = await deployTool(signers[0], "FRClaims", libraries);
	const libRolesRepo = await deployTool(signers[0], "RolesRepo", libraries);
	const libRulesParser = await deployTool(signers[0], "RulesParser", libraries);
	const libTopChain = await deployTool(signers[0], "TopChain", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address
	};	
	const libCondsRepo = await deployTool(signers[0], "CondsRepo", libraries);
	const libDealsRepo = await deployTool(signers[0], "DealsRepo", libraries);
	const libDocsRepo = await deployTool(signers[0], "DocsRepo", libraries);
	const libDTClaims = await deployTool(signers[0], "DTClaims", libraries);
	const libLockersRepo = await deployTool(signers[0], "LockersRepo", libraries);
	const libOfficersRepo = await deployTool(signers[0], "OfficersRepo", libraries);
	const libPledgesRepo = await deployTool(signers[0], "PledgesRepo", libraries);
	const libSigsRepo = await deployTool(signers[0], "SigsRepo", libraries);
	const libSwapsRepo = await deployTool(signers[0], "SwapsRepo", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address
	};
	const libSharesRepo = await deployTool(signers[0], "SharesRepo", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"SharesRepo": libSharesRepo.address,
		"TopChain": libTopChain.address
	};
	const libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries);

	libraries = {
		"BallotsBox": libBallotsBox.address,
		"DelegateMap": libDelegateMap.address,
		"EnumerableSet": libEnumerableSet.address,
		"RulesParser": libRulesParser.address
	};
	const libMotionsRepo = await deployTool(signers[0], "MotionsRepo", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"Checkpoints": libCheckpoints.address,
		"CondsRepo": libCondsRepo.address
	};
	const libOptionsRepo = await deployTool(signers[0], "OptionsRepo", libraries);

	libraries = {
		"LockersRepo": libLockersRepo.address
	};
	const libUsersRepo = await deployTool(signers[0], "UsersRepo", libraries);	

	// ==== Deploy RegCenter ====
	
	libraries = {
		"DocsRepo": libDocsRepo.address,
		"UsersRepo": libUsersRepo.address
	};
	await deployTool(signers[0], "RegCenter", libraries);

	// ==== Deploy Templates ====

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"DealsRepo": libDealsRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};
	await deployTool(signers[0], "InvestmentAgreement", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};
	await deployTool(signers[0], "ShareholdersAgreement", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address
	};
	await deployTool(signers[0], "AntiDilution", libraries);
	await deployTool(signers[0], "LockUp", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address
	};
	await deployTool(signers[0], "DragAlong", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address
	};
	await deployTool(signers[0], "TagAlong", libraries);
	
	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"OptionsRepo": libOptionsRepo.address
	};
	await deployTool(signers[0], "Options", libraries);

	// ==== Keepers ====

	libraries = {
		"RolesRepo": libRolesRepo.address
	}
	await deployTool(signers[0], "GeneralKeeper", libraries);
	await deployTool(signers[0], "BOOKeeper", libraries);
	await deployTool(signers[0], "BOSKeeper", libraries);
	await deployTool(signers[0], "ROMKeeper", libraries);
	await deployTool(signers[0], "ROSKeeper", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	await deployTool(signers[0], "BOAKeeper", libraries);
	await deployTool(signers[0], "BODKeeper", libraries);
	await deployTool(signers[0], "BOGKeeper", libraries);
	await deployTool(signers[0], "BOHKeeper", libraries);
	await deployTool(signers[0], "SHAKeeper", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"PledgesRepo": libPledgesRepo.address
	}
	await deployTool(signers[0], "BOPKeeper", libraries);

	// ==== Books ====

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"DTClaims": libDTClaims.address,
		"EnumerableSet": libEnumerableSet.address,
		"FRClaims": libFRClaims.address,
		"RulesParser": libRulesParser.address,
		"TopChain": libTopChain.address
	}
	await deployTool(signers[0], "BookOfIA", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"MotionsRepo": libMotionsRepo.address,
		"OfficersRepo": libOfficersRepo.address,
		"RulesParser": libRulesParser.address
	}
	await deployTool(signers[0], "BookOfDirectors", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"MotionsRepo": libMotionsRepo.address,
		"RulesParser": libRulesParser.address
	}
	await deployTool(signers[0], "BookOfGM", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"EnumerableSet": libEnumerableSet.address
	}
	await deployTool(signers[0], "BookOfSHA", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"OptionsRepo": libOptionsRepo.address
	}
	await deployTool(signers[0], "BookOfOptions", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"PledgesRepo": libPledgesRepo.address
	}
	await deployTool(signers[0], "BookOfPledges", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"LockersRepo": libLockersRepo.address,
		"SharesRepo": libSharesRepo.address
	}
	await deployTool(signers[0], "BookOfShares", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"MembersRepo": libMembersRepo.address,
		"TopChain": libTopChain.address
	}
	await deployTool(signers[0], "RegisterOfMembers", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"SwapsRepo": libSwapsRepo.address
	}
	await deployTool(signers[0], "RegisterOfSwaps", libraries);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
