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

	const gk = await readContract("GeneralKeeper", "0x68233e877575e8c7e057e83ef0d16ffa7f98984d");
	const addrUsdKeeper = "0x0d72a2EE78306D27C11A0894c0a137b789a21C7C";

	const usdLooKeeper_2 = await readContract("UsdLOOKeeper", "0xf5e5Fe50F7663bc66949Bad35e8a55f85C030Fcf");

	await usdLooKeeper_2.initKeepers(addrUsdKeeper, gk.address);
	console.log('initKeepers of usdLooKeeper_2.');

	const usdLooKeeper_1 = await readContract("UsdLOOKeeper", "0x6435c90E7A0Dc232ec59E907bdC6D8eF8B0B38D0");
	const usdLoo = await readContract("UsdListOfOrders", "0x405ae7F64cA936D57a88E12226Ff7b27F7Ca9f36");
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
