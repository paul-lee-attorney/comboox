const hre = require("hardhat");

const { contractGetter } = require("../scripts/contractGetter");

// const { deployTool } = require("./deployTool");



async function main() {
	const signers = await hre.ethers.getSigners();

	signers.map((v, i) => console.log("Singer", i, "address: ", v.address));

	// console.log("getSigners: ", signers.address);

	let rc = await contractGetter("RegCenter");
	// console.log("obtained RegCenter: ", rc.address);

	const acct0 = await rc.connect(signers[0]).getMyUserNo();
	console.log("acct0: ", acct0);

	await rc.connect(signers[1]).regUser();
	console.log("Acct1 reigstered");
	const acct1 = await rc.connect(signers[1]).getMyUserNo();
	console.log("Acct1: ", acct1);

	await rc.connect(signers[2]).regUser();
	console.log("Acct2 reigstered");
	const acct2 = await rc.connect(signers[2]).getMyUserNo();
	console.log("acct2: ", acct2);

	await rc.connect(signers[3]).regUser();
	console.log("Acct3 reigstered");
	const acct3 = await rc.connect(signers[3]).getMyUserNo();
	console.log("Acct3: ", acct3);

	await rc.connect(signers[4]).regUser();
	console.log("Acct4 reigstered");
	const acct4 = await rc.connect(signers[4]).getMyUserNo();
	console.log("Acct4: ", acct4);

	await rc.connect(signers[5]).regUser();
	console.log("Acct5 reigstered");
	const acct5 = await rc.connect(signers[5]).getMyUserNo();
	console.log("Acct5: ", acct5);

	await rc.connect(signers[6]).regUser();
	console.log("Acct6 reigstered");
	const acct6 = await rc.connect(signers[6]).getMyUserNo();
	console.log("Acct6: ", acct6);

	await rc.connect(signers[7]).regUser();
	console.log("Acct7 reigstered");
	const acct7 = await rc.connect(signers[7]).getMyUserNo();
	console.log("Acct7: ", acct7);

	await rc.connect(signers[8]).regUser();
	console.log("Acct8 reigstered");
	const acct8 = await rc.connect(signers[8]).getMyUserNo();
	console.log("Acct8: ", acct8);

	await rc.connect(signers[9]).regUser();
	console.log("Acct9 reigstered");
	const acct9 = await rc.connect(signers[9]).getMyUserNo();
	console.log("Acct9: ", acct9);

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
