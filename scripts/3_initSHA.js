const hre = require("hardhat");
const { contractGetter, tempAddrGetter } = require("./contractGetter");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Initiate ComBoox with owner:",
		signers[2].address,
		" and keeper: ",
		signers[3].address
	);

	// ==== Get GK & RC ====
	const addrOfGK = "0x4703e9E523b0C23C849e333aF18e6985a3B60b6c";

	const addrOfRC = await tempAddrGetter("RegCenter");
	const rc = await contractGetter("RegCenter", addrOfRC);
	console.log("obtained rc at address:", rc.address);

	// ==== Prepare Accts ====

	const acct2 = await rc.connect(signers[2]).getMyUserNo();
	console.log("Acct2 userNo: ", acct2);

	const acct3 = await rc.connect(signers[3]).getMyUserNo();
	console.log("Acct3 userNo: ", acct3);

	const acct4 = await rc.connect(signers[4]).getMyUserNo();
	console.log("Acct4 userNo: ", acct4);

	const acct5 = await rc.connect(signers[5]).getMyUserNo();
	console.log("Acct5 userNo: ", acct5);

	// ==== Create SHA ====

	const artOfGK = hre.artifacts.readArtifactSync("GeneralKeeper");
	const gk = await hre.ethers.getContractAt(artOfGK.abi, addrOfGK);
	console.log("obtained gk at address:", gk.address);

	await gk.connect(signers[3]).createSHA(1);
	console.log("created sha ");

	let logs = await rc.queryFilter("CreateDoc", "latest");
	console.log("CreateDoc of type: ", logs[0].args["typeOfDoc"], "created by: ", logs[0].args["creator"], "at address: ", logs[0].args["body"]);

	const artOfSHA = hre.artifacts.readArtifactSync("ShareholdersAgreement");
	const sha = await hre.ethers.getContractAt(artOfSHA.abi, logs[0].args["body"]);
	console.log("obtained sha: ", sha.address);


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
