// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { 
	RegCenter, EnumerableSet, GoldChain, RulesParser
} = require("../250619-Arbi/contracts-address-consolidated.json");
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

	const usdLooKeeper = await readContract("UsdLOOKeeper", "0x6435c90E7A0Dc232ec59E907bdC6D8eF8B0B38D0");
	const usdLoo = await readContract("UsdListOfOrders", "0x405ae7F64cA936D57a88E12226Ff7b27F7Ca9f36");

	const looKeeper = await readContract("LOOKeeper", "0x02c21381f9407383189924e59f34056F3F3140F2");
	const loo2 = await readContract("ListOfOrders", "0x8D2303A3Ff37f82A5EB3E06d845105Fe67570D03");

	const loo1 = await readContract("ListOfOrders", "0xC9CB65Fa5A541456b0571734ddd413eb787A1250");

	await usdLooKeeper.initKeepers(addrUsdKeeper, gk.address);
	console.log('initKeepers of usdLooKeeper.');

	await usdLoo.initKeepers(usdLooKeeper.address, gk.address);
	console.log('initKeepers of usdLoo.');

	await gk.connect(signers[1]).regKeeper(13, usdLooKeeper.address);
	console.log('regKeeper ', 13, 'as usdLooKeeper:', usdLooKeeper.address);
	
	await gk.connect(signers[1]).regBook(13, usdLoo.address);
	console.log('regBook ', 13, 'as usdLoo:', usdLoo.address);

	await looKeeper.initKeepers(gk.address, gk.address);
	console.log('initKeepers of looKeeper.');

	await loo2.initKeepers(signers[0].address, gk.address);
	console.log('initKeepers of loo2.');

	const qtyOfInvestors = await loo1.getQtyOfInvestors();	
	const list = await loo1.investorInfoList();
	await loo2.restoreInvestorsRepo(list, qtyOfInvestors);
	console.log('restore investors info into loo2.');
	console.log('qtyOfInvestors:', await loo2.getQtyOfInvestors());
	console.log('investorsInfoList:', await loo2.investorInfoList());

	await loo2.setDirectKeeper(looKeeper.address);
	console.log('transfer DK of loo2 to looKeeper.');

	await gk.connect(signers[1]).regKeeper(10, looKeeper.address);
	console.log('regKeeper ', 10, 'as looKeeper:', looKeeper.address);
	
	await gk.connect(signers[1]).regBook(10, loo2.address);
	console.log('regBook ', 10, 'as loo:', loo2.address);

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
