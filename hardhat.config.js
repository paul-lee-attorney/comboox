
import dotenv from "dotenv";
dotenv.config();
import { defineConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-verify";

export default defineConfig({
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "localhost",
  networks: {
    hardhat: {
      blockGasLimit: 30_000_000,
      gas: 16_000_000,
      initialDate: "2025-01-01T00:00:00Z",
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    arbitrumSepolia: {
      // type: "http",
      url: `https://arb-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_SEPOLIA_KEY}`,
      accounts: [process.env.SEPOLIA_PRIV_KEY_0, process.env.SEPOLIA_PRIV_KEY_1],
    },
    mainnet: {
      // type: "http",
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_MAINNET_KEY}`,
      accounts: [process.env.MAINNET_PRIV_KEY_0, process.env.MAINNET_PRIV_KEY_1, process.env.MAINNET_PRIV_KEY_2],
    },
    arbitrumOne: {
      // type: "http",
      url: `https://arb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_ARB_KEY}`,
      accounts: [process.env.ARB_PRIV_KEY_0, process.env.ARB_PRIV_KEY_1, process.env.ARB_PRIV_KEY_2],
    },
  },
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
  sourcify: {
    enabled: true
  },
});
