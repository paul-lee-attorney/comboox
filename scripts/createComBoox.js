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

  // await rc.setBackupKey(signers[1].address);
	// console.log("Set GeneralKeeper of RC:", signers[1].address);

	let ret;

  ret = await rc.connect(signers[2]).createComp(signers[3].address, signers[2].address);
	console.log("Created new Comapny: ", ret);

	// ==== Templates ====

	// await gk.connect(signers[1]).setTempOfIA(ia.address, 0);
	// console.log("setTemplate of ia");

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
