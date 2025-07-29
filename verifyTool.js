#!/usr/bin/env node
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// 配置参数
const CONFIG = {
  network: 'arbitrum',
  addressFile: path.join(__dirname,'./server/src/contracts/contracts-address.json')
};

// 主执行函数
function main() {
  try {
    // 读取地址文件
    const rawData = fs.readFileSync(CONFIG.addressFile);
    const contracts = JSON.parse(rawData);

    // 遍历所有合约
    for (const [contractName, contractAddress] of Object.entries(contracts)) {
      console.log(`\n🔍 Verifying ${contractName} at ${contractAddress}...`);
      
      // 构建验证命令
      const verifyCommand = `npx hardhat verify ${contractAddress} --network ${CONFIG.network}`;
      
      try {
        // 执行验证
        const output = execSync(verifyCommand, { stdio: 'inherit' });
        console.log(`✅ ${contractName} verified successfully`);
      } catch (error) {
        console.error(`❌ Failed to verify ${contractName}: ${error.message}`);
        // 如果需要失败后继续执行，移除下面这行
        process.exit(1);
      }
    }
    
    console.log('\n🎉 All contracts verified!');
  } catch (error) {
    console.error(`💥 Critical error: ${error.message}`);
    process.exit(1);
  }
}

// 执行主函数
main();