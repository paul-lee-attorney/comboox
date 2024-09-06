// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { addrs } = require("./addrs_240821_ArbiSepo");
const { readContract } = require("../../../scripts/readTool");

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
	// const libGoldChain = await deployTool(signers[0], "GoldChain", libraries, params);
	// const libInvestorsRepo = await deployTool(signers[0], "InvestorsRepo", libraries, params);

	const libGoldChain = await readContract("GoldChain", "0xBAFD7dF460b46f7942B4850f98eF161C6E313931");
	const libInvestorsRepo = await readContract("InvestorsRepo", "0xe4ea52d581BF8EB228006002025e68d5b84624Ca");

	// libraries = {
	// 	"GoldChain": libGoldChain.address,
	// };
	// const libOrdersRepo = await deployTool(signers[0], "OrdersRepo", libraries, params);

	const libOrdersRepo = await readContract("OrdersRepo", "0xf7754574D81AbB4aFd74847f2b0928eCBc77d44f");

	let rc = await readContract("RegCenter", addrs.RegCenter_2);
	console.log("get RegCenter at:", rc.address);

	// ==== Deploy Templates ====

	libraries = {
		"ArrayUtils": addrs.ArrayUtils,
		"DealsRepo": addrs.DealsRepo,
		"EnumerableSet": addrs.EnumerableSet,
		"RolesRepo": addrs.RolesRepo,
		"SigsRepo": addrs.SigsRepo,
		"SwapsRepo": addrs.SwapsRepo
	};
	let ia = await deployTool(signers[0], "InvestmentAgreement", libraries, params);

	libraries = {
		"ArrayUtils": addrs.ArrayUtils,
		"EnumerableSet": addrs.EnumerableSet,
		"RolesRepo": addrs.RolesRepo,
		"SigsRepo": addrs.SigsRepo
	};
	let sha = await deployTool(signers[0], "ShareholdersAgreement", libraries, params);

	libraries = {
		"EnumerableSet": addrs.EnumerableSet,
		"RolesRepo": addrs.RolesRepo
	};
	let ad = await deployTool(signers[0], "AntiDilution", libraries, params);

	libraries = {
		"ArrayUtils": addrs.ArrayUtils,
		"EnumerableSet": addrs.EnumerableSet,
		"RolesRepo": addrs.RolesRepo
	};
	let lu = await deployTool(signers[0], "LockUp", libraries, params);

	libraries = {
		"RolesRepo": addrs.RolesRepo,
		"LinksRepo": addrs.LinksRepo
	};
	let al = await deployTool(signers[0], "Alongs", libraries, params);
	
	libraries = {
		"EnumerableSet": addrs.EnumerableSet,
		"RolesRepo": addrs.RolesRepo,
		"OptionsRepo": addrs.OptionsRepo
	};
	let op = await deployTool(signers[0], "Options", libraries, params);

	// ==== Keepers ====

	libraries = {
		"Address": addrs.Address
	}
	let gk = await deployTool(signers[0], "GeneralKeeper", libraries, params);

	libraries = {}

	let rooKeeper = await deployTool(signers[0], "ROOKeeper", libraries, params);
	let romKeeper = await deployTool(signers[0], "ROMKeeper", libraries, params);
	let rodKeeper = await deployTool(signers[0], "RODKeeper", libraries, params);

	libraries = {
		"RulesParser": addrs.RulesParser		
	}
	let shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries, params);
	let looKeeper = await deployTool(signers[0], "LOOKeeper", libraries, params);

	libraries = {
		"ArrayUtils": addrs.ArrayUtils,
		"RulesParser": addrs.RulesParser		
	}
	let gmmKeeper = await deployTool(signers[0], "GMMKeeper", libraries, params);
	let bmmKeeper = await deployTool(signers[0], "BMMKeeper", libraries, params);

	libraries = {
		"DocsRepo": addrs.DocsRepo,
		"RulesParser": addrs.RulesParser		
	}
	let roaKeeper = await deployTool(signers[0], "ROAKeeper", libraries, params);

	libraries = {
		"ArrayUtils": addrs.ArrayUtils,
		"DocsRepo": addrs.DocsRepo,
		"RulesParser": addrs.RulesParser		
	}
	let rocKeeper = await deployTool(signers[0], "ROCKeeper", libraries, params);

	libraries = {
		"PledgesRepo": addrs.PledgesRepo,
	}
	let ropKeeper = await deployTool(signers[0], "ROPKeeper", libraries, params);

	// ==== Books ====

	libraries = {
		"DTClaims": addrs.DTClaims,
		"FilesRepo": addrs.FilesRepo,
		"FRClaims": addrs.FRClaims,
		"TopChain": addrs.TopChain
	}
	let roa = await deployTool(signers[0], "RegisterOfAgreements", libraries, params);

	libraries = {
		"OfficersRepo": addrs.OfficersRepo
	}
	let rod = await deployTool(signers[0], "RegisterOfDirectors", libraries, params);

	libraries = {
		"MotionsRepo": addrs.MotionsRepo
	}
	let mm = await deployTool(signers[0], "MeetingMinutes", libraries, params);

	libraries = {
		"FilesRepo": addrs.FilesRepo
	}
	let roc = await deployTool(signers[0], "RegisterOfConstitution", libraries, params);

	libraries = {
		"OptionsRepo": addrs.OptionsRepo,
		"SwapsRepo": addrs.SwapsRepo
	}
	let roo = await deployTool(signers[0], "RegisterOfOptions", libraries, params);

	libraries = {
		"PledgesRepo": addrs.PledgesRepo
	}
	let rop = await deployTool(signers[0], "RegisterOfPledges", libraries, params);

	libraries = {
		"LockersRepo": addrs.LockersRepo,
		"SharesRepo": addrs.SharesRepo
	}
	let ros = await deployTool(signers[0], "RegisterOfShares", libraries, params);

	libraries = {
		"MembersRepo": addrs.MembersRepo,
		"TopChain": addrs.TopChain
	}
	let rom = await deployTool(signers[0], "RegisterOfMembers", libraries, params);

	libraries = {
		"OrdersRepo": libOrdersRepo.address,
		"GoldChain": libGoldChain.address,
		"EnumerableSet": addrs.EnumerableSet,
		"InvestorsRepo": libInvestorsRepo.address,
	}
	let loo = await deployTool(signers[0], "ListOfOrders", libraries, params);

	libraries = {
		"TeamsRepo": addrs.TeamsRepo,
	};
	let lop = await deployTool(signers[0], "ListOfProjects", libraries, params);

	// ==== SetTemplate ====

	await rc.connect(signers[1]).setTemplate( 1, rocKeeper.address, 9);
	console.log("set template for ROCKeeper at address: ", rocKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 2, rodKeeper.address, 9);
	console.log("set template for RODKeeper at address: ", rodKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 3, bmmKeeper.address, 9);
	console.log("set template for BMMKeeper at address: ", bmmKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 4, romKeeper.address, 9);
	console.log("set template for ROMKeeper at address: ", romKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 5, gmmKeeper.address, 9);
	console.log("set template for GMMKeeper at address: ", gmmKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 6, roaKeeper.address, 9);
	console.log("set template for ROAKeeper at address: ", roaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 7, rooKeeper.address, 9);
	console.log("set template for ROOKeeper at address: ", rooKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 8, ropKeeper.address, 9);
	console.log("set template for ROPKeeper at address: ", ropKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 9, shaKeeper.address, 9);
	console.log("set template for SHAKeeper at address: ", shaKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 10, looKeeper.address, 9);
	console.log("set template for LOOKeeper at address: ", looKeeper.address, "\n");

	await rc.connect(signers[1]).setTemplate( 11, roc.address, 9);
	console.log("set template for ROC at address: ", roc.address, "\n");

	await rc.connect(signers[1]).setTemplate( 12, rod.address, 9);
	console.log("set template for ROD at address: ", rod.address, "\n");

	await rc.connect(signers[1]).setTemplate( 13, mm.address, 9);
	console.log("set template for MM at address: ", mm.address, "\n");

	await rc.connect(signers[1]).setTemplate( 14, rom.address, 9);
	console.log("set template for ROM at address: ", rom.address, "\n");

	await rc.connect(signers[1]).setTemplate( 15, roa.address, 9);
	console.log("set template for ROA at address: ", roa.address, "\n");

	await rc.connect(signers[1]).setTemplate( 16, roo.address, 9);
	console.log("set template for ROO at address: ", roo.address, "\n");

	await rc.connect(signers[1]).setTemplate( 17, rop.address, 9);
	console.log("set template for ROP at address: ", rop.address, "\n");

	await rc.connect(signers[1]).setTemplate( 18, ros.address, 9);
	console.log("set template for ROS at address: ", ros.address, "\n");

	await rc.connect(signers[1]).setTemplate( 19, loo.address, 9);
	console.log("set template for LOO at address: ", loo.address, "\n");

	await rc.connect(signers[1]).setTemplate( 20, gk.address, 9);
	console.log("set template for GK at address: ", gk.address, "\n");

	await rc.connect(signers[1]).setTemplate( 21, ia.address, 9);
	console.log("set template for IA at address: ", ia.address, "\n");

	await rc.connect(signers[1]).setTemplate( 22, sha.address, 9);
	console.log("set template for SHA at address: ", sha.address, "\n");

	await rc.connect(signers[1]).setTemplate( 23, ad.address, 9);
	console.log("set template for AD at address: ", ad.address, "\n");

	await rc.connect(signers[1]).setTemplate( 24, lu.address, 9);
	console.log("set template for LU at address: ", lu.address, "\n");

	await rc.connect(signers[1]).setTemplate( 25, al.address, 9);
	console.log("set template for AL at address: ", al.address, "\n");

	await rc.connect(signers[1]).setTemplate( 26, op.address, 9);
	console.log("set template for OP at address: ", op.address, "\n");

	await rc.connect(signers[1]).setTemplate( 27, lop.address, 9);
	console.log("set template for LOP at address: ", lop.address, "\n");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
