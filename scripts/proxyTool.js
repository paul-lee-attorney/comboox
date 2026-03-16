import { network } from "hardhat";
import { saveTempAddr } from "./deployTool";
import { readTool } from "./readTool";

export async function proxySC(signer, scName, addrRC) {

    let options = {signer: signer};

    const {ethers} = await network.connect();

    const Proxy = await ethers.getContractFactory("ERC1967Proxy", options);
    console.log("Obtained Proxy Interface \n");

    const proxy = await Proxy.deploy(addrRC, "0x");

    await proxy.waitForDeployment();

    const proxyAddress = await proxy.getAddress();

    console.log("Deployed Smart Contract at:", proxyAddress, "\n");

    saveTempAddr(scName + "_Proxy", proxyAddress);

    return proxyAddress;
}



