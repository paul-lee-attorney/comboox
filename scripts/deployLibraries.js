// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2026 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import {network} from "hardhat";
import { deployTool, getTypeByName } from "./deployTool";
import { readTool } from "./readTool";
import { proxySC } from "./proxyTool";

async function main() {

	const { ethers } = await network.connect();

	const signers = await ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress(), "\n"
	);

	console.log("Account balance:", (await ethers.provider.getBalance(signers[0])).toString(), "\n");

	let libraries = {};
	let params = [];

	// ==== Deploy RegCenter ====

	const libEnumerableSet = await deployTool(signers[0], "EnumerableSet", libraries, params);
	
	libraries = {
		"EnumerableSet": libEnumerableSet,
	};	
	const libDocsRepo = await deployTool(signers[0], "DocsRepo", libraries, params);
	const libUsersRepo = await deployTool(signers[0], "UsersRepo", libraries, params);

	libraries = {
		"DocsRepo": libDocsRepo,
		"UsersRepo": libUsersRepo,
	};
	let addrRC = await deployTool(signers[0], "RegCenter", libraries, params);
	let addrRCProxy = await proxySC(signers[0], "RegCenter", addrRC);
	const rc = await readTool("RegCenter", addrRCProxy);

	await rc.initialize(signers[1].address);
	console.log("Initialized RegCenter with keeper:", await rc.getBookeeper(), "\n");

	// ==== Get User_1 and User_2 ====

	const acct_0 = await rc.getMyUserNo();
	console.log("Account 0 userNo:", acct_0, "\n");

	const acct_1 = await rc.connect(signers[1]).getMyUserNo();
	console.log("Account 1 userNo:", acct_1, "\n");

	// ==== Set RegCenter Template & Proxy ====

	await rc.connect(signers[1]).setTemplate(getTypeByName("RegCenter"), addrRC, acct_0);
	console.log("Set RC Temp:", addrRC, "in BookOfDocs \n");

	await rc.connect(signers[1]).regProxy(addrRC, addrRCProxy);
	console.log("Registered RC Proxy:", addrRCProxy, "in BookOfDocs \n");

	console.log("deployed RC with owner: ", await rc.getOwner(), "\n");
	console.log("Bookeeper: ", await rc.getBookeeper(), "\n");

	// ==== Register EnumerableSet, DocsRepo & UsersRepo in RegCenter ====

	await rc.connect(signers[1]).setTemplate( getTypeByName("EnumerableSet"), libEnumerableSet, acct_0);
	console.log("set template for 'EnumerableSet' with TypeOfDoc:", getTypeByName("EnumerableSet"), "at address: ", libEnumerableSet, "\n");	

	await rc.connect(signers[1]).setTemplate( getTypeByName("DocsRepo"), libDocsRepo, acct_0);
	console.log("set template for 'DocsRepo' with TypeOfDoc:", getTypeByName("DocsRepo"), "at address: ", libDocsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("UsersRepo"), libUsersRepo, acct_0);
	console.log("set template for 'UsersRepo' with TypeOfDoc:", getTypeByName("UsersRepo"), "at address: ", libUsersRepo, "\n");

	// ==== Batch 1 Libraries ====
	libraries = {};

	const libArrayUtils = await deployTool(signers[0], "ArrayUtils", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("ArrayUtils"), libArrayUtils, acct_0);
	console.log("set template for 'ArrayUtils' with TypeOfDoc:", getTypeByName("ArrayUtils"), "at address: ", libArrayUtils, "\n");

	const libBallotsBox = await deployTool(signers[0], "BallotsBox", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("BallotsBox"), libBallotsBox, acct_0);
	console.log("set template for 'BallotsBox' with TypeOfDoc:", getTypeByName("BallotsBox"), "at address: ", libBallotsBox, "\n");
	
	const libCheckpoints = await deployTool(signers[0], "Checkpoints", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("Checkpoints"), libCheckpoints, acct_0);
	console.log("set template for 'Checkpoints' with TypeOfDoc:", getTypeByName("Checkpoints"), "at address: ", libCheckpoints, "\n");

	const libDelegateMap = await deployTool(signers[0], "DelegateMap", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("DelegateMap"), libDelegateMap, acct_0);
	console.log("set template for 'DelegateMap' with TypeOfDoc:", getTypeByName("DelegateMap"), "at address: ", libDelegateMap, "\n");

	const libFRClaims = await deployTool(signers[0], "FRClaims", libraries, params);
	
	await rc.connect(signers[1]).setTemplate( getTypeByName("FRClaims"), libFRClaims, acct_0);
	console.log("set template for 'FRClaims' with TypeOfDoc:", getTypeByName("FRClaims"), "at address: ", libFRClaims, "\n");

	const libGoldChain = await deployTool(signers[0], "GoldChain", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("GoldChain"), libGoldChain, acct_0);
	console.log("set template for 'GoldChain' with TypeOfDoc:", getTypeByName("GoldChain"), "at address: ", libGoldChain, "\n");

	const libRolesRepo = await deployTool(signers[0], "RolesRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("RolesRepo"), libRolesRepo, acct_0);
	console.log("set template for 'RolesRepo' with TypeOfDoc:", getTypeByName("RolesRepo"), "at address: ", libRolesRepo, "\n");

	const libRulesParser = await deployTool(signers[0], "RulesParser", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("RulesParser"), libRulesParser, acct_0);
	console.log("set template for 'RulesParser' with TypeOfDoc:", getTypeByName("RulesParser"), "at address: ", libRulesParser, "\n");
	
	const libSwapsRepo = await deployTool(signers[0], "SwapsRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("SwapsRepo"), libSwapsRepo, acct_0);
	console.log("set template for 'SwapsRepo' with TypeOfDoc:", getTypeByName("SwapsRepo"), "at address: ", libSwapsRepo, "\n");

	const libTopChain = await deployTool(signers[0], "TopChain", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("TopChain"), libTopChain, acct_0);
	console.log("set template for 'TopChain' with TypeOfDoc:", getTypeByName("TopChain"), "at address: ", libTopChain, "\n");

	const libInvestorsRepo = await deployTool(signers[0], "InvestorsRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("InvestorsRepo"), libInvestorsRepo, acct_0);
	console.log("set template for 'InvestorsRepo' with TypeOfDoc:", getTypeByName("InvestorsRepo"), "at address: ", libInvestorsRepo, "\n");

	const libWaterfallsRepo = await deployTool(signers[0], "WaterfallsRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("WaterfallsRepo"), libWaterfallsRepo, acct_0);
	console.log("set template for 'WaterfallsRepo' with TypeOfDoc:", getTypeByName("WaterfallsRepo"), "at address: ", libWaterfallsRepo, "\n");

	const libInterfacesHub = await deployTool(signers[0], "InterfacesHub", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("InterfacesHub"), libInterfacesHub, acct_0);
	console.log("set template for 'InterfacesHub' with TypeOfDoc:", getTypeByName("InterfacesHub"), "at address: ", libInterfacesHub, "\n");

	const libKeepersRouter = await deployTool(signers[0], "KeepersRouter", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("KeepersRouter"), libKeepersRouter, acct_0);
	console.log("set template for 'KeepersRouter' with TypeOfDoc:", getTypeByName("KeepersRouter"), "at address: ", libKeepersRouter, "\n");

	// ==== Batch 2 ====

	libraries = {
		"EnumerableSet": libEnumerableSet,
	};	
	const libCondsRepo = await deployTool(signers[0], "CondsRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("CondsRepo"), libCondsRepo, acct_0);
	console.log("set template for 'CondsRepo' with TypeOfDoc:", getTypeByName("CondsRepo"), "at address: ", libCondsRepo, "\n");

	const libDTClaims = await deployTool(signers[0], "DTClaims", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("DTClaims"), libDTClaims, acct_0);
	console.log("set template for 'DTClaims' with TypeOfDoc:", getTypeByName("DTClaims"), "at address: ", libDTClaims, "\n");

	const libFilesRepo = await deployTool(signers[0], "FilesRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("FilesRepo"), libFilesRepo, acct_0);
	console.log("set template for 'FilesRepo' with TypeOfDoc:", getTypeByName("FilesRepo"), "at address: ", libFilesRepo, "\n");

	const libLockersRepo = await deployTool(signers[0], "LockersRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("LockersRepo"), libLockersRepo, acct_0);
	console.log("set template for 'LockersRepo' with TypeOfDoc:", getTypeByName("LockersRepo"), "at address: ", libLockersRepo, "\n");

	const libOfficersRepo = await deployTool(signers[0], "OfficersRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("OfficersRepo"), libOfficersRepo, acct_0);
	console.log("set template for 'OfficersRepo' with TypeOfDoc:", getTypeByName("OfficersRepo"), "at address: ", libOfficersRepo, "\n");

	const libPledgesRepo = await deployTool(signers[0], "PledgesRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("PledgesRepo"), libPledgesRepo, acct_0);
	console.log("set template for 'PledgesRepo' with TypeOfDoc:", getTypeByName("PledgesRepo"), "at address: ", libPledgesRepo, "\n");

	const libSigsRepo = await deployTool(signers[0], "SigsRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("SigsRepo"), libSigsRepo, acct_0);
	console.log("set template for 'SigsRepo' with TypeOfDoc:", getTypeByName("SigsRepo"), "at address: ", libSigsRepo, "\n");

	const libSharesRepo = await deployTool(signers[0], "SharesRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("SharesRepo"), libSharesRepo, acct_0);
	console.log("set template for 'SharesRepo' with TypeOfDoc:", getTypeByName("SharesRepo"), "at address: ", libSharesRepo, "\n");

	const libRedemptionsRepo = await deployTool(signers[0], "RedemptionsRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("RedemptionsRepo"), libRedemptionsRepo, acct_0);
	console.log("set template for 'RedemptionsRepo' with TypeOfDoc:", getTypeByName("RedemptionsRepo"), "at address: ", libRedemptionsRepo, "\n");

	const libUsdLockersRepo = await deployTool(signers[0], "UsdLockersRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("UsdLockersRepo"), libUsdLockersRepo, acct_0);
	console.log("set template for 'UsdLockersRepo' with TypeOfDoc:", getTypeByName("UsdLockersRepo"), "at address: ", libUsdLockersRepo, "\n");

	const libDealsRepo = await deployTool(signers[0], "DealsRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("DealsRepo"), libDealsRepo, acct_0);
	console.log("set template for 'DealsRepo' with TypeOfDoc:", getTypeByName("DealsRepo"), "at address: ", libDealsRepo, "\n");

	// ==== Batch 3 ====

	libraries = {
		"InterfacesHub": libInterfacesHub,
	};
	const libRoyaltyCharge = await deployTool(signers[0], "RoyaltyCharge", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("RoyaltyCharge"), libRoyaltyCharge, acct_0);
	console.log("set template for 'RoyaltyCharge' with TypeOfDoc:", getTypeByName("RoyaltyCharge"), "at address: ", libRoyaltyCharge, "\n");

	libraries = {
		"GoldChain": libGoldChain,
	};
	const libOrdersRepo = await deployTool(signers[0], "OrdersRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("OrdersRepo"), libOrdersRepo, acct_0);
	console.log("set template for 'OrdersRepo' with TypeOfDoc:", getTypeByName("OrdersRepo"), "at address: ", libOrdersRepo, "\n");

	const libUsdOrdersRepo = await deployTool(signers[0], "UsdOrdersRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("UsdOrdersRepo"), libUsdOrdersRepo, acct_0);
	console.log("set template for 'UsdOrdersRepo' with TypeOfDoc:", getTypeByName("UsdOrdersRepo"), "at address: ", libUsdOrdersRepo, "\n");

	libraries = {
		"EnumerableSet": libEnumerableSet,
		"RulesParser": libRulesParser
	};
	const libLinksRepo = await deployTool(signers[0], "LinksRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("LinksRepo"), libLinksRepo, acct_0);
	console.log("set template for 'LinksRepo' with TypeOfDoc:", getTypeByName("LinksRepo"), "at address: ", libLinksRepo, "\n");

	libraries = {
		"Checkpoints": libCheckpoints,
		"EnumerableSet": libEnumerableSet,
		"TopChain": libTopChain
	};
	const libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("MembersRepo"), libMembersRepo, acct_0);
	console.log("set template for 'MembersRepo' with TypeOfDoc:", getTypeByName("MembersRepo"), "at address: ", libMembersRepo, "\n");

	libraries = {
		"BallotsBox": libBallotsBox,
		"DelegateMap": libDelegateMap,
		"EnumerableSet": libEnumerableSet,
		"RulesParser": libRulesParser
	};
	const libMotionsRepo = await deployTool(signers[0], "MotionsRepo", libraries, params);

	await rc.connect(signers[1]).setTemplate( getTypeByName("MotionsRepo"), libMotionsRepo, acct_0);
	console.log("set template for 'MotionsRepo' with TypeOfDoc:", getTypeByName("MotionsRepo"), "at address: ", libMotionsRepo, "\n");

	libraries = {
		"EnumerableSet": libEnumerableSet,
		"Checkpoints": libCheckpoints,
		"CondsRepo": libCondsRepo,
		"SwapsRepo": libSwapsRepo,
	};
	const libOptionsRepo = await deployTool(signers[0], "OptionsRepo", libraries, params);
	
	await rc.connect(signers[1]).setTemplate( getTypeByName("OptionsRepo"), libOptionsRepo, acct_0);
	console.log("set template for 'OptionsRepo' with TypeOfDoc:", getTypeByName("OptionsRepo"), "at address: ", libOptionsRepo, "\n");

	
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
