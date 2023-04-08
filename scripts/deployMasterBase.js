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
	const libEnumerableSet = await deployTool(signers[0], "EnumerableSet", libraries);
	const libDelegateMap = await deployTool(signers[0], "DelegateMap", libraries);
	const libFRClaims = await deployTool(signers[0], "FRClaims", libraries);
	const libRolesRepo = await deployTool(signers[0], "RolesRepo", libraries);
	const libRulesParser = await deployTool(signers[0], "RulesParser", libraries);
	const libTopChain = await deployTool(signers[0], "TopChain", libraries);
		
	libraries = {
		"EnumerableSet": libEnumerableSet.address
	};
	
	const libCondsRepo = await deployTool(signers[0], "CondsRepo", libraries);
	const libDealsRepo = await deployTool(signers[0], "DealsRepo", libraries);
	const libDTClaims = await deployTool(signers[0], "DTClaims", libraries);
	const libLockersRepo = await deployTool(signers[0], "LockersRepo", libraries);
	const libPledgesRepo = await deployTool(signers[0], "PledgesRepo", libraries);
	const libSigsRepo = await deployTool(signers[0], "SigsRepo", libraries);
	const libSwapsRepo = await deployTool(signers[0], "SwapsRepo", libraries);
	const libDocsRepo = await deployTool(signers[0], "DocsRepo", libraries);


	libraries = {
		"LockersRepo": libLockersRepo.address
	};

	const libUsersRepo = await deployTool(signers[0], "UsersRepo", libraries);

	libraries = {
		"BallotsBox": libBallotsBox.address,
		"EnumerableSet": libEnumerableSet.address
	};

	const libMotionsRepo = await deployTool(signers[0], "MotionsRepo", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address
	};

	const libSharesRepo = await deployTool(signers[0], "SharesRepo", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"Checkpoints": libCheckpoints.address,
		"CondsRepo": libCondsRepo.address
	};

	const libOptionsRepo = await deployTool(signers[0], "OptionsRepo", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"SharesRepo": libSharesRepo.address,
		"TopChain": libTopChain.address
	};

	const libMembersRepo = await deployTool(signers[0], "MembersRepo", libraries);
	
	// ==== Deploy RegCenter ====
	libraries = {
		"DocsRepo": libDocsRepo.address,
		"UsersRepo": libUsersRepo.address
	};
	const rc = await deployTool(signers[0], "RegCenter", libraries);

	// ==== Deploy Templates ====
	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"DealsRepo": libDealsRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};

	const ia = await deployTool(signers[0], "InvestmentAgreement", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};
	const sha = await deployTool(signers[0], "ShareholdersAgreement", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
	};
	const ad = await deployTool(signers[0], "AntiDilution", libraries);
	const lu = await deployTool(signers[0], "LockUp", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address
	};
	const da = await deployTool(signers[0], "DragAlong", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address
	};
	const ta = await deployTool(signers[0], "TagAlong", libraries);
	
	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"OptionsRepo": libOptionsRepo.address
	};
	const op = await deployTool(signers[0], "Options", libraries);

	// ==== Keepers ====

	libraries = {
		"RolesRepo": libRolesRepo.address			
	}
	const gk = await deployTool(signers[0], "GeneralKeeper", libraries);
	await gk.init(0, signers[0].address, rc.address, gk.address);
	console.log("GeneralKeeper Initialzed \n");

	// ---- BOAKeeper 0 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	const boaKeeper = await deployTool(signers[0], "BOAKeeper", libraries);
	await boaKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("BOAKeeper Initialzed");		
	await gk.setBookeeper(0, boaKeeper.address);
	console.log("BOAKeeper registered with GeneralKeeper\n");

	// ---- BODKeeper 1 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	const bodKeeper = await deployTool(signers[0], "BODKeeper", libraries);
	await bodKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("BODKeeper Initialzed");
	await gk.setBookeeper(1, bodKeeper.address);
	console.log("BODKeeper registered with GeneralKeeper\n");

	// ---- BOGKeeper 2 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	const bogKeeper = await deployTool(signers[0], "BOGKeeper", libraries);
	await bogKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("BOGKeeper Initialzed");
	await gk.setBookeeper(2, bogKeeper.address);
	console.log("BOGKeeper registered with GeneralKeeper\n");

	// ---- BOHKeeper 3 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	const bohKeeper = await deployTool(signers[0], "BOHKeeper", libraries);
	await bohKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("BOHKeeper Initialzed");		
	await gk.setBookeeper(3, bohKeeper.address);
	console.log("BOHKeeper registered with GeneralKeeper\n");

	// ---- BOOKeeper 4 ----
	libraries = {
		"RolesRepo": libRolesRepo.address			
	}
	const booKeeper = await deployTool(signers[0], "BOOKeeper", libraries);
	await booKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("BOOKeeper Initialzed");
	await gk.setBookeeper(4, booKeeper.address);
	console.log("BOOKeeper registered with GeneralKeeper\n");

	// ---- BOPKeeper 5 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"PledgesRepo": libPledgesRepo.address
	}
	const bopKeeper = await deployTool(signers[0], "BOPKeeper", libraries);
	await bopKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("BOPKeeper Initialzed");		
	await gk.setBookeeper(5, bopKeeper.address);
	console.log("BOPKeeper registered with GeneralKeeper\n");

	// ---- BOSKeeper 6 ----
	libraries = {
		"RolesRepo": libRolesRepo.address			
	}
	const bosKeeper = await deployTool(signers[0], "BOSKeeper", libraries);
	await bosKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("BOSKeeper Initialzed");
	await gk.setBookeeper(6, bosKeeper.address);
	console.log("BOSKeeper registered with GeneralKeeper\n");

	// ---- ROMKeeper 7 ----
	libraries = {
		"RolesRepo": libRolesRepo.address			
	}
	const romKeeper = await deployTool(signers[0], "ROMKeeper", libraries);
	await romKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("ROMKeeper Initialzed");
	await gk.setBookeeper(7, romKeeper.address);
	console.log("ROMKeeper registered with GeneralKeeper\n");

	// ---- SHAKeeper 8 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address		
	}
	const shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries);
	await shaKeeper.init(0, gk.address, rc.address, gk.address);
	console.log("SHAKeeper Initialzed");		
	await gk.setBookeeper(8, shaKeeper.address);
	console.log("SHAKeeper registered with GeneralKeeper\n");

	// ==== Books ====

	// ---- BOA 0 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"DTClaims": libDTClaims.address,
		"EnumerableSet": libEnumerableSet.address,
		"FRClaims": libFRClaims.address,
		"RulesParser": libRulesParser.address,
		"TopChain": libTopChain.address
	}
	const boa = await deployTool(signers[0], "BookOfIA", libraries);
	await boa.init(0, boaKeeper.address, rc.address, gk.address);
	console.log("BookOfIA Initialzed");		
	await gk.setBook(0, boa.address);
	console.log("BookOfIA registered with GeneralKeeper\n");

	// ---- BOD 1 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"DelegateMap": libDelegateMap.address,
		"EnumerableSet": libEnumerableSet.address,
		"MotionsRepo": libMotionsRepo.address,
		"RulesParser": libRulesParser.address
	}
	const bod = await deployTool(signers[0], "BookOfDirectors", libraries);
	await bod.init(0, bodKeeper.address, rc.address, gk.address);
	console.log("BookOfDirectors Initialzed");		
	await gk.setBook(1, bod.address);
	console.log("BookOfDirectors registered with GeneralKeeper\n");

	// ---- BOG 2 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"DelegateMap": libDelegateMap.address,
		"EnumerableSet": libEnumerableSet.address,
		"MotionsRepo": libMotionsRepo.address,
		"RulesParser": libRulesParser.address
	}
	const bog = await deployTool(signers[0], "BookOfGM", libraries);
	await bog.init(0, bogKeeper.address, rc.address, gk.address);
	console.log("BookOfGM Initialzed");		
	await gk.setBook(2, bog.address);
	console.log("BookOfGM registered with GeneralKeeper\n");

	// ---- BOH 3 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"EnumerableSet": libEnumerableSet.address
	}
	const boh = await deployTool(signers[0], "BookOfSHA", libraries);
	await boh.init(0, shaKeeper.address, rc.address, gk.address);
	console.log("BookOfSHA Initialzed");		
	await gk.setBook(3, boh.address);
	console.log("BookOfSHA registered with GeneralKeeper\n");

	// ---- BOO 4 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"OptionsRepo": libOptionsRepo.address
	}
	const boo = await deployTool(signers[0], "BookOfOptions", libraries);
	await boo.init(0, booKeeper.address, rc.address, gk.address);
	console.log("BookOfOptions Initialzed");		
	await gk.setBook(4, boo.address);
	console.log("BookOfOptions registered with GeneralKeeper\n");

	// ---- BOP 5 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"PledgesRepo": libPledgesRepo.address
	}
	const bop = await deployTool(signers[0], "BookOfPledges", libraries);
	await bop.init(0, bopKeeper.address, rc.address, gk.address);
	console.log("BookOfPledges Initialzed");		
	await gk.setBook(5, bop.address);
	console.log("BookOfPledges registered with GeneralKeeper\n");

	// ---- BOS 6 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"LockersRepo": libLockersRepo.address,
		"SharesRepo": libSharesRepo.address
	}
	const bos = await deployTool(signers[0], "BookOfShares", libraries);
	await bos.init(0, bosKeeper.address, rc.address, gk.address);
	console.log("BookOfShares Initialzed");
	await gk.setBook(6, bos.address);
	console.log("BookOfShares registered with GeneralKeeper\n");

	// ---- ROM 7 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"MembersRepo": libMembersRepo.address,
		"TopChain": libTopChain.address
	}
	const rom = await deployTool(signers[0], "RegisterOfMembers", libraries);
	await rom.init(0, romKeeper.address, rc.address, gk.address);
	console.log("RegisterOfMembers Initialzed");
	await gk.setBook(7, rom.address);
	console.log("RegisterOfMembers registered with GeneralKeeper\n");

	// ---- ROS 8 ----
	libraries = {
		"RolesRepo": libRolesRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"SwapsRepo": libSwapsRepo.address
	}
	const ros = await deployTool(signers[0], "RegisterOfSwaps", libraries);
	await ros.init(0, shaKeeper.address, rc.address, gk.address);
	console.log("RegisterOfSwaps Initialzed");
	await gk.setBook(8, ros.address);
	console.log("RegisterOfSwaps registered with GeneralKeeper\n");
	
	// ==== 0 BOAKeeper BooksRuting ====
	await boaKeeper.initBOA();
	await boaKeeper.initBOD();
	await boaKeeper.initBOG();
	await boaKeeper.initBOH();
	await boaKeeper.initBOS();
	await boaKeeper.initROM();
	console.log("BOAKeeper linked Books \n");

	// ==== 1 BODKeeper BooksRuting ====
	await bodKeeper.initBOD();
	await bodKeeper.initBOG();
	await bodKeeper.initBOH();
	console.log("BODKeeper linked Books \n");

	// ==== 2 BOGKeeper BooksRuting ====
	await bogKeeper.initBOA();
	await bogKeeper.initBOD();
	await bogKeeper.initBOG();
	await bogKeeper.initBOH();
	await bogKeeper.initBOO();
	await bogKeeper.initBOS();
	await bogKeeper.initROM();
	await bogKeeper.initROS();
	console.log("BOGKeeper linked Books \n");

	// ==== 3 BOHKeeper BooksRuting ====
	await bohKeeper.initBOD();
	await bohKeeper.initBOH();
	await bohKeeper.initBOO();
	await bohKeeper.initBOS();
	await bohKeeper.initROM();
	console.log("BOHKeeper linked Books \n");

	// ==== 4 BOOKeeper BooksRuting ====
	await booKeeper.initBOO();
	await booKeeper.initROS();
	console.log("BOOKeeper linked Books \n");

	// ==== 5 BOPKeeper BooksRuting ====
	await bopKeeper.initBOP();
	await bopKeeper.initBOS();
	console.log("BOPKeeper linked Books \n");

	// ==== 6 BOSKeeper BooksRuting ====
	await bosKeeper.initBOS();
	console.log("BOSKeeper linked Books \n");

	// ==== 7 ROMKeeper BooksRuting ====
	await romKeeper.initROM();
	console.log("ROMKeeper linked Books \n");	

	// ==== 8 SHAKeeper BooksRuting ====
	await shaKeeper.initBOA();
	await shaKeeper.initBOH();
	await shaKeeper.initBOS();
	await shaKeeper.initROM();
	console.log("SHAKeeper linked Books \n");	

	// ==== 0 BOA BooksRuting ====
	await boa.initBOH();
	await boa.initROM();
	await boa.initBOS();
	console.log("BOA linked Books \n");	

	// ==== 1 BOD BooksRuting ====
	await bod.initBOD();
	await bod.initBOH();
	await bod.initROM();
	console.log("BOD linked Books \n");	

	// ==== 2 BOG BooksRuting ====
	await bog.initBOD();
	await bog.initBOH();
	await bog.initROM();
	console.log("BOG linked Books \n");	

	// ==== 3 BOH BooksRuting ====
	console.log("BOH has no Books to link \n");	

	// ==== 4 BOO BooksRuting ====
	await boo.initBOS();
	await boo.initROS();
	console.log("BOO linked Books \n");	

	// ==== 5 BOP BooksRuting ====
	await bop.initBOS();
	console.log("BOP linked Books \n");	

	// ==== 6 BOS BooksRuting ====
	await bos.initROM();
	console.log("BOS linked Books \n");	

	// ==== 7 ROM BooksRuting ====
	await rom.initBOS();
	console.log("ROM linked Books \n");	

	// ==== 8 ROS BooksRuting ====
	await ros.initBOS();
	await ros.initROM();
	console.log("ROS linked Books \n");	
	

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
