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
	
	// ==== Exec Action ====

	const seqOfVR = 9n;
	const desHash = ethers.utils.formatBytes32String("UpgradeCashier");
	const seqOfMotion = 26n;

	let tx = await gk.execActionOfGM(
		seqOfVR, [cashierAddr], [0n], [data], desHash, seqOfMotion
	);

	let receipt = await tx.wait();

	console.log("tx:", tx);
	console.log("receipt:", receipt);

/*

tx: {
  hash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
  type: 2,
  accessList: [],
  blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646',
  blockNumber: 320948336,
  transactionIndex: 2,
  confirmations: 1,
  from: '0xc12c20fd7B50DA0909500dc9bb6758376398F8a8',
  gasPrice: BigNumber { value: "14461000" },
  maxPriorityFeePerGas: BigNumber { value: "0" },
  maxFeePerGas: BigNumber { value: "18468000" },
  gasLimit: BigNumber { value: "269036" },
  to: '0x68233E877575E8C7e057e83eF0D16FFa7F98984D',
  value: BigNumber { value: "0" },
  nonce: 1177,
  data: '0x07f2990e000000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001405570677261646543617368696572000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000008871e3bb5ac263e10e293bee88cce82f336cb20a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000044291c098e00000000000000000000000017d9a82cdd2471ca26f9b5d603be808aea41e6f1000000000000000000000000000000000000000000000000000000003b9aca0000000000000000000000000000000000000000000000000000000000',
  r: '0xeee745404efeddaaf97d23b3fbe2f2a7cacf248cf41823d825d839c4c78ea728',
  s: '0x7bbba17e697deb10c00b1554c37e90592442195daa219bd3c9136f5880d75772',
  v: 1,
  creates: null,
  chainId: 42161,
  wait: [Function (anonymous)]
}
receipt: {
  to: '0x68233E877575E8C7e057e83eF0D16FFa7F98984D',
  from: '0xc12c20fd7B50DA0909500dc9bb6758376398F8a8',
  contractAddress: null,
  transactionIndex: 2,
  gasUsed: BigNumber { value: "256942" },
  logsBloom: '0x00000000004800800000000000010000000800000001000000000000000000000000000000000000000800000000000000000001000000000000000001040000000000000804100001000008000008011000010000040000002000001000000001000000020002000008000000000800000010000000100000001014000000000200000000000000000000000000000010000000000400001010000000000018000020000000010000000000000041000000000000000000001000000000000000002002004000000000000000000008000000000020000000408000000060000000002000000000000080000010200000400000000004002000008000000808',
  blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646',
  transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
  logs: [
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0x18F7AE56d1e04B95A2C50AFd528aC3FCb6F23f91',
      topics: [Array],
      data: '0x',
      logIndex: 1,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646'
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0x7256b47ff39997355ecEC2deFB7C7B332FcFDd42',
      topics: [Array],
      data: '0x000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000001',
      logIndex: 2,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646'
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0xa55e249Ca4bfF878E80dE14F16Fe05C7D3B5e844',
      topics: [Array],
      data: '0x',
      logIndex: 3,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646'
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0x8871e3Bb5Ac263E10e293Bee88cce82f336Cb20a',
      topics: [Array],
      data: '0x',
      logIndex: 4,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646'
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
      topics: [Array],
      data: '0x000000000000000000000000000000000000000000000000000000003b9aca00',
      logIndex: 5,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646'
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0x68233E877575E8C7e057e83eF0D16FFa7F98984D',
      topics: [Array],
      data: '0x',
      logIndex: 6,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646'
    }
  ],
  blockNumber: 320948336,
  confirmations: 1,
  cumulativeGasUsed: BigNumber { value: "314898" },
  effectiveGasPrice: BigNumber { value: "14461000" },
  status: 1,
  type: 2,
  byzantium: true,
  events: [
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0x18F7AE56d1e04B95A2C50AFd528aC3FCb6F23f91',
      topics: [Array],
      data: '0x',
      logIndex: 1,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646',
      removeListener: [Function (anonymous)],
      getBlock: [Function (anonymous)],
      getTransaction: [Function (anonymous)],
      getTransactionReceipt: [Function (anonymous)]
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0x7256b47ff39997355ecEC2deFB7C7B332FcFDd42',
      topics: [Array],
      data: '0x000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000001',
      logIndex: 2,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646',
      removeListener: [Function (anonymous)],
      getBlock: [Function (anonymous)],
      getTransaction: [Function (anonymous)],
      getTransactionReceipt: [Function (anonymous)]
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0xa55e249Ca4bfF878E80dE14F16Fe05C7D3B5e844',
      topics: [Array],
      data: '0x',
      logIndex: 3,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646',
      removeListener: [Function (anonymous)],
      getBlock: [Function (anonymous)],
      getTransaction: [Function (anonymous)],
      getTransactionReceipt: [Function (anonymous)]
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0x8871e3Bb5Ac263E10e293Bee88cce82f336Cb20a',
      topics: [Array],
      data: '0x',
      logIndex: 4,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646',
      removeListener: [Function (anonymous)],
      getBlock: [Function (anonymous)],
      getTransaction: [Function (anonymous)],
      getTransactionReceipt: [Function (anonymous)]
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
      topics: [Array],
      data: '0x000000000000000000000000000000000000000000000000000000003b9aca00',
      logIndex: 5,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646',
      removeListener: [Function (anonymous)],
      getBlock: [Function (anonymous)],
      getTransaction: [Function (anonymous)],
      getTransactionReceipt: [Function (anonymous)]
    },
    {
      transactionIndex: 2,
      blockNumber: 320948336,
      transactionHash: '0xe83dc9be2b9a66c05305633908be3e021ee26cf28f8ce2d69d04f3ed68451f61',
      address: '0x68233E877575E8C7e057e83eF0D16FFa7F98984D',
      topics: [Array],
      data: '0x',
      logIndex: 6,
      blockHash: '0x5375c544b758a1d758e5948be4a55834a5a0638c3ea56e799e9ef9527dea0646',
      args: [Array],
      decode: [Function (anonymous)],
      event: 'ExecAction',
      eventSignature: 'ExecAction(uint256)',
      removeListener: [Function (anonymous)],
      getBlock: [Function (anonymous)],
      getTransaction: [Function (anonymous)],
      getTransactionReceipt: [Function (anonymous)]
    }
  ]
}

*/


};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
