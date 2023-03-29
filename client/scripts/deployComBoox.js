const { ethers } = require("ethers");
const { contractGetter } = require("./contractGetter");
// const { deployTool } = require("./deployTool");

const provider = new ethers.getDefaultProvider();
console.log("obtained defaultProvider: ", provider);

const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const signer = new ethers.Wallet(privateKey, provider);

async function main() {
	// const signers = await ethers.getSigners();
	// console.log(
	// 	"Deploying the contracts with the account:",
	// 	signers[0].address
	// );

	// console.log("Account balance:", (await signers[0].getBalance()).toString());

	// const signer = await provider.getSigner();
	// console.log("obtianed Web3Signer:", signer);

	let rc = await contractGetter("RegCenter", provider);
	// let res;


	// ==== Libraries ====

	let libBallotsBox = await contractGetter("BallotsBox", provider);
	let libCheckpoints = await contractGetter("Checkpoints", provider);
	let libDelegateMap = await contractGetter("DelegateMap", provider);
	let libDTClaims = await contractGetter("DTClaims", provider);
	let libEnumerableSet = await contractGetter("EnumerableSet", provider);
	let libFRClaims = await contractGetter("FRClaims", provider);

	let libLockersRepo = await contractGetter("LockersRepo", provider);
	let libMembersRepo = await contractGetter("MembersRepo", provider);
	let libMotionsRepo = await contractGetter("MotionsRepo", provider);
	let libOptionsRepo = await contractGetter("OptionsRepo", provider);

	let libPledgesRepo = await contractGetter("PledgesRepo", provider);
	let libRolesRepo = await contractGetter("RolesRepo", provider);
	let libRulesParser = await contractGetter("RulesParser", provider);
	let libSharesRepo = await contractGetter("SharesRepo", provider);
	let libSwapsRepo = await contractGetter("SwapsRepo", provider);
	let libTopChain = await contractGetter("TopChain", provider);

	// ==== Templates ====

	let ia = await contractGetter("InvestmentAgreement", provider);

	let sha = await contractGetter("ShareholdersAgreement", provider);
	let ad = await contractGetter("AntiDilution", provider);
	let lu = await contractGetter("LockUp", provider);
	let da = await contractGetter("DragAlong", provider);
	let ta = await contractGetter("TagAlong", provider);
	let op = await contractGetter("Options", provider);

	// ==== Keepers ====

	let libraries = {
		"RolesRepo": libRolesRepo.address
	};

	let gk = await deployTool(signers[0], "GeneralKeeper", libraries);
	await gk.init(await rc.getMyUserNo(), signers[1].address, rc.address, gk.address);
	console.log("init GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"RulesParser": libRulesParser.address
	// };
	// let boaKeeper = await deployTool(signers[0], "BOAKeeper", libraries);
	// await boaKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init BOAKeeper");
	// await gk.connect(signers[1]).setBookeeper(0, boaKeeper.address);
	// console.log("reg BOAKeeper with GeneralKeeper");

	// let bodKeeper = await deployTool(signers[0], "BODKeeper", libraries);
	// await bodKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init BODKeeper");
	// await gk.connect(signers[1]).setBookeeper(1, bodKeeper.address);
	// console.log("reg BODKeeper with GeneralKeeper");

	// let bogKeeper = await deployTool(signers[0], "BOGKeeper", libraries);
	// await bogKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init BOGKeeper");
	// await gk.connect(signers[1]).setBookeeper(2, bogKeeper.address);
	// console.log("reg BOGKeeper with GeneralKeeper");

	// let bohKeeper = await deployTool(signers[0], "BOHKeeper", libraries);
	// await bohKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init BOHKeeper");
	// await gk.connect(signers[1]).setBookeeper(3, bohKeeper.address);
	// console.log("reg BOHKeeper with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address
	// };

	// let booKeeper = await deployTool(signers[0], "BOOKeeper", libraries);
	// await booKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init BOOKeeper");
	// await gk.connect(signers[1]).setBookeeper(4, booKeeper.address);
	// console.log("reg BOOKeeper with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"PledgesRepo": libPledgesRepo.address
	// };

	// let bopKeeper = await deployTool(signers[0], "BOPKeeper", libraries);
	// await bopKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init BOPKeeper");
	// await gk.connect(signers[1]).setBookeeper(5, bopKeeper.address);
	// console.log("reg BOPKeeper with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// };

	// let bosKeeper = await deployTool(signers[0], "BOSKeeper", libraries);
	// await bosKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init BOSKeeper");
	// await gk.connect(signers[1]).setBookeeper(6, bosKeeper.address);
	// console.log("reg BOSKeeper with GeneralKeeper");

	// let romKeeper = await deployTool(signers[0], "ROMKeeper", libraries);
	// await romKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init ROMKeeper");
	// await gk.connect(signers[1]).setBookeeper(7, romKeeper.address);
	// console.log("reg ROMKeeper with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"RulesParser": libRulesParser.address
	// };

	// let shaKeeper = await deployTool(signers[0], "SHAKeeper", libraries);
	// await shaKeeper.init(await rc.getMyUserNo(), gk.address, rc.address, gk.address);
	// console.log("init SHAKeeper");
	// await gk.connect(signers[1]).setBookeeper(8, shaKeeper.address);
	// console.log("reg SHAKeeper with GeneralKeeper");

	// // ==== Books ====

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"DTClaims": libDTClaims.address,
	// 	"EnumerableSet": libEnumerableSet.address,
	// 	"FRClaims": libFRClaims.address,
	// 	"RulesParser": libRulesParser.address,
	// 	"TopChain": libTopChain.address
	// };

	// let boa = await deployTool(signers[0], "BookOfIA", libraries);
	// await boa.init(await rc.getMyUserNo(), boaKeeper.address, rc.address, gk.address);
	// console.log("init BookOfIA");
	// await gk.connect(signers[1]).setBook(0, boa.address);
	// console.log("reg BookOfIA with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"DelegateMap": libDelegateMap.address,
	// 	"EnumerableSet": libEnumerableSet.address,
	// 	"MotionsRepo": libMotionsRepo.address,
	// 	"RulesParser": libRulesParser.address
	// };

	// let bod = await deployTool(signers[0], "BookOfDirectors", libraries);
	// await bod.init(await rc.getMyUserNo(), bodKeeper.address, rc.address, gk.address);
	// console.log("init BookOfDirectors");
	// await gk.connect(signers[1]).setBook(1, bod.address);
	// console.log("reg BookOfDirectors with GeneralKeeper");

	// let bog = await deployTool(signers[0], "BookOfGM", libraries);
	// await bog.init(await rc.getMyUserNo(), bogKeeper.address, rc.address, gk.address);
	// console.log("init BookOfGM");
	// await gk.connect(signers[1]).setBook(2, bog.address);
	// console.log("reg BookOfGM with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"EnumerableSet": libEnumerableSet.address
	// };

	// let boh = await deployTool(signers[0], "BookOfSHA", libraries);
	// await boh.init(await rc.getMyUserNo(), bohKeeper.address, rc.address, gk.address);
	// console.log("init BookOfSHA");
	// await gk.connect(signers[1]).setBook(3, boh.address);
	// console.log("reg BookOfSHA with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"Checkpoints": libCheckpoints.address,
	// 	"EnumerableSet": libEnumerableSet.address,
	// 	"OptionsRepo": libOptionsRepo.address
	// };

	// let boo = await deployTool(signers[0], "BookOfOptions", libraries);
	// await boo.init(await rc.getMyUserNo(), booKeeper.address, rc.address, gk.address);
	// console.log("init BookOfOptions");
	// await gk.connect(signers[1]).setBook(4, boo.address);
	// console.log("reg BookOfOptions with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"PledgesRepo": libPledgesRepo.address
	// };

	// let bop = await deployTool(signers[0], "BookOfPledges", libraries);
	// await bop.init(await rc.getMyUserNo(), bopKeeper.address, rc.address, gk.address);
	// console.log("init BookOfPledges");
	// await gk.connect(signers[1]).setBook(5, bop.address);
	// console.log("reg BookOfPledges with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"LockersRepo": libLockersRepo.address,
	// 	"SharesRepo": libSharesRepo.address
	// };

	// let bos = await deployTool(signers[0], "BookOfShares", libraries);
	// await bos.init(await rc.getMyUserNo(), bosKeeper.address, rc.address, gk.address);
	// console.log("init BookOfShares");
	// await gk.connect(signers[1]).setBook(6, bos.address);
	// console.log("reg BookOfShares with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"Checkpoints": libCheckpoints.address,
	// 	"EnumerableSet": libEnumerableSet.address,
	// 	"MembersRepo": libMembersRepo.address,
	// 	"TopChain": libTopChain.address
	// };

	// let rom = await deployTool(signers[0], "RegisterOfMembers", libraries);
	// await rom.init(await rc.getMyUserNo(), romKeeper.address, rc.address, gk.address);
	// console.log("init RegisterOfMembers");
	// await gk.connect(signers[1]).setBook(7, rom.address);
	// console.log("reg RegisterOfMembers with GeneralKeeper");

	// libraries = {
	// 	"RolesRepo": libRolesRepo.address,
	// 	"EnumerableSet": libEnumerableSet.address,
	// 	"SwapsRepo": libSwapsRepo.address
	// };

	// let ros = await deployTool(signers[0], "RegisterOfSwaps", libraries);
	// await ros.init(await rc.getMyUserNo(), booKeeper.address, rc.address, gk.address);
	// console.log("init RegisterOfSwaps");
	// await gk.connect(signers[1]).setBook(8, ros.address);
	// console.log("reg RegisterOfSwaps with GeneralKeeper");

	// // ==== Init Books & Keepers ====
	// await boaKeeper.initBOA();
	// await boaKeeper.initBOD();
	// await boaKeeper.initBOG();
	// await boaKeeper.initBOH();
	// await boaKeeper.initBOS();
	// await boaKeeper.initROM();
	// console.log("initiate BOAKeeper");

	// await bodKeeper.initBOD();
	// await bodKeeper.initBOG();
	// await bodKeeper.initBOH();
	// console.log("initiate BODKeeper");

	// await bogKeeper.initBOA();
	// await bogKeeper.initBOD();
	// await bogKeeper.initBOG();
	// await bogKeeper.initBOH();
	// await bogKeeper.initBOO();
	// await bogKeeper.initBOS();
	// await bogKeeper.initROM();
	// await bogKeeper.initROS();
	// console.log("initiate BOGKeeper");

	// await bohKeeper.initBOD();
	// await bohKeeper.initBOH();
	// await bohKeeper.initBOO();
	// await bohKeeper.initBOS();
	// await bohKeeper.initROM();
	// console.log("initiate BOHKeeper");

	// await booKeeper.initBOO();
	// await booKeeper.initROS();
	// console.log("initiate BOOKeeper");

	// await bopKeeper.initBOP();
	// await bopKeeper.initBOS();
	// console.log("initiate BOPKeeper");

	// await bosKeeper.initBOS();
	// console.log("initiate BOSKeeper");

	// await romKeeper.initROM();
	// console.log("initiate ROMKeeper");

	// await shaKeeper.initBOA();
	// await shaKeeper.initBOH();
	// await shaKeeper.initBOS();
	// await shaKeeper.initROM();
	// console.log("initiate SHAKeeper");

	// // ==== Templates ====

	// await gk.connect(signers[1]).setTempOfIA(ia.address, 0);
	// console.log("setTemplate of ia");

	// await gk.connect(signers[1]).setTempOfBOH(sha.address, 0);
	// console.log("setTemplate of sha");
	// await gk.connect(signers[1]).setTempOfBOH(lu.address, 1);
	// console.log("setTemplate of lockUp");
	// await gk.connect(signers[1]).setTempOfBOH(ad.address, 2);
	// console.log("setTemplate of AntiDilution");
	// await gk.connect(signers[1]).setTempOfBOH(da.address, 3);
	// console.log("setTemplate of DragAlong");
	// await gk.connect(signers[1]).setTempOfBOH(ta.address, 4);
	// console.log("setTemplate of TagAlong");
	// await gk.connect(signers[1]).setTempOfBOH(op.address, 5);
	// console.log("setTemplate of Options");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
