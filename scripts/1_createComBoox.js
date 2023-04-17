const hre = require("hardhat");
const { contractGetter, tempAddrGetter } = require("./contractGetter");
const { saveGKAddr } = require("./deployTool");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Create ComBoox with the account:",
		signers[2].address
	);

	console.log("Account balance:", (await signers[2].getBalance()).toString());

	let rc = await contractGetter("RegCenter", await tempAddrGetter("RegCenter"));

	const acct2 = await rc.connect(signers[2]).getMyUserNo();
	console.log("owner's userNo: ", acct2);

	const acct3 = await rc.connect(signers[3]).getMyUserNo();
	console.log("bookeeper's address: ", signers[3].address);
	console.log("bookeeper's userNo: ", acct3);

	// ==== Crate Comp ====

	let logs;
	let info = {};

  await rc.connect(signers[2]).createComp(signers[3].address);
	logs = await rc.queryFilter("CreateComp", "latest");

	logs.map((v) => {
		if (v.args["creator"] == acct2) {
			info.seqOfDoc = v.args["seqOfDoc"].toNumber();
			info.address = v.args["generalKeeper"];
			saveGKAddr(info.seqOfDoc, info.address);
			console.log("Created Comapny:" , info.seqOfDoc, "with GK at:", info.address);
		} 
	});

	const artOfGK = hre.artifacts.readArtifactSync("GeneralKeeper");
	let gk = await hre.ethers.getContractAt(artOfGK.abi, logs[0].args["generalKeeper"]);
	console.log("obtained gk at address:", gk.address);

	console.log("BOA: ", await gk.getBOA());
	console.log("BOD: ", await gk.getBOD());
	console.log("BOG: ", await gk.getBOG());
	console.log("BOH: ", await gk.getBOH());
	console.log("SHA: ", await gk.getSHA());
	console.log("BOO: ", await gk.getBOD());
	console.log("BOP: ", await gk.getBOP());
	console.log("BOS: ", await gk.getBOS());
	console.log("ROM: ", await gk.getROM());
	console.log("ROS: ", await gk.getROS());

	console.log("BOAKeeper: ", await gk.getKeeper(1));
	console.log("BODKeeper: ", await gk.getKeeper(2));
	console.log("BOGKeeper: ", await gk.getKeeper(3));
	console.log("BOHKeeper: ", await gk.getKeeper(4));
	console.log("BOOKeeper: ", await gk.getKeeper(5));
	console.log("BOPKeeper: ", await gk.getKeeper(6));
	console.log("BOSKeeper: ", await gk.getKeeper(7));
	console.log("ROMKeeper: ", await gk.getKeeper(8));
	console.log("ROSKeeper: ", await gk.getKeeper(9));
	console.log("SHAKeeper: ", await gk.getKeeper(10));

	let num = 50;
	await gk.connect(signers[3]).setMaxQtyOfMembers(num);
	console.log("setMaxQtyOfMembers: ", num);

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
