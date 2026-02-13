// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import {network} from "hardhat";
import { deployTool, getTypeByName } from "./deployTool";
import { readTool } from "./readTool";
import addrs from "../server/src/contracts/contracts-address.json";

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

	// ==== Get RC ====

	const rc = await readTool("RegCenter", addrs.RegCenter_Proxy);
	const acct_0 = await rc.getMyUserNo();
	const acct_1 = await rc.connect(signers[1]).getMyUserNo();

	// ==== Deploy RegCenter Utils ====

	// ---- MockUSDC ----
	
	const addrUSDC = await deployTool(signers[0], "MockUSDC", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("MockUSDC"), addrUSDC, acct_0);

	await rc.connect(signers[1]).proxyDoc(getTypeByName("MockUSDC"), 1);

	const usdc = await readTool("MockUSDC", (await rc.getDoc(getTypeByName("MockUSDC"), 1, 1))[1]);
	console.log("deployed MockUSDC:", usdc.target, "with owner: ", await rc.getOwner(), "\n");
	
	// ---- CreateNewComp ----

	libraries = {
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1],
	}

	const addrCNC = await deployTool(signers[0], "CreateNewComp", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("CreateNewComp"), addrCNC, acct_0);

	await rc.connect(signers[1]).proxyDoc(getTypeByName("CreateNewComp"), 1);

	const cnc = await readTool("CreateNewComp", (await rc.getDoc(getTypeByName("CreateNewComp"), 1, 1))[1]);

	await cnc.connect(signers[1]).setNewOwner(await signers[0].getAddress());
	console.log("deployed CreateNewComp:", cnc.target, "with owner: ", (await cnc.owner())[0], "\n");

	await cnc.connect(signers[1]).updateBank(usdc.target);
	console.log("updated bank for CreateNewComp to: ", usdc.target, "\n");

	// ---- CashLockers ----

	libraries = {
		"UsdLockersRepo": (await rc.getTemp(getTypeByName("UsdLockersRepo"), 1))[1],
	}
	params = [ usdc.target ];
	const addrCashLockers = await deployTool(signers[0], "CashLockers", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("CashLockers"), addrCashLockers, acct_0);
	console.log("Reg the CashLockers:", addrCashLockers, " in BookOfDocs \n");

	// ---- FuelTank ----

	libraries = {
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1],
		// "Address": (await rc.getTemp(getTypeByName("Address"), 1))[1],
	}
	params = [];
	const addrUsdFuelTank = await deployTool(signers[0], "UsdFuelTank", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("UsdFuelTank"), addrUsdFuelTank, acct_0);
	console.log("Reg the Temp of UsdFuelTank:", addrUsdFuelTank, " in BookOfDocs \n");

	await rc.connect(signers[1]).proxyDoc(getTypeByName("UsdFuelTank"), 1);
	console.log("Proxy deployed for UsdFuelTank \n");

	const ft = await readTool("UsdFuelTank", (await rc.getDoc(getTypeByName("UsdFuelTank"), 1, 1))[1]);
	await ft.connect(signers[1]).setNewOwner(await signers[0].getAddress());
	console.log("transfer ownership of UsdFuelTank to: ", (await ft.owner())[0], "\n");

	await ft.setRate(2600 * 10 ** 6);
	console.log("set rate for UsdFuelTank to: ", 2600 * 10 ** 6, "\n");

	// ==== Deploy Templates ====

	libraries = {
		"ArrayUtils": (await rc.getTemp(getTypeByName("ArrayUtils"), 1))[1],
		"DealsRepo": (await rc.getTemp(getTypeByName("DealsRepo"), 1))[1],
		"EnumerableSet": (await rc.getTemp(getTypeByName("EnumerableSet"), 1))[1],
		"RolesRepo": (await rc.getTemp(getTypeByName("RolesRepo"), 1))[1],
		"SigsRepo": (await rc.getTemp(getTypeByName("SigsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	};
	params=[];
	const addrIA = await deployTool(signers[0], "InvestmentAgreement", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("InvestmentAgreement"), addrIA, acct_0);
	console.log("Reg the InvestmentAgreement:", addrIA, " in BookOfDocs \n");

	libraries = {
		"ArrayUtils": (await rc.getTemp(getTypeByName("ArrayUtils"), 1))[1],
		"EnumerableSet": (await rc.getTemp(getTypeByName("EnumerableSet"), 1))[1],
		"RolesRepo": (await rc.getTemp(getTypeByName("RolesRepo"), 1))[1],
		"SigsRepo": (await rc.getTemp(getTypeByName("SigsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	};
	const addrSHA = await deployTool(signers[0], "ShareholdersAgreement", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("ShareholdersAgreement"), addrSHA, acct_0);
	console.log("Reg the ShareholdersAgreement:", addrSHA, "in BookOfDocs \n");

	libraries = {
		"EnumerableSet": (await rc.getTemp(getTypeByName("EnumerableSet"), 1))[1],
		"RolesRepo": (await rc.getTemp(getTypeByName("RolesRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	};
	const addrAD = await deployTool(signers[0], "AntiDilution", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("AntiDilution"), addrAD, acct_0);
	console.log("Reg the AntiDilution:", addrAD, "in BookOfDocs \n");

	libraries = {
		"ArrayUtils": (await rc.getTemp(getTypeByName("ArrayUtils"), 1))[1],
		"EnumerableSet": (await rc.getTemp(getTypeByName("EnumerableSet"), 1))[1],
		"RolesRepo": (await rc.getTemp(getTypeByName("RolesRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	};
	const addrLU = await deployTool(signers[0], "LockUp", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("LockUp"), addrLU, acct_0);
	console.log("Reg the LockUp:", addrLU, "in BookOfDocs \n");

	libraries = {
		"RolesRepo": (await rc.getTemp(getTypeByName("RolesRepo"), 1))[1],
		"LinksRepo": (await rc.getTemp(getTypeByName("LinksRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	};
	const addrAL = await deployTool(signers[0], "Alongs", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("Alongs"), addrAL, acct_0);
	console.log("Reg the Alongs:", addrAL, "in BookOfDocs \n");

	libraries = {
		"EnumerableSet": (await rc.getTemp(getTypeByName("EnumerableSet"), 1))[1],
		"RolesRepo": (await rc.getTemp(getTypeByName("RolesRepo"), 1))[1],
		"OptionsRepo": (await rc.getTemp(getTypeByName("OptionsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	};
	const addrOP = await deployTool(signers[0], "Options", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("Options"), addrOP, acct_0);
	console.log("Reg the Options:", addrOP, "in BookOfDocs \n");

	// ==== Keepers ====

	libraries = {
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1],
		"KeepersRouter": (await rc.getTemp(getTypeByName("KeepersRouter"), 1))[1],
	}
	const addrGK = await deployTool(signers[0], "GeneralKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("GeneralKeeper"), addrGK, acct_0);
	console.log("set template for GeneralKeeper at address:", addrGK, "\n");
	
	libraries = {
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROOKeeper = await deployTool(signers[0], "ROOKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("ROOKeeper"), addrROOKeeper, acct_0);
	console.log("set template for ROOKeeper at address: ", addrROOKeeper, "\n");

	const addrROMKeeper = await deployTool(signers[0], "ROMKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("ROMKeeper"), addrROMKeeper, acct_0);
	console.log("set template for ROMKeeper at address: ", addrROMKeeper, "\n");

	const addrRODKeeper = await deployTool(signers[0], "RODKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("RODKeeper"), addrRODKeeper, acct_0);
	console.log("set template for RODKeeper at address: ", addrRODKeeper, "\n");

	const addrFundRORKeeper = await deployTool(signers[0], "FundRORKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("FundRORKeeper"), addrFundRORKeeper, acct_0);
	console.log("set template for FundRORKeeper at address: ", addrFundRORKeeper, "\n");

	const addrAccountant = await deployTool(signers[0], "Accountant", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("Accountant"), addrAccountant, acct_0);
	console.log("set template for Accountant at address: ", addrAccountant, "\n");

	libraries = {
		"LibOfSHAK": (await rc.getTemp(getTypeByName("LibOfSHAK"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrSHAKeeper = await deployTool(signers[0], "SHAKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("SHAKeeper"), addrSHAKeeper, acct_0);
	console.log("set template for SHAKeeper at address: ", addrSHAKeeper, "\n");

	libraries = {
		"LibOfLOOK": (await rc.getTemp(getTypeByName("LibOfLOOK"), 1))[1],
		"RulesParser": (await rc.getTemp(getTypeByName("RulesParser"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrLOOKeeper = await deployTool(signers[0], "LOOKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("LOOKeeper"), addrLOOKeeper, acct_0);
	console.log("set template for LOOKeeper at address: ", addrLOOKeeper, "\n");

	const addrFundLOOKeeper = await deployTool(signers[0], "FundLOOKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("FundLOOKeeper"), addrFundLOOKeeper, acct_0);
	console.log("set template for FundLOOKeeper at address: ", addrFundLOOKeeper, "\n");
	
	libraries = {
		"RulesParser": (await rc.getTemp(getTypeByName("RulesParser"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROIKeeper = await deployTool(signers[0], "ROIKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("ROIKeeper"), addrROIKeeper, acct_0);
	console.log("set template for ROIKeeper at address: ", addrROIKeeper, "\n");

	const addrFundROIKeeper = await deployTool(signers[0], "FundROIKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("FundROIKeeper"), addrFundROIKeeper, acct_0);
	console.log("set template for FundROIKeeper at address: ", addrFundROIKeeper, "\n");
	
	const addrFundAccountant = await deployTool(signers[0], "FundAccountant", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("FundAccountant"), addrFundAccountant, acct_0);
	console.log("set template for FundAccountant at address: ", addrFundAccountant, "\n");

	libraries = {
		"LibOfGMMK": (await rc.getTemp(getTypeByName("LibOfGMMK"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrGMMKeeper = await deployTool(signers[0], "GMMKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("GMMKeeper"), addrGMMKeeper, acct_0);
	console.log("set template for GMMKeeper at address: ", addrGMMKeeper, "\n");

	const addrFundGMMKeeper = await deployTool(signers[0], "FundGMMKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("FundGMMKeeper"), addrFundGMMKeeper, acct_0);
	console.log("set template for FundGMMKeeper at address: ", addrFundGMMKeeper, "\n");

	libraries = {
		"LibOfBMMK": (await rc.getTemp(getTypeByName("LibOfBMMK"), 1))[1],
		"RulesParser": (await rc.getTemp(getTypeByName("RulesParser"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrBMMKeeper = await deployTool(signers[0], "BMMKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("BMMKeeper"), addrBMMKeeper, acct_0);
	console.log("set template for BMMKeeper at address: ", addrBMMKeeper, "\n");

	libraries = {
		"LibOfROAK": (await rc.getTemp(getTypeByName("LibOfROAK"), 1))[1],
		"DocsRepo": (await rc.getTemp(getTypeByName("DocsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROAKeeper = await deployTool(signers[0], "ROAKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("ROAKeeper"), addrROAKeeper, acct_0);
	console.log("set template for ROAKeeper at address: ", addrROAKeeper, "\n");

	libraries = {
		"LibOfROCK": (await rc.getTemp(getTypeByName("LibOfROCK"), 1))[1],
		"DocsRepo": (await rc.getTemp(getTypeByName("DocsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROCKeeper = await deployTool(signers[0], "ROCKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("ROCKeeper"), addrROCKeeper, acct_0);
	console.log("set template for ROCKeeper at address: ", addrROCKeeper, "\n");

	libraries = {
		"RulesParser": (await rc.getTemp(getTypeByName("RulesParser"), 1))[1],
		"ArrayUtils": (await rc.getTemp(getTypeByName("ArrayUtils"), 1))[1],
		"DocsRepo": (await rc.getTemp(getTypeByName("DocsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrFundROCKeeper = await deployTool(signers[0], "FundROCKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("FundROCKeeper"), addrFundROCKeeper, acct_0);
	console.log("set template for FundROCKeeper at address: ", addrFundROCKeeper, "\n");

	libraries = {
		"PledgesRepo": (await rc.getTemp(getTypeByName("PledgesRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROPKeeper = await deployTool(signers[0], "ROPKeeper", libraries, params);
	await rc.connect(signers[1]).setTemplate( getTypeByName("ROPKeeper"), addrROPKeeper, acct_0);
	console.log("set template for ROPKeeper at address: ", addrROPKeeper, "\n");

	// ==== Books ====

	libraries = {
		"DTClaims": (await rc.getTemp(getTypeByName("DTClaims"), 1))[1],
		"FilesRepo": (await rc.getTemp(getTypeByName("FilesRepo"), 1))[1],
		"FRClaims": (await rc.getTemp(getTypeByName("FRClaims"), 1))[1],
		"TopChain": (await rc.getTemp(getTypeByName("TopChain"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROA = await deployTool(signers[0], "RegisterOfAgreements", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfAgreements"), addrROA, acct_0);
	console.log("Reg the RegisterOfAgreements:", addrROA, "in BookOfDocs \n");

	libraries = {
		"OfficersRepo": (await rc.getTemp(getTypeByName("OfficersRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROD = await deployTool(signers[0], "RegisterOfDirectors", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfDirectors"), addrROD, acct_0);
	console.log("Reg the RegisterOfDirectors:", addrROD, "in BookOfDocs \n");

	libraries = {
		"MotionsRepo": (await rc.getTemp(getTypeByName("MotionsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrMM = await deployTool(signers[0], "MeetingMinutes", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("MeetingMinutes"), addrMM, acct_0);
	console.log("Reg the MeetingMinutes:", addrMM, "in BookOfDocs \n");

	libraries = {
		"FilesRepo": (await rc.getTemp(getTypeByName("FilesRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROC = await deployTool(signers[0], "RegisterOfConstitution", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfConstitution"), addrROC, acct_0);
	console.log("Reg the RegisterOfConstitution:", addrROC, "in BookOfDocs \n");

	libraries = {
		"OptionsRepo": (await rc.getTemp(getTypeByName("OptionsRepo"), 1))[1],
		"SwapsRepo": (await rc.getTemp(getTypeByName("SwapsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROO = await deployTool(signers[0], "RegisterOfOptions", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfOptions"), addrROO, acct_0);
	console.log("Reg the RegisterOfOptions:", addrROO, "in BookOfDocs \n");

	libraries = {
		"PledgesRepo": (await rc.getTemp(getTypeByName("PledgesRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROP = await deployTool(signers[0], "RegisterOfPledges", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfPledges"), addrROP, acct_0);
	console.log("Reg the RegisterOfPledges:", addrROP, "in BookOfDocs \n");

	libraries = {
		"LockersRepo": (await rc.getTemp(getTypeByName("LockersRepo"), 1))[1],
		"SharesRepo": (await rc.getTemp(getTypeByName("SharesRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROS = await deployTool(signers[0], "RegisterOfShares", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfShares"), addrROS, acct_0);
	console.log("Reg the RegisterOfShares:", addrROS, "in BookOfDocs \n");

	libraries = {
		"Checkpoints": (await rc.getTemp(getTypeByName("Checkpoints"), 1))[1],
		"MembersRepo": (await rc.getTemp(getTypeByName("MembersRepo"), 1))[1],
		"TopChain": (await rc.getTemp(getTypeByName("TopChain"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROM = await deployTool(signers[0], "RegisterOfMembers", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfMembers"), addrROM, acct_0);
	console.log("Reg the RegisterOfMembers:", addrROM, "in BookOfDocs \n");

	libraries = {
		"InvestorsRepo": (await rc.getTemp(getTypeByName("InvestorsRepo"), 1))[1],
		"EnumerableSet": (await rc.getTemp(getTypeByName("EnumerableSet"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROI = await deployTool(signers[0], "RegisterOfInvestors", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfInvestors"), addrROI, acct_0);
	console.log("Reg the RegisterOfInvestors:", addrROI, "in BookOfDocs \n");

	libraries = {
		"UsdOrdersRepo": (await rc.getTemp(getTypeByName("UsdOrdersRepo"), 1))[1],
		"GoldChain": (await rc.getTemp(getTypeByName("GoldChain"), 1))[1],
		"EnumerableSet": (await rc.getTemp(getTypeByName("EnumerableSet"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrLOO = await deployTool(signers[0], "ListOfOrders", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("ListOfOrders"), addrLOO, acct_0);
	console.log("Reg the ListOfOrders:", addrLOO, "in BookOfDocs \n");

	libraries = {
		"RulesParser": (await rc.getTemp(getTypeByName("RulesParser"), 1))[1],
		"WaterfallsRepo": (await rc.getTemp(getTypeByName("WaterfallsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrCashier = await deployTool(signers[0], "Cashier", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("Cashier"), addrCashier, acct_0);
	console.log("Reg the Cashier:", addrCashier, "in BookOfDocs \n");

	libraries = {
		"RedemptionsRepo": (await rc.getTemp(getTypeByName("RedemptionsRepo"), 1))[1],
		"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	}
	const addrROR = await deployTool(signers[0], "RegisterOfRedemptions", libraries, params);
	await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfRedemptions"), addrROR, acct_0);
	console.log("Reg the RegisterOfRedemptions:", addrROR, "in BookOfDocs \n");
	
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
