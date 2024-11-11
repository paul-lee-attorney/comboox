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
    await runScript('npx', ['hardhat', 'run', './scripts/testing/00_regUsers.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/01_createComp.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/02_configComBoox.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/03_signSHA.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/04_electOfficers.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/05_approveInvestors.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/06_capitalIncrease.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/07_externalTransfer.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/08_internalTransfer.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/09_antiDilution.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/10_alongs.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/11_firstRefusal.js', '--network', 'localhost']);
    await runScript('npx', ['hardhat', 'run', './scripts/testing/12_pledge.js', '--network', 'localhost']);
    console.log('All scripts executed successfully');
  } catch (err) {
    console.error('Error in script execution:', err);
  }
})();