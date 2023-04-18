const hre = require("hardhat");
const { contractGetter, tempAddrGetter } = require("./contractGetter");

async function main() {
	const signers = await hre.ethers.getSigners();
	const owner = signers[2];
	const keeper = signers[3];
	const gc = signers[4];
	console.log(
		"owner:",
		owner.address, "\n",
		"keeper: ",
		keeper.address, "\n",
		"generalCounsel: ",
		gc.address, "\n"
	);

	// ==== Get GK & RC ====
	const addrOfGK = "0x6687Da782e8b34d8f818f7BAA844Ca9217ce2bcD";

	const addrOfRC = await tempAddrGetter("RegCenter");
	const rc = await contractGetter("RegCenter", addrOfRC);
	console.log("obtained rc at address:", rc.address);

	// ==== Prepare Accts ====

	const ownerNo = await rc.connect(signers[2]).getMyUserNo();
	console.log("owner's UserNo: ", ownerNo);

	const keeperNo = await rc.connect(signers[3]).getMyUserNo();
	console.log("keeper's UserNo: ", keeperNo);

	const gcNo = await rc.connect(signers[4]).getMyUserNo();
	console.log("generalCounsel's UserNo: ", gcNo);

	const acct5 = await rc.connect(signers[5]).getMyUserNo();
	console.log("Acct5 userNo: ", acct5);

	// ==== Get GK ====

	const artOfGK = hre.artifacts.readArtifactSync("GeneralKeeper");
	const gk = await hre.ethers.getContractAt(artOfGK.abi, addrOfGK);
	console.log("obtained gk at address:", gk.address);

	// ==== Get BOHKeeper ====
	const artOfBOHKeeper = hre.artifacts.readArtifactSync("BOHKeeper");
	const addrOfBOHKeeper = await gk.getKeeper(4);
	const bohKeeper = await hre.ethers.getContractAt(artOfBOHKeeper.abi, addrOfBOHKeeper);
	console.log("obtained bohKeeper at address:", bohKeeper.address);

	// ==== Get BOH ====
	const artOfBOH = hre.artifacts.readArtifactSync("BookOfSHA");
	const addrOfBOH = await gk.getBOH();
	const boh = await hre.ethers.getContractAt(artOfBOH.abi, addrOfBOH);
	console.log("obtained boh at address:", boh.address);

	// ==== CreateSHA ====

	await gk.connect(owner).createSHA(1);
	console.log("created SHA");

	let logs = await rc.queryFilter("CreateDoc", "latest");
	let doc = {};
	let addOfSHA;

	logs.map(v => {
		doc.typeOfDoc = v.args["typeOfDoc"].toNumber();
		doc.creator = v.args["creator"].toNumber();
		doc.body = v.args["body"];

		if (doc.typeOfDoc == 22 && 
				doc.creator == ownerNo) 
		{
				addOfSHA = doc.body;
		}
	});

	console.log(
		"get SHA's address: ", addOfSHA
	);

	const artOfSHA = hre.artifacts.readArtifactSync("ShareholdersAgreement");
	const sha = await hre.ethers.getContractAt(artOfSHA.abi, addOfSHA);
	console.log("obtained sha at: ", sha.address);

	logs = await sha.queryFilter("Init", "latest");
	console.log("Init SHA with \n",
		"owner: ", logs[0].args["owner"].toNumber(), "\n",
		"directKeeper: ", logs[0].args["directKeeper"], "\n",
		"regCenter: ", logs[0].args["regCenter"], "\n",
		"generalKeeper: ", logs[0].args["generalKeeper"] , "\n"
	);

	logs = await boh.queryFilter("UpdateStateOfFile", "latest");
	console.log("RegSHA with BOH",
		"address: ", logs[0].args["body"], "\n",
		"stateOfFile: ", logs[0].args["state"].toNumber(), "\n"
	);

	// ==== Set General Counsel ====
	await sha.connect(owner).setGeneralCounsel(await rc.connect(gc).getMyUserNo());
	logs = await sha.queryFilter("SetGeneralCounsel", "latest");
	console.log("Set GeneralCounsel of SHA",
		"counsel's userNo: ", logs[0].args["acct"].toNumber()
	);
	
	// ==== GovernanceRule ====

	let gr = {};
	gr.seqOfRule = "0000";
	gr.qtyOfSubRule = "01";
	gr.seqOfSubRule = "01";
	gr.basedOnPar = "00";
	gr.proposeWeightRatioOfGM = "03e8";
	gr.proposeHeadNumOfMembers = "0000";
	gr.proposeHeadNumOfDirectors = "0001";
	gr.maxNumOfMembers = "00000032";
	gr.quorumOfGM = "1388";
	gr.maxNumOfDirectors = "0032";
	gr.tenureMonOfBoard = "0024";
	gr.quorumOfBoardMeeting = "1388";
	
	let rule = serializeObj(gr);
	console.log("created GovernanceRule: ", rule);

	await sha.connect(gc).addRule(rule);
	console.log("added GovenanceRule into SHA: ", await sha.getRule(0));

}

function serializeObj (obj) {
	let arr = Object.values(obj);
	let rule = "0x";

	arr.map(v => {
		rule += v;
	});

	return rule.padEnd(66, "0");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
