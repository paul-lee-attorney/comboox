const hre = require("hardhat");

const { contractGetter } = require("./contractGetter");

// const { deployTool } = require("./deployTool");

async function main() {

	const signers = await hre.ethers.getSigners();

	signers.map((v, i) => console.log("Singer", i, "address: ", v.address));


	let rc = await contractGetter("RegCenter");
	let bos = await contractGetter("BookOfShares");
	let rom = await contractGetter("RegisterOfMembers");
	let gk = await contractGetter("GeneralKeeper");

	let events;
	// ==== config setting ====
	
	await gk.connect(signers[1]).setMaxQtyOfMembers(50);
	events = await rom.queryFilter("SetMaxQtyOfMembers");
	console.log("Event 'SetMaxQtyOfMembers': ", events[events.length - 1]);

	// ==== IssueShare ====


};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
