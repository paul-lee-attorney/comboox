
import dotenv from "dotenv";
dotenv.config();
import { defineConfig } from "hardhat/config";
import hardhatVerify from "@nomicfoundation/hardhat-verify";
import hardhatEthers from "@nomicfoundation/hardhat-ethers";
import hardhatTypechain from "@nomicfoundation/hardhat-typechain";
import hardhatMocha from "@nomicfoundation/hardhat-mocha";
import hardhatEthersChaiMatchers from "@nomicfoundation/hardhat-ethers-chai-matchers";
import hardhatNetworkHelpers from "@nomicfoundation/hardhat-network-helpers";

export default defineConfig({
  plugins:[
    hardhatVerify,
    hardhatEthers,
    hardhatTypechain,
    hardhatMocha,
    hardhatEthersChaiMatchers,
    hardhatNetworkHelpers,    
  ],
  solidity: {
    version: "0.8.8",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      blockGasLimit: 30_000_000,
      gas: 16_000_000,
      type:"edr-simulated",
      url: "http://127.0.0.1:8545",
      initialDate: "2025-01-01T00:00:00Z",
    },
    arbitrumSepolia: {
      type: "http",
      url: `https://arb-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_SEPOLIA_KEY}`,
      accounts: [process.env.SEPOLIA_PRIV_KEY_0, process.env.SEPOLIA_PRIV_KEY_1],
    },
    mainnet: {
      type: "http",
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_MAINNET_KEY}`,
      accounts: [process.env.MAINNET_PRIV_KEY_0, process.env.MAINNET_PRIV_KEY_1, process.env.MAINNET_PRIV_KEY_2],
    },
    arbitrumOne: {
      type: "http",
      url: `https://arb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_ARB_KEY}`,
      accounts: [process.env.ARB_PRIV_KEY_0, process.env.ARB_PRIV_KEY_1, process.env.ARB_PRIV_KEY_2],
    },
  },
  verify:{
    etherscan:{
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
    // apiKey: {
    //   arbitrumOne: process.env.ETHERSCAN_API_KEY, // Arbiscan
    //   arbitrumSepolia: process.env.ETHERSCAN_API_KEY,
    // },
    // customChains: [
    //   {
    //     network: 'arbitrumSepolia',
    //     chainId: 421614,
    //     urls: {
    //       apiURL: "https://api-sepolia.arbiscan.io/api",
    //       browserURL: "https://sepolia.arbiscan.io/",
    //     }
    //   }
    // ]
  },
  sourcify: {
    enabled: true
  },
});
