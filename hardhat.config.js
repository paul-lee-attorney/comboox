import "dotenv/config";
import { defineConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-chai-matchers";
import hardhatEthers from "@nomicfoundation/hardhat-ethers";
import hardhatVerify from "@nomicfoundation/hardhat-verify";

export default defineConfig({
  plugins: [
    hardhatEthers,
    hardhatVerify
  ],
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      type: "edr-simulated",
      chainId: 31337,
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
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
      // customChains: [
      //   {
      //     network: "arbitrumSepolia",
      //     chainId: 421614,
      //     urls: {
      //       apiURL: "https://api-sepolia.arbiscan.io/api",
      //       browserURL: "https://sepolia.arbiscan.io/",
      //     },
      //   },
      //   {
      //     network: "arbitrumOne",
      //     chainId: 42161,
      //     urls: {
      //       apiURL: "https://api.arbiscan.io/api",
      //       browserURL: "https://arbiscan.io/",
      //     },
      //   },
      // ],
    },
  },
  sourcify: {
    enabled: true,
  },
  blockscout: {
    enabled: false,
  },
});
