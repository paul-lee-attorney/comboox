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
		"EnumerableSet": libEnumerableSet.address
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
		"RolesRepo": libRolesRepo.address
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

	// ==== Keepers ====

	libraries = {
		"RolesRepo": libRolesRepo.address
	}
	let gk = await deployTool(signers[0], "GeneralKeeper", libraries);
	let booKeeper = await deployTool(signers[0], "BOOKeeper", libraries);
	let bosKeeper = await deployTool(signers[0], "BOSKeeper", libraries);
	let romKeeper = await deployTool(signers[0], "ROMKeeper", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"SwapsRepo": libSwapsRepo.address
	}	
	let rosKeeper = await deployTool(signers[0], "ROSKeeper", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	let bogKeeper = await deployTool(signers[0], "BOGKeeper", libraries);
	let shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries);

	libraries = {
		"DocsRepo": libDocsRepo.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	let boaKeeper = await deployTool(signers[0], "BOAKeeper", libraries);
	let bohKeeper = await deployTool(signers[0], "BOHKeeper", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address
	}
	let bodKeeper = await deployTool(signers[0], "BODKeeper", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"PledgesRepo": libPledgesRepo.address
	}
	let bopKeeper = await deployTool(signers[0], "BOPKeeper", libraries);

	// ==== Books ====

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"DTClaims": libDTClaims.address,
		"EnumerableSet": libEnumerableSet.address,
		"FRClaims": libFRClaims.address,
		"RulesParser": libRulesParser.address,
		"TopChain": libTopChain.address
	}
	let boa = await deployTool(signers[0], "BookOfIA", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"MotionsRepo": libMotionsRepo.address,
		"OfficersRepo": libOfficersRepo.address,
		"RulesParser": libRulesParser.address
	}
	let bod = await deployTool(signers[0], "BookOfDirectors", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"MotionsRepo": libMotionsRepo.address,
		"RulesParser": libRulesParser.address
	}
	let bog = await deployTool(signers[0], "BookOfGM", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"EnumerableSet": libEnumerableSet.address
	}
	let boh = await deployTool(signers[0], "BookOfSHA", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"OptionsRepo": libOptionsRepo.address
	}
	let boo = await deployTool(signers[0], "BookOfOptions", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"PledgesRepo": libPledgesRepo.address
	}
	let bop = await deployTool(signers[0], "BookOfPledges", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"LockersRepo": libLockersRepo.address,
		"SharesRepo": libSharesRepo.address
	}
	let bos = await deployTool(signers[0], "BookOfShares", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"MembersRepo": libMembersRepo.address,
		"TopChain": libTopChain.address
	}
	let rom = await deployTool(signers[0], "RegisterOfMembers", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"SwapsRepo": libSwapsRepo.address
	}
	let ros = await deployTool(signers[0], "RegisterOfSwaps", libraries);

	// ==== SetTemplate ====
	await rc.setBackupKey(signers[1].address);
	console.log("set up bookeeper: ", signers[1].address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0001"), boaKeeper.address);
	console.log("set template for BOAKeeper at address: ", boaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0002"), bodKeeper.address);
	console.log("set template for BODKeeper at address: ", bodKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0003"), bogKeeper.address);
	console.log("set template for BOGKeeper at address: ", bogKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0004"), bohKeeper.address);
	console.log("set template for BOHKeeper at address: ", bohKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0005"), booKeeper.address);
	console.log("set template for BOOKeeper at address: ", booKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0006"), bopKeeper.address);
	console.log("set template for BOPKeeper at address: ", bopKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0007"), bosKeeper.address);
	console.log("set template for BOSKeeper at address: ", bosKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0008"), romKeeper.address);
	console.log("set template for ROMKeeper at address: ", romKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0009"), rosKeeper.address);
	console.log("set template for ROSKeeper at address: ", rosKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("000a"), shaKeeper.address);
	console.log("set template for SHAKeeper at address: ", shaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("000b"), boa.address);
	console.log("set template for BOA at address: ", boa.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("000c"), bod.address);
	console.log("set template for BOD at address: ", bod.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("000d"), bog.address);
	console.log("set template for BOG at address: ", bog.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("000e"), boh.address);
	console.log("set template for BOH at address: ", boh.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("000f"), boo.address);
	console.log("set template for BOO at address: ", boo.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0010"), bop.address);
	console.log("set template for BOP at address: ", bop.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0011"), bos.address);
	console.log("set template for BOS at address: ", bos.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0012"), rom.address);
	console.log("set template for ROM at address: ", rom.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0013"), ros.address);
	console.log("set template for ROS at address: ", ros.address, "\n");
	
	await rc.connect(signers[1]).setTemplate(codifyHead("0014"), gk.address);
	console.log("set template for GK at address: ", gk.address, "\n");
	
	await rc.connect(signers[1]).setTemplate(codifyHead("0015"), ia.address);
	console.log("set template for IA at address: ", ia.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0016"), sha.address);
	console.log("set template for SHA at address: ", sha.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0017"), ad.address);
	console.log("set template for AD at address: ", ad.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0018"), da.address);
	console.log("set template for DA at address: ", da.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("0019"), lu.address);
	console.log("set template for LU at address: ", lu.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("001a"), op.address);
	console.log("set template for OP at address: ", op.address, "\n");

	await rc.connect(signers[1]).setTemplate(codifyHead("001b"), ta.address);
	console.log("set template for TA at address: ", ta.address, "\n");

	// ==== Reg Users ====

	await rc.connect(signers[2]).regUser();
	console.log("regUser: ", signers[2].address, " at No: ", parseInt( await rc.connect(signers[2]).getMyUserNo()));

	await rc.connect(signers[3]).regUser();
	console.log("regUser: ", signers[3].address, " at No: ", parseInt( await rc.connect(signers[3]).getMyUserNo()));

	await rc.connect(signers[4]).regUser();
	console.log("regUser: ", signers[4].address, " at No: ", parseInt( await rc.connect(signers[4]).getMyUserNo()));

	await rc.connect(signers[5]).regUser();
	console.log("regUser: ", signers[5].address, " at No: ", parseInt( await rc.connect(signers[5]).getMyUserNo()));
	
	await rc.connect(signers[6]).regUser();
	console.log("regUser: ", signers[6].address, " at No: ", parseInt( await rc.connect(signers[6]).getMyUserNo()));

	await rc.connect(signers[7]).regUser();
	console.log("regUser: ", signers[7].address, " at No: ", parseInt( await rc.connect(signers[7]).getMyUserNo()));

	await rc.connect(signers[8]).regUser();
	console.log("regUser: ", signers[8].address, " at No: ", parseInt( await rc.connect(signers[8]).getMyUserNo()));

	await rc.connect(signers[9]).regUser();
	console.log("regUser: ", signers[9].address, " at No: ", parseInt( await rc.connect(signers[9]).getMyUserNo()));

};

function codifyHead(typeOfDoc) {
	return hre.ethers.BigNumber.from('0x' + typeOfDoc.padEnd(64, '0'));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
