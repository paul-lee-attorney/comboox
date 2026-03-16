// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2026 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

import {network} from "hardhat";
import { deployTool, getTypeByName } from "../../../scripts/deployTool";
import { readTool } from "../../../scripts/readTool";
import addrs from "../contracts/contracts-address.json";

async function main() {

	const { ethers } = await network.connect();

	const signers = await ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress()
	);

	console.log("Account balance:", (await ethers.provider.getBalance(signers[0])).toString());

	let libraries = {};
	let params = [];

	// ==== Get RC, GK & Accts ====

	const rc = await readTool("RegCenter", addrs.RegCenter_Proxy);

	const addrGK = "0xd9bb66d6e9bd06b6088e95c9a74b8a4b42b02a11";
	const gk = await readTool("GeneralKeeper", addrGK);

	const acct_0 = await rc.getMyUserNo();

	// ==== Get Ros ====

	const addrROS = "0x960a4c6e2312702791006736cc019ad87e8e297c";
	const ros = await readTool("RegisterOfShares", addrROS);

	const addrNewROS = "0x6185cb3FB8A224D31a74CDa99b47D17D6002Aa08";

	// ==== Deploy Another ROS as New Temp ====

	// libraries = {
	// 	"LockersRepo": (await rc.getTemp(getTypeByName("LockersRepo"), 1))[1],
	// 	"SharesRepo": (await rc.getTemp(getTypeByName("SharesRepo"), 1))[1],
	// 	"InterfacesHub": (await rc.getTemp(getTypeByName("InterfacesHub"), 1))[1]
	// }
	// const addrNewROS = await deployTool(signers[0], "RegisterOfShares", libraries, params);
	// await rc.connect(signers[1]).setTemplate(getTypeByName("RegisterOfShares"), addrNewROS, acct_0);
	// console.log("Reg the RegisterOfShares:", addrNewROS, "in BookOfDocs \n");

	// ==== Upgrade to proxy New Ros ====

	// transfer DK to signers[0], who is also the owner;
	await gk.connect(signers[1]).takeBackKeys(addrROS);
	await ros.connect(signers[1]).setDirectKeeper(signers[0].address);

	let res = await ros.upgradeDocTo(addrNewROS); 
	console.log("Upgrade res:", res, "\n");
	
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
