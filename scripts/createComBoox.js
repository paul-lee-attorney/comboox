const hre = require("hardhat");
const { contractGetter } = require("./contractGetter");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		signers[0].address
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	let rc = await contractGetter("RegCenter");

	// ==== Crate Comp ====

  await rc.connect(signers[2]).createComp(signers[3].address);
	console.log("Created new Comapny");

	const filterCreateComp = rc.filters.CreateComp();

	const logsCreateComp = await rc.queryFilter(filterCreateComp);
	console.log("create ComBoox with GK: ", logsCreateComp[0].args["generalKeeper"]);

	// const filterCreateDoc = rc.filters.CreateDoc();
	// const logsCreateDoc = await rc.queryFilter(filterCreateDoc);
	// logsCreateDoc.map( (v) => {
	// 	console.log("Created SnDoc: ", "0x" + v.args["snOfDoc"].toHexString().slice(2).padStart(64, "0"));
	// 	console.log("at Address: ", v.args["body"], "\n");
	// });

	const artOfGK = hre.artifacts.readArtifactSync("GeneralKeeper");
	let gk = await hre.ethers.getContractAt(artOfGK.abi, logsCreateComp[0].args["generalKeeper"]);
	console.log("obtained GK at address:", gk.address);

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


};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
