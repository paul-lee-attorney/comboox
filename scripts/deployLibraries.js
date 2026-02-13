// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import {network} from "hardhat";
import { deployTool, getTypeByName } from "./deployTool";
import { readTool } from "./readTool";
import { proxyRC } from "./proxyTool";

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
	const libEnumerableSet = await deployTool(signers[0], "EnumerableSet", libraries, params);
	const libFRClaims = await deployTool(signers[0], "FRClaims", libraries, params);
	const libGoldChain = await deployTool(signers[0], "GoldChain", libraries, params);
	const libRolesRepo = await deployTool(signers[0], "RolesRepo", libraries, params);
	const libRulesParser = await deployTool(signers[0], "RulesParser", libraries, params);
	const libSwapsRepo = await deployTool(signers[0], "SwapsRepo", libraries, params);
	const libTopChain = await deployTool(signers[0], "TopChain", libraries, params);
	const libInvestorsRepo = await deployTool(signers[0], "InvestorsRepo", libraries, params);
	const libWaterfallsRepo = await deployTool(signers[0], "WaterfallsRepo", libraries, params);
	const libInterfacesHub = await deployTool(signers[0], "InterfacesHub", libraries, params);
	const libTypesList = await deployTool(signers[0], "TypesList", libraries, params);

	libraries = {};
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
	const libDocsRepo = await deployTool(signers[0], "DocsRepo", libraries, params);
	const libDTClaims = await deployTool(signers[0], "DTClaims", libraries, params);
	const libFilesRepo = await deployTool(signers[0], "FilesRepo", libraries, params);
	const libLockersRepo = await deployTool(signers[0], "LockersRepo", libraries, params);
	const libOfficersRepo = await deployTool(signers[0], "OfficersRepo", libraries, params);
	const libPledgesRepo = await deployTool(signers[0], "PledgesRepo", libraries, params);
	const libSigsRepo = await deployTool(signers[0], "SigsRepo", libraries, params);
	const libSharesRepo = await deployTool(signers[0], "SharesRepo", libraries, params);
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
		"EnumerableSet": libEnumerableSet
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
	};

	params = [];

	let addrRC = await deployTool(signers[0], "RegCenter", libraries, params);

	let addrRCProxy = await proxyRC(signers[0], addrRC, await signers[1].getAddress());

	// ==== Get User_1 and User_2 ====

	const rc = await readTool("RegCenter", addrRCProxy);

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

	// ==== Reg Libraries ====

	await rc.connect(signers[1]).setTemplate( getTypeByName("ArrayUtils"), libArrayUtils, acct_0);
	console.log("set template for 'ArrayUtils' with TypeOfDoc:", getTypeByName("ArrayUtils"), "at address: ", libArrayUtils, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("InterfacesHub"), libInterfacesHub, acct_0);
	console.log("set template for 'InterfacesHub' with TypeOfDoc:", getTypeByName("InterfacesHub"), "at address: ", libInterfacesHub, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("RolesRepo"), libRolesRepo, acct_0);
	console.log("set template for 'RolesRepo' with TypeOfDoc:", getTypeByName("RolesRepo"), "at address: ", libRolesRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("UsdLockersRepo"), libUsdLockersRepo, acct_0);
	console.log("set template for 'UsdLockersRepo' with TypeOfDoc:", getTypeByName("UsdLockersRepo"), "at address: ", libUsdLockersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("TypesList"), libTypesList, acct_0);
	console.log("set template for 'TypesList' with TypeOfDoc:", getTypeByName("TypesList"), "at address: ", libTypesList, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("EnumerableSet"), libEnumerableSet, acct_0);
	console.log("set template for 'EnumerableSet' with TypeOfDoc:", getTypeByName("EnumerableSet"), "at address: ", libEnumerableSet, "\n");	

	await rc.connect(signers[1]).setTemplate( getTypeByName("FilesRepo"), libFilesRepo, acct_0);
	console.log("set template for 'FilesRepo' with TypeOfDoc:", getTypeByName("FilesRepo"), "at address: ", libFilesRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("RulesParser"), libRulesParser, acct_0);
	console.log("set template for 'RulesParser' with TypeOfDoc:", getTypeByName("RulesParser"), "at address: ", libRulesParser, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("SigsRepo"), libSigsRepo, acct_0);
	console.log("set template for 'SigsRepo' with TypeOfDoc:", getTypeByName("SigsRepo"), "at address: ", libSigsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("OfficersRepo"), libOfficersRepo, acct_0);
	console.log("set template for 'OfficersRepo' with TypeOfDoc:", getTypeByName("OfficersRepo"), "at address: ", libOfficersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("Checkpoints"), libCheckpoints, acct_0);
	console.log("set template for 'Checkpoints' with TypeOfDoc:", getTypeByName("Checkpoints"), "at address: ", libCheckpoints, "\n");
	
	await rc.connect(signers[1]).setTemplate( getTypeByName("MembersRepo"), libMembersRepo, acct_0);
	console.log("set template for 'MembersRepo' with TypeOfDoc:", getTypeByName("MembersRepo"), "at address: ", libMembersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("TopChain"), libTopChain, acct_0);
	console.log("set template for 'TopChain' with TypeOfDoc:", getTypeByName("TopChain"), "at address: ", libTopChain, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("BallotsBox"), libBallotsBox, acct_0);
	console.log("set template for 'BallotsBox' with TypeOfDoc:", getTypeByName("BallotsBox"), "at address: ", libBallotsBox, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("DelegateMap"), libDelegateMap, acct_0);
	console.log("set template for 'DelegateMap' with TypeOfDoc:", getTypeByName("DelegateMap"), "at address: ", libDelegateMap, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("MotionsRepo"), libMotionsRepo, acct_0);
	console.log("set template for 'MotionsRepo' with TypeOfDoc:", getTypeByName("MotionsRepo"), "at address: ", libMotionsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("DealsRepo"), libDealsRepo, acct_0);
	console.log("set template for 'DealsRepo' with TypeOfDoc:", getTypeByName("DealsRepo"), "at address: ", libDealsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("DTClaims"), libDTClaims, acct_0);
	console.log("set template for 'DTClaims' with TypeOfDoc:", getTypeByName("DTClaims"), "at address: ", libDTClaims, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("FRClaims"), libFRClaims, acct_0);
	console.log("set template for 'FRClaims' with TypeOfDoc:", getTypeByName("FRClaims"), "at address: ", libFRClaims, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("LinksRepo"), libLinksRepo, acct_0);
	console.log("set template for 'LinksRepo' with TypeOfDoc:", getTypeByName("LinksRepo"), "at address: ", libLinksRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("CondsRepo"), libCondsRepo, acct_0);
	console.log("set template for 'CondsRepo' with TypeOfDoc:", getTypeByName("CondsRepo"), "at address: ", libCondsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("OptionsRepo"), libOptionsRepo, acct_0);
	console.log("set template for 'OptionsRepo' with TypeOfDoc:", getTypeByName("OptionsRepo"), "at address: ", libOptionsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("SwapsRepo"), libSwapsRepo, acct_0);
	console.log("set template for 'SwapsRepo' with TypeOfDoc:", getTypeByName("SwapsRepo"), "at address: ", libSwapsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("PledgesRepo"), libPledgesRepo, acct_0);
	console.log("set template for 'PledgesRepo' with TypeOfDoc:", getTypeByName("PledgesRepo"), "at address: ", libPledgesRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("LockersRepo"), libLockersRepo, acct_0);
	console.log("set template for 'LockersRepo' with TypeOfDoc:", getTypeByName("LockersRepo"), "at address: ", libLockersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("SharesRepo"), libSharesRepo, acct_0);
	console.log("set template for 'SharesRepo' with TypeOfDoc:", getTypeByName("SharesRepo"), "at address: ", libSharesRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("GoldChain"), libGoldChain, acct_0);
	console.log("set template for 'GoldChain' with TypeOfDoc:", getTypeByName("GoldChain"), "at address: ", libGoldChain, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("OrdersRepo"), libOrdersRepo, acct_0);
	console.log("set template for 'OrdersRepo' with TypeOfDoc:", getTypeByName("OrdersRepo"), "at address: ", libOrdersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("UsdOrdersRepo"), libUsdOrdersRepo, acct_0);
	console.log("set template for 'UsdOrdersRepo' with TypeOfDoc:", getTypeByName("UsdOrdersRepo"), "at address: ", libUsdOrdersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("InvestorsRepo"), libInvestorsRepo, acct_0);
	console.log("set template for 'InvestorsRepo' with TypeOfDoc:", getTypeByName("InvestorsRepo"), "at address: ", libInvestorsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("UsersRepo"), libUsersRepo, acct_0);
	console.log("set template for 'UsersRepo' with TypeOfDoc:", getTypeByName("UsersRepo"), "at address: ", libUsersRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("DocsRepo"), libDocsRepo, acct_0);
	console.log("set template for 'DocsRepo' with TypeOfDoc:", getTypeByName("DocsRepo"), "at address: ", libDocsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("WaterfallsRepo"), libWaterfallsRepo, acct_0);
	console.log("set template for 'WaterfallsRepo' with TypeOfDoc:", getTypeByName("WaterfallsRepo"), "at address: ", libWaterfallsRepo, "\n");
	
	await rc.connect(signers[1]).setTemplate( getTypeByName("RedemptionsRepo"), libRedemptionsRepo, acct_0);
	console.log("set template for 'RedemptionsRepo' with TypeOfDoc:", getTypeByName("RedemptionsRepo"), "at address: ", libRedemptionsRepo, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("LibOfROCK"), libOfROCK, acct_0);
	console.log("set template for 'LibOfROCK' with TypeOfDoc:", getTypeByName("LibOfROCK"), "at address: ", libOfROCK, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("LibOfBMMK"), libOfBMMK, acct_0);
	console.log("set template for 'LibOfBMMK' with TypeOfDoc:", getTypeByName("LibOfBMMK"), "at address: ", libOfBMMK, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("LibOfGMMK"), libOfGMMK, acct_0);
	console.log("set template for 'LibOfGMMK' with TypeOfDoc:", getTypeByName("LibOfGMMK"), "at address: ", libOfGMMK, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("LibOfROAK"), libOfROAK, acct_0);
	console.log("set template for 'LibOfROAK' with TypeOfDoc:", getTypeByName("LibOfROAK"), "at address: ", libOfROAK, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("LibOfSHAK"), libOfSHAK, acct_0);
	console.log("set template for 'LibOfSHAK' with TypeOfDoc:", getTypeByName("LibOfSHAK"), "at address: ", libOfSHAK, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("LibOfLOOK"), libOfLOOK, acct_0);
	console.log("set template for 'LibOfLOOK' with TypeOfDoc:", getTypeByName("LibOfLOOK"), "at address: ", libOfLOOK, "\n");

	await rc.connect(signers[1]).setTemplate( getTypeByName("KeepersRouter"), libKeepersRouter, acct_0);
	console.log("set template for 'KeepersRouter' with TypeOfDoc:", getTypeByName("KeepersRouter"), "at address: ", libKeepersRouter, "\n");
	
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
