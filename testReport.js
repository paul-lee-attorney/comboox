const { spawn } = require('child_process');

// Run a script using spawn for more control over streaming
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

// Run scripts sequentially
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
    console.log('All tests are passed successfully !');
  } catch (err) {
    console.error('Error in script execution:', err);
  }
})();