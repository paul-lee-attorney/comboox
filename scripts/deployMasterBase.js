// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool, saveTempAddr } = require("./deployTool");

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
	const libDocsRepo = await deployTool(signers[0], "DocsRepo", libraries);
	const libEnumerableSet = await deployTool(signers[0], "EnumerableSet", libraries);
	const libFRClaims = await deployTool(signers[0], "FRClaims", libraries);
	const libGoldChain = await deployTool(signers[0], "GoldChain", libraries);
	const libRolesRepo = await deployTool(signers[0], "RolesRepo", libraries);
	const libRulesParser = await deployTool(signers[0], "RulesParser", libraries);
	const libSwapsRepo = await deployTool(signers[0], "SwapsRepo", libraries);
	const libTopChain = await deployTool(signers[0], "TopChain", libraries);

	libraries = {
		"GoldChain": libGoldChain.address,
		"EnumerableSet": libEnumerableSet.address,
	};
	const libOrdersRepo = await deployTool(signers[0], "OrdersRepo", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
	};	
	const libCondsRepo = await deployTool(signers[0], "CondsRepo", libraries);
	const libDTClaims = await deployTool(signers[0], "DTClaims", libraries);
	const libFilesRepo = await deployTool(signers[0], "FilesRepo", libraries);
	const libLockersRepo = await deployTool(signers[0], "LockersRepo", libraries);
	const libOfficersRepo = await deployTool(signers[0], "OfficersRepo", libraries);
	const libPledgesRepo = await deployTool(signers[0], "PledgesRepo", libraries);
	const libSigsRepo = await deployTool(signers[0], "SigsRepo", libraries);
	const libSharesRepo = await deployTool(signers[0], "SharesRepo", libraries);
	const libTeamsRepo = await deployTool(signers[0], "TeamsRepo", libraries);

	libraries = {
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
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
		"SwapsRepo": libSwapsRepo.address,
	};	
	const libDealsRepo = await deployTool(signers[0], "DealsRepo", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"Checkpoints": libCheckpoints.address,
		"CondsRepo": libCondsRepo.address,
		"SwapsRepo": libSwapsRepo.address,
	};
	const libOptionsRepo = await deployTool(signers[0], "OptionsRepo", libraries);

	libraries = {
		"LockersRepo": libLockersRepo.address
	};
	const libUsersRepo = await deployTool(signers[0], "UsersRepo", libraries);	

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RulesParser": libRulesParser.address
	};
	const libLinksRepo = await deployTool(signers[0], "LinksRepo", libraries);

	// ==== Deploy RegCenter ====
	
	libraries = {
		"DocsRepo": libDocsRepo.address,
		"UsersRepo": libUsersRepo.address,
		"LockersRepo": libLockersRepo.address
	};
	let rc = await deployTool(signers[0], "RegCenter", libraries);
	let res = await rc.getOwner();
	console.log("deployed RC with owner: ", res, "\n");
	console.log("creator of RC: ", signers[0].address, "\n");

	await rc.setBackupKey(signers[1].address);
	res = await rc.getBookeeper();
	console.log("setup bookeeper of RC: ", res, "\n");

	libraries = {};
	let cnc = await deployTool(signers[0], "CreateNewComp", libraries);

	await cnc.init(signers[0].address, rc.address);
	res = await cnc.getOwner();
	console.log("init CNC with owner: ", res, "\n");
	res = await cnc.getRegCenter();
	console.log(" set CNC with RC: ", res , "\n");

	// ==== Deploy Templates ====

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"DealsRepo": libDealsRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address,
		"SwapsRepo": libSwapsRepo.address
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
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address
	};
	let ad = await deployTool(signers[0], "AntiDilution", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address
	};
	let lu = await deployTool(signers[0], "LockUp", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"LinksRepo": libLinksRepo.address
	};
	let al = await deployTool(signers[0], "Alongs", libraries);
	
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
	let rooKeeper = await deployTool(signers[0], "ROOKeeper", libraries);
	let romKeeper = await deployTool(signers[0], "ROMKeeper", libraries);
	let rodKeeper = await deployTool(signers[0], "RODKeeper", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	let shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries);
	let gmmKeeper = await deployTool(signers[0], "GMMKeeper", libraries);
	let bmmKeeper = await deployTool(signers[0], "BMMKeeper", libraries);
	let looKeeper = await deployTool(signers[0], "LOOKeeper", libraries);

	libraries = {
		"DocsRepo": libDocsRepo.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	let roaKeeper = await deployTool(signers[0], "ROAKeeper", libraries);

	libraries = {
		"DocsRepo": libDocsRepo.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	let rocKeeper = await deployTool(signers[0], "ROCKeeper", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"PledgesRepo": libPledgesRepo.address,
		"DealsRepo": libDealsRepo.address,
		"DocsRepo": libDocsRepo.address,
		"RulesParser": libRulesParser.address
	}
	let ropKeeper = await deployTool(signers[0], "ROPKeeper", libraries);

	// ==== Books ====

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"DTClaims": libDTClaims.address,
		"FilesRepo": libFilesRepo.address,
		"FRClaims": libFRClaims.address,
		"TopChain": libTopChain.address
	}
	let roa = await deployTool(signers[0], "RegisterOfAgreements", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"OfficersRepo": libOfficersRepo.address
	}
	let rod = await deployTool(signers[0], "RegisterOfDirectors", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"MotionsRepo": libMotionsRepo.address
	}
	let mm = await deployTool(signers[0], "MeetingMinutes", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"FilesRepo": libFilesRepo.address
	}
	let roc = await deployTool(signers[0], "RegisterOfConstitution", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"OptionsRepo": libOptionsRepo.address,
		"SwapsRepo": libSwapsRepo.address
	}
	let roo = await deployTool(signers[0], "RegisterOfOptions", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"PledgesRepo": libPledgesRepo.address
	}
	let rop = await deployTool(signers[0], "RegisterOfPledges", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"LockersRepo": libLockersRepo.address,
		"SharesRepo": libSharesRepo.address
	}
	let ros = await deployTool(signers[0], "RegisterOfShares", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"MembersRepo": libMembersRepo.address,
		"TopChain": libTopChain.address
	}
	let rom = await deployTool(signers[0], "RegisterOfMembers", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"OrdersRepo": libOrdersRepo.address,
		"GoldChain": libGoldChain.address,
	}
	let loo = await deployTool(signers[0], "ListOfOrders", libraries);

	libraries = {
		"TeamsRepo": libTeamsRepo.address,
	};
	let lop = await deployTool(signers[0], "ListOfProjects", libraries);

	libraries = {};

	// let mockFeedRegistry = 	await deployTool(signers[0], "MockFeedRegistry", libraries);

	// ==== SetTemplate ====

	await rc.connect(signers[1]).setTemplate( 1, rocKeeper.address, 1);
	console.log("set template for ROCKeeper at address: ", rocKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 2, rodKeeper.address, 1);
	console.log("set template for RODKeeper at address: ", rodKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 3, bmmKeeper.address, 1);
	console.log("set template for BMMKeeper at address: ", bmmKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 4, romKeeper.address, 1);
	console.log("set template for ROMKeeper at address: ", romKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 5, gmmKeeper.address, 1);
	console.log("set template for GMMKeeper at address: ", gmmKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 6, roaKeeper.address, 1);
	console.log("set template for ROAKeeper at address: ", roaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 7, rooKeeper.address, 1);
	console.log("set template for ROOKeeper at address: ", rooKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 8, ropKeeper.address, 1);
	console.log("set template for ROPKeeper at address: ", ropKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 9, shaKeeper.address, 1);
	console.log("set template for SHAKeeper at address: ", shaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 10, looKeeper.address, 1);
	console.log("set template for LOOKeeper at address: ", looKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 11, roc.address, 1);
	console.log("set template for ROC at address: ", roc.address, "\n");

	await rc.connect(signers[1]).setTemplate( 12, rod.address, 1);
	console.log("set template for ROD at address: ", rod.address, "\n");

	await rc.connect(signers[1]).setTemplate( 13, mm.address, 1);
	console.log("set template for MM at address: ", mm.address, "\n");

	await rc.connect(signers[1]).setTemplate( 14, rom.address, 1);
	console.log("set template for ROM at address: ", rom.address, "\n");

	await rc.connect(signers[1]).setTemplate( 15, roa.address, 1);
	console.log("set template for ROA at address: ", roa.address, "\n");

	await rc.connect(signers[1]).setTemplate( 16, roo.address, 1);
	console.log("set template for ROO at address: ", roo.address, "\n");

	await rc.connect(signers[1]).setTemplate( 17, rop.address, 1);
	console.log("set template for ROP at address: ", rop.address, "\n");

	await rc.connect(signers[1]).setTemplate( 18, ros.address, 1);
	console.log("set template for ROS at address: ", ros.address, "\n");

	await rc.connect(signers[1]).setTemplate( 19, loo.address, 1);
	console.log("set template for LOO at address: ", loo.address, "\n");

	await rc.connect(signers[1]).setTemplate( 20, gk.address, 1);
	console.log("set template for GK at address: ", gk.address, "\n");
	
	await rc.connect(signers[1]).setTemplate( 21, ia.address, 1);
	console.log("set template for IA at address: ", ia.address, "\n");

	await rc.connect(signers[1]).setTemplate( 22, sha.address, 1);
	console.log("set template for SHA at address: ", sha.address, "\n");

	await rc.connect(signers[1]).setTemplate( 23, ad.address, 1);
	console.log("set template for AD at address: ", ad.address, "\n");

	await rc.connect(signers[1]).setTemplate( 24, lu.address, 1);
	console.log("set template for LU at address: ", lu.address, "\n");

	await rc.connect(signers[1]).setTemplate( 25, al.address, 1);
	console.log("set template for AL at address: ", al.address, "\n");

	await rc.connect(signers[1]).setTemplate( 26, op.address, 1);
	console.log("set template for OP at address: ", op.address, "\n");

	await rc.connect(signers[1]).setTemplate( 27, lop.address, 1);
	console.log("set template for LOP at address: ", lop.address, "\n");

	// await rc.connect(signers[1]).setPriceFeed(0, mockFeedRegistry.address);
	// console.log("set MOCK price feed at address: ", mockFeedRegistry.address, "\n");

	let options = {
		signer: signers[0],
		libraries: libraries,
	};

	let FuleTank = await hre.ethers.getContractFactory("FuleTank", options);
	let ft = await FuleTank.deploy(rc.address, 10000);
	await ft.deployed();

	saveTempAddr("FuleTank", ft);

	// ==== Reg Users ====

	// await rc.connect(signers[2]).regUser("0x0".padEnd(66, "0"));
	// console.log("regUser: ", signers[2].address, " with No: ", parseInt( await rc.connect(signers[2]).getMyUserNo()));

	// await rc.connect(signers[3]).regUser("0x0".padEnd(66, "0"));
	// console.log("regUser: ", signers[3].address, " with No: ", parseInt( await rc.connect(signers[3]).getMyUserNo()));

	// await rc.connect(signers[4]).regUser("0x0".padEnd(66, "0"));
	// console.log("regUser: ", signers[4].address, " with No: ", parseInt( await rc.connect(signers[4]).getMyUserNo()));

	// await rc.connect(signers[5]).regUser("0x0".padEnd(66, "0"));
	// console.log("regUser: ", signers[5].address, " with No: ", parseInt( await rc.connect(signers[5]).getMyUserNo()));
	
	// await rc.connect(signers[6]).regUser("0x0".padEnd(66, "0"));
	// console.log("regUser: ", signers[6].address, " with No: ", parseInt( await rc.connect(signers[6]).getMyUserNo()));

	// await rc.connect(signers[7]).regUser("0x0".padEnd(66, "0"));
	// console.log("regUser: ", signers[7].address, " with No: ", parseInt( await rc.connect(signers[7]).getMyUserNo()));

	// await rc.connect(signers[8]).regUser("0x0".padEnd(66, "0"));
	// console.log("regUser: ", signers[8].address, " with No: ", parseInt( await rc.connect(signers[8]).getMyUserNo()));

	// await rc.connect(signers[9]).regUser("0x0".padEnd(66, "0"));
	// console.log("regUser: ", signers[9].address, " with No: ", parseInt( await rc.connect(signers[9]).getMyUserNo()));

};

// function codifyHead(typeOfDoc) {

// 	let sn = '0x' + typeOfDoc.padStart(8, '0').padEnd(64, '0');
// 	console.log("snOfDoc: ", sn);
// 	return sn;
// }

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
