#!/usr/bin/env node
import { exec } from 'child_process';
import { readFileSync } from 'fs';
import { join } from 'path';

const __dirname = import.meta.dirname;

// 配置参数
const CONFIG = {
  network: 'arbitrumOne',
  addressFile: join(__dirname,'../server/src/260311-Arbi/contracts-address.json'),
  concurrency: 4,
  dispatchIntervalMs: 500,
};

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let nextDispatchAt = 0;

async function waitForDispatchSlot() {
  const now = Date.now();
  const waitMs = Math.max(0, nextDispatchAt - now);
  nextDispatchAt = Math.max(nextDispatchAt, now) + CONFIG.dispatchIntervalMs;

  if (waitMs > 0) {
    await sleep(waitMs);
  }
}

function runVerifyCommand(command) {
  return new Promise((resolve, reject) => {
    exec(command, { maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
      if (error) {
        reject({ error, stdout, stderr });
        return;
      }
      resolve({ stdout, stderr });
    });
  });
}

async function verifySingle(contractName, contractAddress, workerId) {
  console.log(`\n[Worker-${workerId}] Verifying ${contractName} at ${contractAddress} ...\n`);

  const verifyCommand = `npx hardhat verify etherscan ${contractAddress} --network ${CONFIG.network}`;

  try {
    await waitForDispatchSlot();
    const { stdout, stderr } = await runVerifyCommand(verifyCommand);
    if (stdout) process.stdout.write(stdout);
    if (stderr) process.stderr.write(stderr);

    console.log(`[Worker-${workerId}] SUCCESS ${contractName} \n`);
    return { contractName, contractAddress, ok: true };
    
  } catch (result) {
    if (result?.stdout) process.stdout.write(result.stdout);
    if (result?.stderr) process.stderr.write(result.stderr);

    const message = result?.error?.message ?? 'unknown error';
    console.error(`[Worker-${workerId}] FAILED ${contractName}: ${message} \n`);
    return { contractName, contractAddress, ok: false, error: message };
  }
}

// 主执行函数
async function main() {
  try {
    // 读取地址文件
    const rawData = readFileSync(CONFIG.addressFile);
    const contracts = JSON.parse(rawData);
    const entries = Object.entries(contracts);

    if (entries.length === 0) {
      console.log('No contracts to verify.');
      return;
    }

    const workerCount = Math.min(CONFIG.concurrency, entries.length);
    let nextIndex = 0;
    const results = [];

    async function worker(workerId) {
      while (true) {
        const current = nextIndex;
        nextIndex += 1;

        if (current >= entries.length) {
          return;
        }

        const [contractName, contractAddress] = entries[current];
        const result = await verifySingle(contractName, contractAddress, workerId);
        results.push(result);
      }
    }

    await Promise.all(
      Array.from({ length: workerCount }, (_, i) => worker(i + 1))
    );

    const failed = results.filter((item) => !item.ok);
    const passed = results.length - failed.length;

    console.log(`\nVerification finished. Total: ${results.length}, Passed: ${passed}, Failed: ${failed.length}`);

    if (failed.length > 0) {
      console.error('\nFailed contracts:');
      for (const item of failed) {
        console.error(`- ${item.contractName} (${item.contractAddress})`);
      }
      process.exit(1);
    }
    
    console.log('\nAll contracts verified successfully.');
  } catch (error) {
    console.error(`\nCritical error: ${error.message}`);
    process.exit(1);
  }
}

// 执行主函数
await main();