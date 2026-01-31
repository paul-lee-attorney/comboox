// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2025 LI LI of JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

// To run the test codes with a single command:
// (1) start a solo test node of HardHat in a terminal with the following command:
//     "npx hardhat node";
// (2) run this JS code in another terminal with the following command:
//     "node testReportUSD.js".

// To run the testing codes one by one:
// (1) start a solo test node of HardHat in a terminal with the following command:
//     "npx hardhat node";
// (2) run the test JS code in another terminal one by one:
//     "npx hardhat run ./scripts/testing/01_regUsers.js";
//     "npx hardhat run ./scripts/testing/02.1_createCompUSD.js";
//     ... ...

// To ensure the accuracy and relevance of the testing process, it must be conducted
// under predefined conditions, including shareholding structure, officer titles, 
// the Shareholders Agreement, and other corporate governance elements. The testing 
// shall be performed in a strictly defined sequential order.

// For a detailed explanation of the test scenario and the APIs involved, please 
// refer to the instructions at the top of each test JS script.


import {spawn} from "child_process";

const runScript = (command, args) => {
  return new Promise((resolve, reject) => {
    const process = spawn(command, args, { stdio: 'inherit' });

    process.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Process exited with code ${code}`));
      }
    });
  });
};

(async () => {
  try {
    await runScript('npx', ['hardhat', 'run', './scripts/deployMasterBase.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/01_regUsers.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/02_createComp.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/03_configComBoox.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/04_signSHA.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/05_electOfficers.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/06_approveInvestors.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/07_motions.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/08_capitalIncrease.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/09_externalTransfer.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/10_internalTransfer.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/11_antiDilution.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/12_alongs.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/13_firstRefusal.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/14_pledge.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/15_options.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/16_cbpTransaction.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/17_listing.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/18_deposits.js', '--network', 'localhost']);

    console.log('All tests are passed successfully !\n');
  } catch (err) {
    console.error('Error in script execution:', err);
  }
})();