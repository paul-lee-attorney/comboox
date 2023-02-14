const hre = require("hardhat");
const { deployTool } = require("./deployTool");

async function main() {
	const [deployer] = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await deployer.getAddress()
	);

	console.log("Account balance:", (await deployer.getBalance()).toString());

	let libraries = {};

	// ==== Libraries ====		
	let libArrayUtils = await deployTool(deployer, "ArrayUtils", undefined);
	let libDelegateMap = await deployTool(deployer, "DelegateMap", undefined);
	let libEnumerableSet = await deployTool(deployer, "EnumerableSet", undefined);
	let libRolesRepo = await deployTool(deployer, "RolesRepo", undefined);
	let libSNParser = await deployTool(deployer, "SNParser", undefined);
	let libSNFactory = await deployTool(deployer, "SNFactory", undefined);
	let libTopChain = await deployTool(deployer, "TopChain", undefined);
	let libCheckpoints = await deployTool(deployer, "Checkpoints", undefined);

	libraries = {
		"EnumerableSet": libEnumerableSet.address
	};
	let libBallotsBox = await deployTool(deployer, "BallotsBox", libraries);
	let libSigsRepo = await deployTool(deployer, "SigsRepo", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"Checkpoints": libCheckpoints.address,
		"SNFactory": libSNFactory.address,
		"SNParser": libSNParser.address
	};
	let libOptionsRepo = await deployTool(deployer, "OptionsRepo", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"Checkpoints": libCheckpoints.address,
		"TopChain": libTopChain.address
	};
	let libMembersRepo = await deployTool(deployer, "MembersRepo", libraries);

	libraries = {
		"BallotsBox": libBallotsBox.address,
		"DelegateMap": libDelegateMap.address,
		"EnumerableSet": libEnumerableSet.address,
		"SNParser": libSNParser.address
	};
	let libMotionsRepo = await deployTool(deployer, "MotionsRepo", libraries);

	// ==== RegCenter ====
	libraries = {
		"SNParser": libSNParser.address
	};
	let rc = await deployTool(deployer, "RegCenter", libraries);

	// ==== Templates ====
	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SNParser": libSNParser.address
	};
	let ia = await deployTool(deployer, "InvestmentAgreement", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address
	};
	let frd = await deployTool(deployer, "FirstRefusalDeals", libraries);

	libraries = {
		"MembersRepo": libMembersRepo.address,
		"RolesRepo": libRolesRepo.address,
		"SNParser": libSNParser.address,
		"TopChain": libTopChain.address
	};
	let mr = await deployTool(deployer, "MockResults", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SNParser": libSNParser.address
	};
	let sha = await deployTool(deployer, "ShareholdersAgreement", libraries);

	libraries = {
		"RolesRepo": libRolesRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"SNParser": libSNParser.address
	};
	let da = await deployTool(deployer, "DragAlong", libraries);
	
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
