// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2024 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

const hre = require("hardhat");

const { getGK, getROS, getROO, } = require("./boox");
const { increaseTime, } = require("./utils");
const { printShares } = require("./ros");
const { parseOption, parseOracle, parseSwap } = require("./roo");

async function main() {

    console.log('********************************');
    console.log('**      Call / Put Option     **');
    console.log('********************************\n');

	  const signers = await hre.ethers.getSigners();

    const gk = await getGK();
    const roo = await getROO();
    const ros = await getROS();
    
    // ==== Update Oracles ====

    await gk.connect(signers[1]).updateOracle(1, 5600 * 10 ** 4, 550 * 10 ** 4, 0);
    console.log('get latest oracle of option 1:', parseOracle(await roo.getLatestOracle(1)), '\n');
    console.log('Opt No 1:', parseOption(await roo.getOption(1)), '\n');

    await gk.connect(signers[1]).updateOracle(2, 800 * 10 ** 4, 120 * 10 ** 4, 0);
    console.log('get latest oracle of option 2:', parseOracle(await roo.getLatestOracle(2)), '\n');
    console.log('Opt No 2:', parseOption(await roo.getOption(2)), '\n');
        
    // ==== Execute Option ====

    await gk.connect(signers[3]).execOption(1);
    console.log('exec opt No 1:', parseOption(await roo.getOption(1)), '\n');

    await gk.connect(signers[1]).execOption(2);
    console.log('exec opt No 2:', parseOption(await roo.getOption(2)), '\n');

    // ==== Create Swap ====
    
    await gk.connect(signers[3]).createSwap(1, 3, 500*10**4, 2);
    console.log('swap created:', parseSwap(await roo.getSwap(1, 1)), '\n');

    await gk.connect(signers[1]).createSwap(2, 3, 500*10**4, 2);
    console.log('swap created:', parseSwap(await roo.getSwap(2, 1)), '\n');
    
    // ==== Exec Call Option ====

    const centPrice = await gk.getCentPrice();
    let value = 110n * 500n * BigInt(centPrice) + 100n;

    await gk.connect(signers[1]).payOffSwap(2, 1, {value:value});
    console.log('call opt to Share 3 executed.\n');

    // ==== Exec Put Option ====

    await increaseTime(86400 * 4);

    await gk.connect(signers[3]).terminateSwap(1, 1);
    console.log('put opt to Share 3 executed.\n');

    await printShares(ros);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });  
