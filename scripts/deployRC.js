// scripts/deploy-uups.ts
import hre from "hardhat";

export async function main() {
  const publicClient = await hre.viem.getPublicClient();
  const [deployer] = await hre.viem.getWalletClients();
  console.log("deployer:", deployer.account.address);

  // 1) 部署实现合约
  const Impl = await hre.viem.getContractFactory("YourUUPSContract");
  const impl = await Impl.deploy();
  console.log("impl tx:", impl.deploymentTransaction?.hash);
  const implAddr = await impl.getAddress();
  console.log("impl:", implAddr);

  // 2) 编码初始化数据（按需替换参数）
  const initData = Impl.interface.encodeFunctionData("initialize", [
    deployer.account.address,
    "0x0000000000000000000000000000000000000000"
  ]);

  // 3) 部署 ERC1967Proxy
  const Proxy = await hre.viem.getContractFactory("ERC1967Proxy");
  const proxy = await Proxy.deploy([implAddr, initData]);
  console.log("proxy tx:", proxy.deploymentTransaction?.hash);
  const proxyAddr = await proxy.getAddress();
  console.log("proxy:", proxyAddr);

  // 4) 通过代理读写（可选）
  const proxied = await hre.viem.getContractAt("YourUUPSContract", proxyAddr);
  const owner = await proxied.read.getOwner?.();
  console.log("proxied owner:", owner);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});