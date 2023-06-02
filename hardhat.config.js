
// import { HardhatUserConfig } from "hardhat/config";
require ("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");

require("hardhat-deploy");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
// require('hardhat-reset');
require("dotenv").config();


require("./tasks/block-number");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    outputSelection: {
      "*": {
        "*": ["abi"]
      }
    },
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.1",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.8",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  networks:{
    hardhat: {}, // 默认的 Hardhat 开发网络
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    goerli: {
      url: "https://ethereum-goerli.publicnode.com" ,

      accounts: ["4ad668a0d0227ee9db9af2ff433fc95790722d43b2568e1a26110fef39cade45"]
    },
    bnbtest: {
      url: process.env.BNBTest_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []

    }
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY
  }
};


