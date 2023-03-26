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
	let libArrayUtils = await deployTool(deployer, "ArrayUtils", libraries);
	let libBallotsBox = await deployTool(deployer, "BallotsBox", libraries);
	let libCheckpoints = await deployTool(deployer, "Checkpoints", libraries);
	let libEnumerableSet = await deployTool(deployer, "EnumerableSet", libraries);
	let libDelegateMap = await deployTool(deployer, "DelegateMap", libraries);
	let libFRClaims = await deployTool(deployer, "FRClaims", libraries);
	let libRolesRepo = await deployTool(deployer, "RolesRepo", libraries);
	let libRulesParser = await deployTool(deployer, "RulesParser", libraries);
	let libTopChain = await deployTool(deployer, "TopChain", libraries);
		
	libraries = {
		"EnumerableSet": libEnumerableSet.address
	};
	
	let libCondsRepo = await deployTool(deployer, "CondsRepo", libraries);
	let libDealsRepo = await deployTool(deployer, "DealsRepo", libraries);
	let libDTClaims = await deployTool(deployer, "DTClaims", libraries);
	let libLockersRepo = await deployTool(deployer, "LockersRepo", libraries);
	let libPledgesRepo = await deployTool(deployer, "PledgesRepo", libraries);
	let libSigsRepo = await deployTool(deployer, "SigsRepo", libraries);
	let libSwapsRepo = await deployTool(deployer, "SwapsRepo", libraries);

	libraries = {
		"BallotsBox": libBallotsBox.address
	};

	let libMotionsRepo = await deployTool(deployer, "MotionsRepo", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address
	};

	let libSharesRepo = await deployTool(deployer, "SharesRepo", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"Checkpoints": libCheckpoints.address,
		"CondsRepo": libCondsRepo.address
	};

	let libOptionsRepo = await deployTool(deployer, "OptionsRepo", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"Checkpoints": libCheckpoints.address,
		"EnumerableSet": libEnumerableSet.address,
		"SharesRepo": libSharesRepo.address,
		"TopChain": libTopChain.address
	};

	let libMembersRepo = await deployTool(deployer, "MembersRepo", libraries);
	
	// ==== RegCenter ====
	libraries = {
		"LockersRepo": libLockersRepo.address
	};
	let rc = await deployTool(deployer, "RegCenter", libraries);

	// ==== Templates ====
	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"DealsRepo": libDealsRepo.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};

	let ia = await deployTool(deployer, "InvestmentAgreement", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"SigsRepo": libSigsRepo.address
	};
	let sha = await deployTool(deployer, "ShareholdersAgreement", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
	};
	let ad = await deployTool(deployer, "AntiDilution", libraries);
	let lu = await deployTool(deployer, "LockUp", libraries);

	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address
	};
	let da = await deployTool(deployer, "DragAlong", libraries);

	libraries = {
		"ArrayUtils": libArrayUtils.address,
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"RulesParser": libRulesParser.address
	};
	let ta = await deployTool(deployer, "TagAlong", libraries);
	
	libraries = {
		"EnumerableSet": libEnumerableSet.address,
		"RolesRepo": libRolesRepo.address,
		"OptionsRepo": libOptionsRepo.address
	};
	let op = await deployTool(deployer, "Options", libraries);

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
