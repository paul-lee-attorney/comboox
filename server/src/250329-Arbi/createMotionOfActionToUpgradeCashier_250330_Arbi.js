// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");
const { deployTool } = require("../../../scripts/deployTool");
const { 
	RegCenter, USDC, USDKeeper
} = require("./contracts-address-consolidated.json")
const { readContract } = require("../../../scripts/readTool");

async function main() {
	const signers = await hre.ethers.getSigners();
	console.log(
		"Deploying the contracts with the account:",
		await signers[0].getAddress(), "\n"
	);
	console.log("Account balance:", (await signers[0].getBalance()).toString());

	const cashierAddr = "0x8871e3Bb5Ac263E10e293Bee88cce82f336Cb20a";
	const gkAddr = "0x68233e877575e8c7e057e83ef0d16ffa7f98984d";

	const gk = await readContract("GeneralKeeper", gkAddr); 

	// ==== construct iface ====

	const abi = [
		"function transferUsd(address to, uint256 amt) external",
	];

	const iface = new ethers.utils.Interface(abi);
	const to = "0x17d9A82Cdd2471ca26f9B5D603bE808aEa41e6F1";
	const amt = (10n ** 9n).toString();
	const data = iface.encodeFunctionData("transferUsd", [to, amt]);
	
	console.log("payload for calling func:");
	console.log(data);
	
	// ==== Create Action ====

	const seqOfVR = 9n;
	const desHash = ethers.utils.formatBytes32String("UpgradeCashier");
	const executor = 1n;

	let tx = await gk.createActionOfGM(
		seqOfVR, [cashierAddr], [0n], [data], desHash, executor
	);

	let receipt = await tx.wait();

	console.log("tx:", tx);
	console.log("receipt:", receipt);

/*
	tx: {
		hash: '0x5edb8253d6b5d5fc9cdd50ca542fdd849ae2373982ff2db19459af5d2fa8cc5c',
		type: 2,
		accessList: [],
		blockHash: '0x21f4d2ece96e211c93220c6070a0e020ae6d1af6f7a0d3908dc7ef3605bdc366',
		blockNumber: 320945002,
		transactionIndex: 7,
		confirmations: 1,
		from: '0xc12c20fd7B50DA0909500dc9bb6758376398F8a8',
		gasPrice: BigNumber { value: "10000000" },
		maxPriorityFeePerGas: BigNumber { value: "0" },
		maxFeePerGas: BigNumber { value: "12656250" },
		gasLimit: BigNumber { value: "307476" },
		to: '0x68233E877575E8C7e057e83eF0D16FFa7F98984D',
		value: BigNumber { value: "0" },
		nonce: 1173,
		data: '0xc297ddd0000000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001405570677261646543617368696572000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000008871e3bb5ac263e10e293bee88cce82f336cb20a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000044291c098e00000000000000000000000017d9a82cdd2471ca26f9b5d603be808aea41e6f1000000000000000000000000000000000000000000000000000000003b9aca0000000000000000000000000000000000000000000000000000000000',
		r: '0x04e24206d87f363f99fe1535525a9c846c1efc23cbaeca09ef3f0c6129d7a459',
		s: '0x66b31898bdb909403411235317b43dbb2f68db8c628049d1e37c0b92f411f26d',
		v: 0,
		creates: null,
		chainId: 42161,
		wait: [Function (anonymous)]
	  }	*/

/*
	  receipt: {
		to: '0x68233E877575E8C7e057e83eF0D16FFa7F98984D',
		from: '0xc12c20fd7B50DA0909500dc9bb6758376398F8a8',
		contractAddress: null,
		transactionIndex: 7,
		gasUsed: BigNumber { value: "285460" },
		logsBloom: '0x00000000000000000000000000000000000040000000000000000000000000000000000000000000000800000000000000000000000000000000000001000000000000000004000000000008000008010000010000000000000000000000000000000000400000000000000000000010000000000000008000001010000000000200000000000000000000000000000008000000000000001000000000000010000000000000000000000000000000000000000000000000000000000000000000000002100000000000000080000008000000010000000000000000000000000000000000000000000000000010000000000000000000002000000000000a00',
		blockHash: '0x21f4d2ece96e211c93220c6070a0e020ae6d1af6f7a0d3908dc7ef3605bdc366',
		transactionHash: '0x5edb8253d6b5d5fc9cdd50ca542fdd849ae2373982ff2db19459af5d2fa8cc5c',
		logs: [
		  {
			transactionIndex: 7,
			blockNumber: 320945002,
			transactionHash: '0x5edb8253d6b5d5fc9cdd50ca542fdd849ae2373982ff2db19459af5d2fa8cc5c',
			address: '0x18F7AE56d1e04B95A2C50AFd528aC3FCb6F23f91',
			topics: [Array],
			data: '0x',
			logIndex: 33,
			blockHash: '0x21f4d2ece96e211c93220c6070a0e020ae6d1af6f7a0d3908dc7ef3605bdc366'
		  },
		  {
			transactionIndex: 7,
			blockNumber: 320945002,
			transactionHash: '0x5edb8253d6b5d5fc9cdd50ca542fdd849ae2373982ff2db19459af5d2fa8cc5c',
			address: '0xa55e249Ca4bfF878E80dE14F16Fe05C7D3B5e844',
			topics: [Array],
			data: '0x',
			logIndex: 34,
			blockHash: '0x21f4d2ece96e211c93220c6070a0e020ae6d1af6f7a0d3908dc7ef3605bdc366'
		  }
		],
		blockNumber: 320945002,
		confirmations: 1,
		cumulativeGasUsed: BigNumber { value: "2967573" },
		effectiveGasPrice: BigNumber { value: "10000000" },
		status: 1,
		type: 2,
		byzantium: true,
		events: [
		  {
			transactionIndex: 7,
			blockNumber: 320945002,
			transactionHash: '0x5edb8253d6b5d5fc9cdd50ca542fdd849ae2373982ff2db19459af5d2fa8cc5c',
			address: '0x18F7AE56d1e04B95A2C50AFd528aC3FCb6F23f91',
			topics: [Array],
			data: '0x',
			logIndex: 33,
			blockHash: '0x21f4d2ece96e211c93220c6070a0e020ae6d1af6f7a0d3908dc7ef3605bdc366',
			removeListener: [Function (anonymous)],
			getBlock: [Function (anonymous)],
			getTransaction: [Function (anonymous)],
			getTransactionReceipt: [Function (anonymous)]
		  },
		  {
			transactionIndex: 7,
			blockNumber: 320945002,
			transactionHash: '0x5edb8253d6b5d5fc9cdd50ca542fdd849ae2373982ff2db19459af5d2fa8cc5c',
			address: '0xa55e249Ca4bfF878E80dE14F16Fe05C7D3B5e844',
			topics: [Array],
			data: '0x',
			logIndex: 34,
			blockHash: '0x21f4d2ece96e211c93220c6070a0e020ae6d1af6f7a0d3908dc7ef3605bdc366',
			removeListener: [Function (anonymous)],
			getBlock: [Function (anonymous)],
			getTransaction: [Function (anonymous)],
			getTransactionReceipt: [Function (anonymous)]
		  }
		]
	  } */

};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
