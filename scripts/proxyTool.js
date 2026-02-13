import { network } from "hardhat";
import { saveTempAddr } from "./deployTool";
import { readTool } from "./readTool";

export async function proxyRC(signer, addrRC, bookeeper) {

    let options = {signer: signer};

    const {ethers} = await network.connect();

    const Proxy = await ethers.getContractFactory("ERC1967Proxy", options);
    console.log("Obtained Proxy Interface \n");

    const proxy = await Proxy.deploy(addrRC, "0x");

    await proxy.waitForDeployment();

    const proxyAddress = await proxy.getAddress();

    const rc = await readTool("RegCenter", proxyAddress);

    await rc.initialize(proxyAddress, bookeeper);

    console.log("Deployed Proxy RegCenter at:", proxyAddress);

    saveTempAddr("RegCenter_Proxy", proxyAddress);

    return proxyAddress;
}



