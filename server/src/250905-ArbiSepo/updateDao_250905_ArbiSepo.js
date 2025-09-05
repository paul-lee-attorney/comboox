// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { 
	RegCenter, EnumerableSet, GoldChain, RulesParser
} = require("./contracts-address-consolidated.json");
const { readContract } = require("../../../scripts/readTool");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress()
	);

	console.log("Account balance:", (await signers[0].getBalance()).toString());

	const gk = await readContract("GeneralKeeper", "0xdbc235f3CB5f344065143D67621AACF5F1AcA7Cb");
	const addrUsdKeeper = "0x113C1666E4EF6B4Cc951Cad5c91d3d192A934762";

	const usdLooKeeper_2 = await readContract("UsdLOOKeeper", "0x3b888b2b277451646DBbD98f7e587f29d3021d27");

	await usdLooKeeper_2.initKeepers(addrUsdKeeper, gk.address);
	console.log('initKeepers of usdLooKeeper_2.');

	const usdLooKeeper_1 = await readContract("UsdLOOKeeper", "0xd4e110578442446307E77502DDE8b2Fe5eDA4e90");
	const usdLoo = await readContract("UsdListOfOrders", "0x811a6C96D41364012785Fd7F67CEB183A7187d7A");
	const usdKeeper = await readContract("USDKeeper", addrUsdKeeper);

	await usdKeeper.connect(signers[1]).takeBackKeys(usdLooKeeper_1.address);
	console.log('take back keys of UsdLooKeeper_1 as:', signers[1].address);

	await usdLooKeeper_1.connect(signers[1]).takeBackKeys(usdLoo.address);
	console.log('take back keys of UsdLoo as:', signers[1].address);

	await usdLoo.connect(signers[1]).setDirectKeeper(usdLooKeeper_2.address);
	console.log('set UsdLOO new DK:', usdLooKeeper_2.address);

	await gk.connect(signers[1]).regKeeper(13, usdLooKeeper_2.address);
	console.log('regKeeper ', 13, 'as usdLooKeeper_2:', usdLooKeeper_2.address);
	
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
