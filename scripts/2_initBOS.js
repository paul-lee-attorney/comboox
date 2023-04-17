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

	// ==== Crate Comp ====
	const addrOfGK = "0x5559244bedaB6b84b00B0bb9ebac8CAc37D806f1";

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

	// ==== Issue Shares ====

	const artOfGK = hre.artifacts.readArtifactSync("GeneralKeeper");
	const gk = await hre.ethers.getContractAt(artOfGK.abi, addrOfGK);
	console.log("obtained gk at address:", gk.address);

	const artOfBOSKeeper = hre.artifacts.readArtifactSync("BOSKeeper");
	const addrOfBOSKeeper = await gk.getKeeper(7);
	console.log("address of bosKeeper: ", addrOfBOSKeeper);

	const	bosKeeper = await hre.ethers.getContractAt(artOfBOSKeeper.abi, addrOfBOSKeeper);
	console.log("obtained bosKeeper: ", bosKeeper.address);

	const artOfBOS = hre.artifacts.readArtifactSync("BookOfShares");
	const addrOfBOS = await gk.getBOS();  
	const	bos = await hre.ethers.getContractAt(artOfBOS.abi, addrOfBOS);
	console.log("obtained BOS: ", bos.address);

	const artOfROM = hre.artifacts.readArtifactSync("RegisterOfMembers");
	const addrOfROM = await gk.getROM();  
	const	rom = await hre.ethers.getContractAt(artOfROM.abi, addrOfROM);
	console.log("obtained ROM: ", rom.address);

	let dk = await bos.getBookeeper();

	// ==== getBack Bookeeper right to EOA of GK's bookeeper ====
	if (dk == bosKeeper.address) {
		await gk.connect(signers[3]).removeDirectKeeper(bosKeeper.address);
		await bosKeeper.connect(signers[3]).removeDirectKeeper(addrOfBOS);
		console.log("get back keeper's authority from BOS");	
	}

	// ==== issue share1 ====

	let objShareNumber = {
		seqOfShare: 0,
		preSeq: 0,
		class: 1,
		issueDate: 1473332264,
		shareholder: acct2,
		priceOfPaid: 100,
		priceOfPar: 0,
		para: 0,
		arg:0
	};
	console.log("ObjSn: ", objShareNumber);
	
	let sn = _codifyShareNumber(objShareNumber);
	console.log("created sharenumber: ", sn);

	let objShareBody = {
		payInDeadline: 1533725864,
		paid: 5000000,
		par: 5000000
	}
	console.log("created body of share: ", objShareBody);

	await _issueShare(bos, rom, sn, objShareBody, signers[3]);

	// ==== Share 2 ====

	objShareNumber.shareholder = acct3;
	sn = _codifyShareNumber(objShareNumber);
	console.log("created sharenumber: ", sn);

	objShareBody.paid = 3000000;
	objShareBody.par = 3000000;

	await _issueShare(bos, rom, sn, objShareBody, signers[3]);

	// ==== Share 3 ====

	objShareNumber.shareholder = acct4;
	sn = _codifyShareNumber(objShareNumber);
	console.log("created sharenumber: ", sn);

	objShareBody.paid = 1000000;
	objShareBody.par = 2000000;

	await _issueShare(bos, rom, sn, objShareBody, signers[3]);

	// ==== Share 4 ====

	objShareNumber.shareholder = acct5;
	sn = _codifyShareNumber(objShareNumber);
	console.log("created sharenumber: ", sn);

	objShareBody.paid = 1000000;
	objShareBody.par = 1000000;

	await _issueShare(bos, rom, sn, objShareBody, signers[3]);


	// ==== Recover Bookeeper ====
	await bos.connect(signers[3]).setDirectKeeper(bosKeeper.address);
	console.log("recovered bookeeper of BOS into: ", await bos.getBookeeper());
	await bosKeeper.connect(signers[3]).setDirectKeeper(gk.address);
	console.log("recovered bookeeper of BOSKeeper into: ", await bosKeeper.getBookeeper());

};

function _codifyShareNumber(objSn) {
	let sn = "0x" + objSn.seqOfShare.toString(16).padStart(8, "0") +
		objSn.preSeq.toString(16).padStart(8, "0") + 
		objSn.class.toString(16).padStart(4, "0") +
		objSn.issueDate.toString(16).padStart(12, "0") +
		objSn.shareholder.toString(16).padStart(10, "0") +
		objSn.priceOfPaid.toString(16).padStart(8, "0") +
		objSn.priceOfPar.toString(16).padStart(8, "0") +
		objSn.para.toString(16).padStart(4, "0") +
		objSn.arg.toString(16).padStart(2, "0");	
	return sn
}

async function _issueShare(bos, rom, sn, objShareBody, signer) {
	await bos.connect(signer).issueShare(
		sn, 
		objShareBody.payInDeadline, 
		objShareBody.paid, 
		objShareBody.par
	);

	let logs = await rom.queryFilter("AddMember", "latest");

	if (logs.length > 0) 
		console.log("AddMember: ", logs[0].args["acct"].toNumber(), 
			"resulting totalQtyOfMembers: ", 
			logs[0].args["qtyOfMembers"].toNumber());

	logs = await bos.queryFilter("IssueShare", "latest");
	console.log("IssueShare: ", logs[0].args["seqOfShare"].toNumber(),
		"paid: ", logs[0].args["paid"].toNumber(),
		"par: ", logs[0].args["par"].toNumber());

	logs = await rom.queryFilter("AddShareToMember", "latest");
	console.log("add Share: ", logs[0].args["seqOfShare"].toNumber(),
		"to Member: ", logs[0].args["acct"].toNumber());

	logs = await rom.queryFilter("CapIncrease", "latest");
	console.log("CapIncrease with paid: ", logs[0].args["paid"].toNumber(),
		"par: ", logs[0].args["par"].toNumber());

	console.log("CounterOfShare: ", await bos.counterOfShares());
	console.log("SharesList: ", await rom.sharesList());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
