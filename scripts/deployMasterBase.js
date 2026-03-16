// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import {network} from "hardhat";
import { deployTool } from "./deployTool";
import { readTool } from "./readTool";
import Types from "./TypesList.json";

async function main() {

	const { ethers } = await network.connect();

	const signers = await ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress()
	);

	console.log("Account balance:", (await ethers.provider.getBalance(signers[0])).toString());

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
	const libWaterfallsRepo = await deployTool(signers[0], "WaterfallsRepo", libraries, params);
	const libInterfacesHub = await deployTool(signers[0], "InterfacesHub", libraries, params);
	const libTypesList = await deployTool(signers[0], "TypesList", libraries, params);

	libraries = {
		"Address": libAddress,
	};
	const libKeepersRouter = await deployTool(signers[0], "KeepersRouter", libraries, params);

	libraries = {
		"GoldChain": libGoldChain,
	};
	const libOrdersRepo = await deployTool(signers[0], "OrdersRepo", libraries, params);
	const libUsdOrdersRepo = await deployTool(signers[0], "UsdOrdersRepo", libraries, params);

	libraries = {
		"EnumerableSet": libEnumerableSet,
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
	const libRedemptionsRepo = await deployTool(signers[0], "RedemptionsRepo", libraries, params);
	const libUsdLockersRepo = await deployTool(signers[0], "UsdLockersRepo", libraries, params);

	libraries = {
		"Checkpoints": libCheckpoints,
		"EnumerableSet": libEnumerableSet,
		"TopChain": libTopChain
	};
	const libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries, params);

	libraries = {
		"BallotsBox": libBallotsBox,
		"DelegateMap": libDelegateMap,
		"EnumerableSet": libEnumerableSet,
		"RulesParser": libRulesParser
	};
	const libMotionsRepo = await deployTool(signers[0], "MotionsRepo", libraries, params);

	libraries = {
		"EnumerableSet": libEnumerableSet,
		"SwapsRepo": libSwapsRepo,
	};	
	const libDealsRepo = await deployTool(signers[0], "DealsRepo", libraries, params);

	libraries = {
		"EnumerableSet": libEnumerableSet,
		"Checkpoints": libCheckpoints,
		"CondsRepo": libCondsRepo,
		"SwapsRepo": libSwapsRepo,
	};
	const libOptionsRepo = await deployTool(signers[0], "OptionsRepo", libraries, params);

	libraries = {
		"LockersRepo": libLockersRepo
	};
	const libUsersRepo = await deployTool(signers[0], "UsersRepo", libraries, params);	

	libraries = {
		"EnumerableSet": libEnumerableSet,
		"RulesParser": libRulesParser
	};
	const libLinksRepo = await deployTool(signers[0], "LinksRepo", libraries, params);

	libraries = {
		"RulesParser": libRulesParser,
		"ArrayUtils": libArrayUtils,
		"InterfacesHub": libInterfacesHub
	};
	const libOfROCK = await deployTool(signers[0], "LibOfROCK", libraries, params);	

	libraries = {
		"RulesParser": libRulesParser,
		"ArrayUtils": libArrayUtils,
		"InterfacesHub": libInterfacesHub,
		"Address": libAddress
	};
	const libOfBMMK = await deployTool(signers[0], "LibOfBMMK", libraries, params);	
	const libOfGMMK = await deployTool(signers[0], "LibOfGMMK", libraries, params);	

	libraries = {
		"RulesParser": libRulesParser,
		"InterfacesHub": libInterfacesHub
	};
	const libOfROAK = await deployTool(signers[0], "LibOfROAK", libraries, params);	

	libraries = {
		"RulesParser": libRulesParser,
		"InterfacesHub": libInterfacesHub,
		"DTClaims": libDTClaims
	};
	const libOfSHAK = await deployTool(signers[0], "LibOfSHAK", libraries, params);	

	libraries = {
		"InterfacesHub": libInterfacesHub
	};
	const libOfLOOK = await deployTool(signers[0], "LibOfLOOK", libraries, params);
	
	// ==== Deploy RegCenter ====
	
	libraries = {
		"DocsRepo": libDocsRepo,
		"UsersRepo": libUsersRepo,
		"LockersRepo": libLockersRepo,
		"Address": libAddress
	};

	params = [];

	let addrRC = await deployTool(signers[0], "RegCenter", libraries, params);

	let addrRCProxy = await proxyRC(signers[0], addrRC, await signers[1].getAddress());

	let rc = await readTool("RegCenter", addrRCProxy);

	console.log("deployed RC with owner: ", await rc.getOwner(), "\n");
	console.log("Bookeeper of RC: ", await rc.getBookeeper(), "\n");

	// ==== Get User_1 and User_2 ====

	const acct_0 = await rc.getMyUserNo();
	console.log("Account 0 userNo:", acct_0);

	const acct_1 = await rc.connect(signers[1]).getMyUserNo();
	console.log("Account 1 userNo:", acct_1);

	// ==== Reg Libraries ====

	await rc.connect(signers[1]).setTemplate( Types.ArrayUtils, libArrayUtils, acct_0);
	console.log("set template for 'ArrayUtils' at address: ", libArrayUtils, "\n");

	await rc.connect(signers[1]).setTemplate( Types.InterfacesHub, libInterfacesHub, acct_0);
	console.log("set template for 'InterfacesHub' at address: ", libInterfacesHub, "\n");

	await rc.connect(signers[1]).setTemplate( Types.RolesRepo, libRolesRepo, acct_0);
	console.log("set template for 'RolesRepo' at address: ", libRolesRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.UsdLockersRepo, libUsdLockersRepo, acct_0);
	console.log("set template for 'UsdLockersRepo' at address: ", libUsdLockersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.TypesList_, libTypesList, acct_0);
	console.log("set template for 'TypesList' at address: ", libTypesList, "\n");
	
	await rc.connect(signers[1]).setTemplate( Types.FilesRepo, libFilesRepo, acct_0);
	console.log("set template for 'FilesRepo' at address: ", libFilesRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.RulesParser, libRulesParser, acct_0);
	console.log("set template for 'RulesParser' at address: ", libRulesParser, "\n");

	await rc.connect(signers[1]).setTemplate( Types.RulesParser, libRulesParser, acct_0);
	console.log("set template for 'RulesParser' at address: ", libRulesParser, "\n");

	await rc.connect(signers[1]).setTemplate( Types.SigsRepo, libSigsRepo, acct_0);
	console.log("set template for 'SigsRepo' at address: ", libSigsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.OfficersRepo, libOfficersRepo, acct_0);
	console.log("set template for 'OfficersRepo' at address: ", libOfficersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.Checkpoints, libCheckpoints, acct_0);
	console.log("set template for 'Checkpoints' at address: ", libCheckpoints, "\n");
	
	await rc.connect(signers[1]).setTemplate( Types.MembersRepo, libMembersRepo, acct_0);
	console.log("set template for 'MembersRepo' at address: ", libMembersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.TopChain, libTopChain, acct_0);
	console.log("set template for 'TopChain' at address: ", libTopChain, "\n");

	await rc.connect(signers[1]).setTemplate( Types.BallotsBox, libBallotsBox, acct_0);
	console.log("set template for 'BallotsBox' at address: ", libBallotsBox, "\n");

	await rc.connect(signers[1]).setTemplate( Types.DelegateMap, libDelegateMap, acct_0);
	console.log("set template for 'DelegateMap' at address: ", libDelegateMap, "\n");

	await rc.connect(signers[1]).setTemplate( Types.MotionsRepo, libMotionsRepo, acct_0);
	console.log("set template for 'MotionsRepo' at address: ", libMotionsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.DealsRepo, libDealsRepo, acct_0);
	console.log("set template for 'DealsRepo' at address: ", libDealsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.DTClaims, libDTClaims, acct_0);
	console.log("set template for 'DTClaims' at address: ", libDTClaims, "\n");

	await rc.connect(signers[1]).setTemplate( Types.FRClaims, libFRClaims, acct_0);
	console.log("set template for 'FRClaims' at address: ", libFRClaims, "\n");

	await rc.connect(signers[1]).setTemplate( Types.LinksRepo, libLinksRepo, acct_0);
	console.log("set template for 'LinksRepo' at address: ", libLinksRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.FRClaims, libFRClaims, acct_0);
	console.log("set template for 'FRClaims' at address: ", libFRClaims, "\n");

	await rc.connect(signers[1]).setTemplate( Types.CondsRepo, libCondsRepo, acct_0);
	console.log("set template for 'CondsRepo' at address: ", libCondsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.OptionsRepo, libOptionsRepo, acct_0);
	console.log("set template for 'OptionsRepo' at address: ", libOptionsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.SwapsRepo, libSwapsRepo, acct_0);
	console.log("set template for 'SwapsRepo' at address: ", libSwapsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.PledgesRepo, libPledgesRepo, acct_0);
	console.log("set template for 'PledgesRepo' at address: ", libPledgesRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.LockersRepo, libLockersRepo, acct_0);
	console.log("set template for 'LockersRepo' at address: ", libLockersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.SharesRepo, libSharesRepo, acct_0);
	console.log("set template for 'SharesRepo' at address: ", libSharesRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.GoldChain, libGoldChain, acct_0);
	console.log("set template for 'GoldChain' at address: ", libGoldChain, "\n");

	await rc.connect(signers[1]).setTemplate( Types.OrdersRepo, libOrdersRepo, acct_0);
	console.log("set template for 'OrdersRepo' at address: ", libOrdersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.UsdOrdersRepo, libUsdOrdersRepo, acct_0);
	console.log("set template for 'UsdOrdersRepo' at address: ", libUsdOrdersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.UsdOrdersRepo, libUsdOrdersRepo, acct_0);
	console.log("set template for 'UsdOrdersRepo' at address: ", libUsdOrdersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.InvestorsRepo, libInvestorsRepo, acct_0);
	console.log("set template for 'InvestorsRepo' at address: ", libInvestorsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( Types.UsersRepo, libUsersRepo, acct_0);
	console.log("set template for 'UsersRepo' at address: ", libUsersRepo, "\n");


	


	// ==== Deploy RegCenter Tools ====

	libraries = {};
	params=[];

	let addrUSDC = await deployTool(signers[0], "MockUSDC", libraries, params);
	let usdc = await readTool("MockUSDC", addrUSDC);
	await usdc.init(signers[0], addrRCProxy);
	console.log("deployed USDC with owner: ", await usdc.getOwner(), "\n");

	

	





	params=[addrUSDC];
	let addrCNC = await deployTool(signers[0], "CreateNewComp", libraries, params);
	let cnc = await readTool("CreateNewComp", addrCNC);
	await cnc.init(signers[0], addrRC);

	// let cnf = await deployTool(signers[0], "CreateNewFund", libraries, params);
	// await cnf.init(signers[0], rc);

	// ==== Deploy Templates ====

	libraries = {
		"ArrayUtils": libArrayUtils,
		"DealsRepo": libDealsRepo,
		"EnumerableSet": libEnumerableSet,
		"RolesRepo": libRolesRepo,
		"SigsRepo": libSigsRepo,
		"SwapsRepo": libSwapsRepo,
		"BooksRepo": libBooksRepo
	};
	params=[];
	let ia = await deployTool(signers[0], "InvestmentAgreement", libraries, params);

	libraries = {
		"ArrayUtils": libArrayUtils,
		"EnumerableSet": libEnumerableSet,
		"RolesRepo": libRolesRepo,
		"SigsRepo": libSigsRepo
	};
	let sha = await deployTool(signers[0], "ShareholdersAgreement", libraries, params);

	libraries = {
		"EnumerableSet": libEnumerableSet,
		"RolesRepo": libRolesRepo,
		"BooksRepo": libBooksRepo
	};
	let ad = await deployTool(signers[0], "AntiDilution", libraries, params);

	libraries = {
		"ArrayUtils": libArrayUtils,
		"EnumerableSet": libEnumerableSet,
		"RolesRepo": libRolesRepo,
		"BooksRepo": libBooksRepo
	};
	let lu = await deployTool(signers[0], "LockUp", libraries, params);

	libraries = {
		"RolesRepo": libRolesRepo,
		"LinksRepo": libLinksRepo,
		"BooksRepo": libBooksRepo
	};
	let al = await deployTool(signers[0], "Alongs", libraries, params);
	
	libraries = {
		"EnumerableSet": libEnumerableSet,
		"RolesRepo": libRolesRepo,
		"OptionsRepo": libOptionsRepo
	};
	let op = await deployTool(signers[0], "Options", libraries, params);

	// ==== Keepers ====

	libraries = {
		// "RolesRepo": libRolesRepo,
		"Address": libAddress
	}

	let gk = await deployTool(signers[0], "CompKeeper", libraries, params);
	let fk = await deployTool(signers[0], "FundKeeper", libraries, params);
	let lpFundKeeper = await deployTool(signers[0], "LPFundKeeper", libraries, params);
	let listedLPFundKeeper = await deployTool(signers[0], "ListedLPFundKeeper", libraries, params);
	let openFundKeeper = await deployTool(signers[0], "OpenFundKeeper", libraries, params);
	let listedOpenFundKeeper = await deployTool(signers[0], "ListedOpenFundKeeper", libraries, params);
	
	libraries = {
		"BooksRepo": libBooksRepo
	}

	let rooKeeper = await deployTool(signers[0], "ROOKeeper", libraries, params);
	let romKeeper = await deployTool(signers[0], "ROMKeeper", libraries, params);
	let rodKeeper = await deployTool(signers[0], "RODKeeper", libraries, params);
	let fundRORKeeper = await deployTool(signers[0], "FundRORKeeper", libraries, params);
	let accountant = await deployTool(signers[0], "Accountant", libraries, params);

	// let usdKeeper = await deployTool(signers[0], "USDKeeper", libraries, params);
	// let usdRomKeeper = await deployTool(signers[0], "UsdROMKeeper", libraries, params);
	// let usdRooKeeper = await deployTool(signers[0], "UsdROOKeeper", libraries, params);
	// let usdRoaKeeper = await deployTool(signers[0], "UsdROAKeeper", libraries, params);

	libraries = {
		"RulesParser": libRulesParser,
		"BooksRepo": libBooksRepo
	}
	let shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries, params);
	let looKeeper = await deployTool(signers[0], "LOOKeeper", libraries, params);
	let roiKeeper = await deployTool(signers[0], "ROIKeeper", libraries, params);
	let fundLOOKeeper = await deployTool(signers[0], "FundLOOKeeper", libraries, params);
	let fundROIKeeper = await deployTool(signers[0], "FundROIKeeper", libraries, params);
	let fundAccountant = await deployTool(signers[0], "FundAccountant", libraries, params);

	// let usdLooKeeper = await deployTool(signers[0], "UsdLOOKeeper", libraries, params);

	libraries = {
		"ArrayUtils": libArrayUtils,
		"RulesParser": libRulesParser,
		"BooksRepo": libBooksRepo
	}
	let gmmKeeper = await deployTool(signers[0], "GMMKeeper", libraries, params);
	let bmmKeeper = await deployTool(signers[0], "BMMKeeper", libraries, params);
	let fundGMMKeeper = await deployTool(signers[0], "FundGMMKeeper", libraries, params);

	libraries = {
		"DocsRepo": libDocsRepo,
		"RulesParser": libRulesParser,
		"BooksRepo": libBooksRepo
	}
	let roaKeeper = await deployTool(signers[0], "ROAKeeper", libraries, params);

	libraries = {
		"ArrayUtils": libArrayUtils,
		"DocsRepo": libDocsRepo,
		"RulesParser": libRulesParser,
		"BooksRepo": libBooksRepo
	}
	let rocKeeper = await deployTool(signers[0], "ROCKeeper", libraries, params);
	let fundROCKeeper = await deployTool(signers[0], "FundROCKeeper", libraries, params);

	libraries = {
		"PledgesRepo": libPledgesRepo,
		"BooksRepo": libBooksRepo
	}
	let ropKeeper = await deployTool(signers[0], "ROPKeeper", libraries, params);

	// ==== Books ====

	libraries = {
		"DTClaims": libDTClaims,
		"FilesRepo": libFilesRepo,
		"FRClaims": libFRClaims,
		"TopChain": libTopChain,
		"BooksRepo": libBooksRepo
	}
	let roa = await deployTool(signers[0], "RegisterOfAgreements", libraries, params);

	libraries = {
		"OfficersRepo": libOfficersRepo,
		"BooksRepo": libBooksRepo
	}
	let rod = await deployTool(signers[0], "RegisterOfDirectors", libraries, params);

	libraries = {
		"MotionsRepo": libMotionsRepo,
		"BooksRepo": libBooksRepo
	}
	let mm = await deployTool(signers[0], "MeetingMinutes", libraries, params);

	libraries = {
		"FilesRepo": libFilesRepo
	}
	let roc = await deployTool(signers[0], "RegisterOfConstitution", libraries, params);

	libraries = {
		"OptionsRepo": libOptionsRepo,
		"SwapsRepo": libSwapsRepo,
		"BooksRepo": libBooksRepo
	}
	let roo = await deployTool(signers[0], "RegisterOfOptions", libraries, params);

	libraries = {
		"PledgesRepo": libPledgesRepo
	}
	let rop = await deployTool(signers[0], "RegisterOfPledges", libraries, params);

	libraries = {
		"LockersRepo": libLockersRepo,
		"SharesRepo": libSharesRepo,
		"BooksRepo": libBooksRepo
	}
	let ros = await deployTool(signers[0], "RegisterOfShares", libraries, params);

	libraries = {
		"Checkpoints": libCheckpoints,
		"MembersRepo": libMembersRepo,
		"TopChain": libTopChain,
		"BooksRepo": libBooksRepo
	}
	let rom = await deployTool(signers[0], "RegisterOfMembers", libraries, params);

	libraries = {
		"InvestorsRepo": libInvestorsRepo,
		"EnumerableSet": libEnumerableSet,
	}
	let roi = await deployTool(signers[0], "RegisterOfInvestors", libraries, params);

	libraries = {
		"UsdOrdersRepo": libUsdOrdersRepo,
		"GoldChain": libGoldChain,
		"EnumerableSet": libEnumerableSet,
		// "InvestorsRepo": libInvestorsRepo,
	}
	let loo = await deployTool(signers[0], "ListOfOrders", libraries, params);

	// libraries = {
	// 	"UsdOrdersRepo": libUsdOrdersRepo,
	// 	"GoldChain": libGoldChain,
	// 	"EnumerableSet": libEnumerableSet
	// }
	// let usdLoo = await deployTool(signers[0], "UsdListOfOrders", libraries, params);

	libraries = {
		"TeamsRepo": libTeamsRepo,
	};
	let lop = await deployTool(signers[0], "ListOfProjects", libraries, params);

	libraries = {
		"RulesParser": libRulesParser,
		"WaterfallsRepo": libWaterfallsRepo,
		"BooksRepo": libBooksRepo
	}
	let cashier = await deployTool(signers[0], "Cashier", libraries, params);

	libraries = {
		"RedemptionsRepo": libRedemptionsRepo
	}
	let ror = await deployTool(signers[0], "RegisterOfRedemptions", libraries, params);

	// libraries = {
	// 	"UsdLockersRepo": libUsdLockersRepo
	// }
	// params = [usdc];
	// let cashLockers = await deployTool(signers[0], "CashLockers", libraries, params);

	libraries = {};
	params = [addrRC];
	let pc = await deployTool(signers[0], "PriceConsumer", libraries, params);

	params = [];
	let mockFeedRegistry = 	await deployTool(signers[0], "MockFeedRegistry", libraries, params);

	// params = [rc, 10000];
	// let ft = await deployTool(signers[0], "FuelTank", libraries, params);

	params = [addrRC, 2600 * 10 ** 6];
	let ft = await deployTool(signers[0], "UsdFuelTank", libraries, params);

	// ==== SetTemplate ====

	await rc.connect(signers[1]).setTemplate( 1, rocKeeper, 1);
	console.log("set template for ROCKeeper at address: ", rocKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 2, rodKeeper, 1);
	console.log("set template for RODKeeper at address: ", rodKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 3, bmmKeeper, 1);
	console.log("set template for BMMKeeper at address: ", bmmKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 4, romKeeper, 1);
	console.log("set template for ROMKeeper at address: ", romKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 5, gmmKeeper, 1);
	console.log("set template for GMMKeeper at address: ", gmmKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 6, roaKeeper, 1);
	console.log("set template for ROAKeeper at address: ", roaKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 7, rooKeeper, 1);
	console.log("set template for ROOKeeper at address: ", rooKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 8, ropKeeper, 1);
	console.log("set template for ROPKeeper at address: ", ropKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 9, shaKeeper, 1);
	console.log("set template for SHAKeeper at address: ", shaKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 10, looKeeper, 1);
	console.log("set template for LOOKeeper at address: ", looKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 11, roc, 1);
	console.log("set template for ROC at address: ", roc, "\n");

	await rc.connect(signers[1]).setTemplate( 12, rod, 1);
	console.log("set template for ROD at address: ", rod, "\n");

	await rc.connect(signers[1]).setTemplate( 13, mm, 1);
	console.log("set template for MM at address: ", mm, "\n");

	await rc.connect(signers[1]).setTemplate( 14, rom, 1);
	console.log("set template for ROM at address: ", rom, "\n");

	await rc.connect(signers[1]).setTemplate( 15, roa, 1);
	console.log("set template for ROA at address: ", roa, "\n");

	await rc.connect(signers[1]).setTemplate( 16, roo, 1);
	console.log("set template for ROO at address: ", roo, "\n");

	await rc.connect(signers[1]).setTemplate( 17, rop, 1);
	console.log("set template for ROP at address: ", rop, "\n");

	await rc.connect(signers[1]).setTemplate( 18, ros, 1);
	console.log("set template for ROS at address: ", ros, "\n");

	await rc.connect(signers[1]).setTemplate( 19, loo, 1);
	console.log("set template for LOO at address: ", loo, "\n");

	await rc.connect(signers[1]).setTemplate( 20, gk, 1);
	console.log("set template for GK at address: ", gk, "\n");

	await rc.connect(signers[1]).setTemplate( 21, ia, 1);
	console.log("set template for IA at address: ", ia, "\n");

	await rc.connect(signers[1]).setTemplate( 22, sha, 1);
	console.log("set template for SHA at address: ", sha, "\n");

	await rc.connect(signers[1]).setTemplate( 23, ad, 1);
	console.log("set template for AD at address: ", ad, "\n");

	await rc.connect(signers[1]).setTemplate( 24, lu, 1);
	console.log("set template for LU at address: ", lu, "\n");

	await rc.connect(signers[1]).setTemplate( 25, al, 1);
	console.log("set template for AL at address: ", al, "\n");

	await rc.connect(signers[1]).setTemplate( 26, op, 1);
	console.log("set template for OP at address: ", op, "\n");

	await rc.connect(signers[1]).setTemplate( 27, lop, 1);
	console.log("set template for LOP at address: ", lop, "\n");

	await rc.connect(signers[1]).setTemplate( 28, cashier, 1);
	console.log("set template for Cashier at address: ", cashier, "\n");

	await rc.connect(signers[1]).setTemplate( 29, cashier, 1);
	console.log("set template for Cashier at address: ", cashier, "\n");

	await rc.connect(signers[1]).setTemplate( 30, cashier, 1);
	console.log("set template for Cashier at address: ", cashier, "\n");

	await rc.connect(signers[1]).setTemplate( 31, cashier, 1);
	console.log("set template for Cashier at address: ", cashier, "\n");

	await rc.connect(signers[1]).setTemplate( 32, cashier, 1);
	console.log("set template for Cashier at address: ", cashier, "\n");

	await rc.connect(signers[1]).setTemplate( 33, cashier, 1);
	console.log("set template for Cashier at address: ", cashier, "\n");

	await rc.connect(signers[1]).setTemplate( 34, cashier, 1);
	console.log("set template for Cashier at address: ", cashier, "\n");

	// await rc.connect(signers[1]).setTemplate( 29, usdLoo, 1);
	// console.log("set template for UsdLOO at address: ", usdLoo, "\n");

	// await rc.connect(signers[1]).setTemplate( 30, usdKeeper, 1);
	// console.log("set template for USDKeeper at address: ", usdKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 31, usdRomKeeper, 1);
	// console.log("set template for UsdROMKeeper at address: ", usdRomKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 32, usdRoaKeeper, 1);
	// console.log("set template for UsdROAKeeper at address: ", usdRoaKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 33, usdLooKeeper, 1);
	// console.log("set template for UsdLOOKeeper at address: ", usdLooKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 34, usdRooKeeper, 1);
	// console.log("set template for UsdROOKeeper at address: ", usdRooKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 35, roiKeeper, 1);
	console.log("set template for ROIKeeper at address: ", roi, "\n");

	await rc.connect(signers[1]).setTemplate( 36, roi, 1);
	console.log("set template for RegisterOfInvestors at address: ", roi, "\n");

	await rc.connect(signers[1]).setTemplate( 37, accountant, 1);
	console.log("set template for Accountant at address: ", accountant, "\n");

	await rc.connect(signers[1]).setTemplate( 38, fundRORKeeper, 1);
	console.log("set template for fundRORKeeper at address: ", fundRORKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 39, ror, 1);
	console.log("set template for RegisterOfRedemptions at address: ", ror, "\n");

	await rc.connect(signers[1]).setTemplate( 40, fk, 1);
	console.log("set template for FundKeeper at address: ", fk, "\n");

	await rc.connect(signers[1]).setTemplate( 41, fundAccountant, 1);
	console.log("set template for FundAccountant at address: ", fundAccountant, "\n");

	await rc.connect(signers[1]).setTemplate( 42, fundGMMKeeper, 1);
	console.log("set template for FundGMMKeeper at address: ", fundGMMKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 43, fundLOOKeeper, 1);
	console.log("set template for FundLOOKeeper at address: ", fundLOOKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 44, fundROCKeeper, 1);
	console.log("set template for FundROCKeeper at address: ", fundROCKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 45, fundROIKeeper, 1);
	console.log("set template for FundROIKeeper at address: ", fundROIKeeper, "\n");

	await rc.connect(signers[1]).setTemplate( 46, addrCNC, 1);
	console.log("set template for CreateNewComp at address: ", addrCNC, "\n");

	// await rc.connect(signers[1]).setTemplate( 47, privCompKeeper, 1);
	// console.log("set template for PrivateCompKeeper at address: ", privCompKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 48, growingCompKeeper, 1);
	// console.log("set template for GrowingCompKeeper at address: ", growingCompKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 49, listedCompKeeper, 1);
	// console.log("set template for ListedCompKeeper at address: ", listedCompKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 50, lpFundKeeper, 1);
	// console.log("set template for lpFundKeeper at address: ", lpFundKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 51, listedLPFundKeeper, 1);
	// console.log("set template for listedLPFundKeeper at address: ", listedLPFundKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 52, openFundKeeper, 1);
	// console.log("set template for openFundKeeper at address: ", openFundKeeper, "\n");

	// await rc.connect(signers[1]).setTemplate( 53, listedOpenFundKeeper, 1);
	// console.log("set template for listedOpenFundKeeper at address: ", listedOpenFundKeeper, "\n");

	// await rc.connect(signers[1]).setOracle(pc);
	// console.log("set Oracle at address: ", pc, "\n");

	// await rc.connect(signers[1]).setPriceFeed(0, mockFeedRegistry);
	// console.log("set MOCK price feed at address: ", mockFeedRegistry, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
