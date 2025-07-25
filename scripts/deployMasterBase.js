// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("./deployTool");

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
	const libArrayUtils = await deployTool(signers[0], "ArrayUtils", libraries, params);
	const libBallotsBox = await deployTool(signers[0], "BallotsBox", libraries, params);
	const libCheckpoints = await deployTool(signers[0], "Checkpoints", libraries, params);
	const libDelegateMap = await deployTool(signers[0], "DelegateMap", libraries, params);
	const libDocsRepo = await deployTool(signers[0], "DocsRepo", libraries, params);
	const libEnumerableSet = await deployTool(signers[0], "EnumerableSet", libraries, params);
	const libFRClaims = await deployTool(signers[0], "FRClaims", libraries, params);
	const libGoldChain = await deployTool(signers[0], "GoldChain", libraries, params);
	const libRolesRepo = await deployTool(signers[0], "RolesRepo", libraries, params);
	const libRulesParser = await deployTool(signers[0], "RulesParser", libraries, params);
	const libSwapsRepo = await deployTool(signers[0], "SwapsRepo", libraries, params);
	const libTopChain = await deployTool(signers[0], "TopChain", libraries, params);
	const libAddress = await deployTool(signers[0], "Address", libraries, params);
	const libInvestorsRepo = await deployTool(signers[0], "InvestorsRepo", libraries, params);

	libraries = {
		"GoldChain": libGoldChain.address,
	};
	const libOrdersRepo = await deployTool(signers[0], "OrdersRepo", libraries, params);
	const libUsdOrdersRepo = await deployTool(signers[0], "UsdOrdersRepo", libraries, params);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
	};	
	const libCondsRepo = await deployTool(signers[0], "CondsRepo", libraries, params);
	const libDTClaims = await deployTool(signers[0], "DTClaims", libraries, params);
	const libFilesRepo = await deployTool(signers[0], "FilesRepo", libraries, params);
	const libLockersRepo = await deployTool(signers[0], "LockersRepo", libraries, params);
	const libOfficersRepo = await deployTool(signers[0], "OfficersRepo", libraries, params);
	const libPledgesRepo = await deployTool(signers[0], "PledgesRepo", libraries, params);
	const libSigsRepo = await deployTool(signers[0], "SigsRepo", libraries, params);
	const libSharesRepo = await deployTool(signers[0], "SharesRepo", libraries, params);
	const libTeamsRepo = await deployTool(signers[0], "TeamsRepo", libraries, params);
	const libUsdLockersRepo = await deployTool(signers[0], "UsdLockersRepo", libraries, params);

	libraries = {
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"TopChain": libTopChain.address
	};
	const libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries, params);

	libraries = {
		"BallotsBox": libBallotsBox.address,
		"DelegateMap": libDelegateMap.address,
		"EnumerableSet": libEnumerableSet.address,
		"RulesParser": libRulesParser.address
	};
	const libMotionsRepo = await deployTool(signers[0], "MotionsRepo", libraries, params);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"SwapsRepo": libSwapsRepo.address,
	};	
	const libDealsRepo = await deployTool(signers[0], "DealsRepo", libraries, params);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"Checkpoints": libCheckpoints.address,
		"CondsRepo": libCondsRepo.address,
		"SwapsRepo": libSwapsRepo.address,
	};
	const libOptionsRepo = await deployTool(signers[0], "OptionsRepo", libraries, params);

	libraries = {
		"LockersRepo": libLockersRepo.address
	};
	const libUsersRepo = await deployTool(signers[0], "UsersRepo", libraries, params);	

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RulesParser": libRulesParser.address
	};
	const libLinksRepo = await deployTool(signers[0], "LinksRepo", libraries, params);

	// ==== Deploy RegCenter ====
	
	libraries = {
		"DocsRepo": libDocsRepo.address,
		"UsersRepo": libUsersRepo.address,
		"LockersRepo": libLockersRepo.address
	};

	params = [signers[1].address];

	let rc = await deployTool(signers[0], "RegCenter", libraries, params);
	console.log("deployed RC with owner: ", await rc.getOwner(), "\n");
	console.log("Bookeeper of RC: ", await rc.getBookeeper(), "\n");

	libraries = {};
	params=[];

	let usdc = await deployTool(signers[0], "MockUSDC", libraries, params);
	await usdc.init(signers[0].address, rc.address);
	console.log("deployed USDC with owner: ", await usdc.getOwner(), "\n");

	params=[usdc.address];
	let cnc = await deployTool(signers[0], "CreateNewComp", libraries, params);
	await cnc.init(signers[0].address, rc.address);

	// ==== Deploy Templates ====

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"DealsRepo": libDealsRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address,
		"SwapsRepo": libSwapsRepo.address
	};
	params=[];
	let ia = await deployTool(signers[0], "InvestmentAgreement", libraries, params);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};
	let sha = await deployTool(signers[0], "ShareholdersAgreement", libraries, params);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address
	};
	let ad = await deployTool(signers[0], "AntiDilution", libraries, params);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address
	};
	let lu = await deployTool(signers[0], "LockUp", libraries, params);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"LinksRepo": libLinksRepo.address
	};
	let al = await deployTool(signers[0], "Alongs", libraries, params);
	
	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"OptionsRepo": libOptionsRepo.address
	};
	let op = await deployTool(signers[0], "Options", libraries, params);

	// ==== Keepers ====

	libraries = {
		// "RolesRepo": libRolesRepo.address,
		"Address": libAddress.address
	}

	let gk = await deployTool(signers[0], "GeneralKeeper", libraries, params);

	libraries = {}

	let rooKeeper = await deployTool(signers[0], "ROOKeeper", libraries, params);
	let romKeeper = await deployTool(signers[0], "ROMKeeper", libraries, params);
	let rodKeeper = await deployTool(signers[0], "RODKeeper", libraries, params);
	let usdKeeper = await deployTool(signers[0], "USDKeeper", libraries, params);
	let usdRomKeeper = await deployTool(signers[0], "UsdROMKeeper", libraries, params);
	let usdRooKeeper = await deployTool(signers[0], "UsdROOKeeper", libraries, params);
	let usdRoaKeeper = await deployTool(signers[0], "UsdROAKeeper", libraries, params);

	libraries = {
		"RulesParser": libRulesParser.address		
	}
	let shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries, params);
	let looKeeper = await deployTool(signers[0], "LOOKeeper", libraries, params);
	let usdLooKeeper = await deployTool(signers[0], "UsdLOOKeeper", libraries, params);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"RulesParser": libRulesParser.address		
	}
	let gmmKeeper = await deployTool(signers[0], "GMMKeeper", libraries, params);
	let bmmKeeper = await deployTool(signers[0], "BMMKeeper", libraries, params);

	libraries = {
		"DocsRepo": libDocsRepo.address,
		"RulesParser": libRulesParser.address		
	}
	let roaKeeper = await deployTool(signers[0], "ROAKeeper", libraries, params);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"DocsRepo": libDocsRepo.address,
		"RulesParser": libRulesParser.address		
	}
	let rocKeeper = await deployTool(signers[0], "ROCKeeper", libraries, params);

	libraries = {
		"PledgesRepo": libPledgesRepo.address,
	}
	let ropKeeper = await deployTool(signers[0], "ROPKeeper", libraries, params);

	// ==== Books ====

	libraries = {
		"DTClaims": libDTClaims.address,
		"FilesRepo": libFilesRepo.address,
		"FRClaims": libFRClaims.address,
		"TopChain": libTopChain.address
	}
	let roa = await deployTool(signers[0], "RegisterOfAgreements", libraries, params);

	libraries = {
		"OfficersRepo": libOfficersRepo.address
	}
	let rod = await deployTool(signers[0], "RegisterOfDirectors", libraries, params);

	libraries = {
		"MotionsRepo": libMotionsRepo.address
	}
	let mm = await deployTool(signers[0], "MeetingMinutes", libraries, params);

	libraries = {
		"FilesRepo": libFilesRepo.address
	}
	let roc = await deployTool(signers[0], "RegisterOfConstitution", libraries, params);

	libraries = {
		"OptionsRepo": libOptionsRepo.address,
		"SwapsRepo": libSwapsRepo.address
	}
	let roo = await deployTool(signers[0], "RegisterOfOptions", libraries, params);

	libraries = {
		"PledgesRepo": libPledgesRepo.address
	}
	let rop = await deployTool(signers[0], "RegisterOfPledges", libraries, params);

	libraries = {
		"LockersRepo": libLockersRepo.address,
		"SharesRepo": libSharesRepo.address
	}
	let ros = await deployTool(signers[0], "RegisterOfShares", libraries, params);

	libraries = {
		"Checkpoints": libCheckpoints.address,
		"MembersRepo": libMembersRepo.address,
		"TopChain": libTopChain.address
	}
	let rom = await deployTool(signers[0], "RegisterOfMembers", libraries, params);

	libraries = {
		"OrdersRepo": libOrdersRepo.address,
		"GoldChain": libGoldChain.address,
		"EnumerableSet": libEnumerableSet.address,
		"InvestorsRepo": libInvestorsRepo.address,
	}
	let loo = await deployTool(signers[0], "ListOfOrders", libraries, params);

	libraries = {
		"UsdOrdersRepo": libUsdOrdersRepo.address,
		"GoldChain": libGoldChain.address,
		"EnumerableSet": libEnumerableSet.address
	}
	let usdLoo = await deployTool(signers[0], "UsdListOfOrders", libraries, params);

	libraries = {
		"TeamsRepo": libTeamsRepo.address,
	};
	let lop = await deployTool(signers[0], "ListOfProjects", libraries, params);

	libraries = {}
	let cashier = await deployTool(signers[0], "Cashier", libraries, params);

	libraries = {
		"UsdLockersRepo": libUsdLockersRepo.address
	}
	params = [usdc.address];
	let cashLockers = await deployTool(signers[0], "CashLockers", libraries, params);

	libraries = {};
	params = [rc.address];
	let pc = await deployTool(signers[0], "PriceConsumer", libraries, params);

	params = [];
	let mockFeedRegistry = 	await deployTool(signers[0], "MockFeedRegistry", libraries, params);

	// params = [rc.address, 10000];
	// let ft = await deployTool(signers[0], "FuelTank", libraries, params);

	params = [rc.address, 2600 * 10 ** 6];
	let ft = await deployTool(signers[0], "UsdFuelTank", libraries, params);

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

	await rc.connect(signers[1]).setTemplate( 28, cashier.address, 1);
	console.log("set template for Cashier at address: ", cashier.address, "\n");

	await rc.connect(signers[1]).setTemplate( 29, usdLoo.address, 1);
	console.log("set template for UsdLOO at address: ", usdLoo.address, "\n");

	await rc.connect(signers[1]).setTemplate( 30, usdKeeper.address, 1);
	console.log("set template for USDKeeper at address: ", usdKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 31, usdRomKeeper.address, 1);
	console.log("set template for UsdROMKeeper at address: ", usdRomKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 32, usdRoaKeeper.address, 1);
	console.log("set template for UsdROAKeeper at address: ", usdRoaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 33, usdLooKeeper.address, 1);
	console.log("set template for UsdLOOKeeper at address: ", usdLooKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 34, usdRooKeeper.address, 1);
	console.log("set template for UsdROOKeeper at address: ", usdRooKeeper.address, "\n");

	await rc.connect(signers[1]).setOracle(pc.address);
	console.log("set Oracle at address: ", pc.address, "\n");

	await rc.connect(signers[1]).setPriceFeed(0, mockFeedRegistry.address);
	console.log("set MOCK price feed at address: ", mockFeedRegistry.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
