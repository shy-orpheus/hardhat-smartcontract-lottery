require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "https://eth-sepolia.g.alchemy.com/v2/PkF7F_24ySQ1iUu-b8tH80kaPQOHtIlZ"  //this is good practice
const PRIVATE_KEY = process.env.PRIVATE_KEY || "smthng"
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "smthng"
const COINMARKET_API_KEY = process.env.COINMARKET_API_KEY || "smthng"

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            // // If you want to do some forking, uncomment this
            // forking: {
            //   url: MAINNET_RPC_URL
            // }
            chainId: 31337,
        },
        localhost: {
            chainId: 31337,
        },
        sepolia: {
            url: SEPOLIA_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            //   accounts: {
            //     mnemonic: MNEMONIC,
            //   },
            saveDeployments: true,
            chainId: 11155111,
        },
        
        // mainnet: {
        //     url: MAINNET_RPC_URL,
        //     accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
        //     //   accounts: {
        //     //     mnemonic: MNEMONIC,
        //     //   },
        //     saveDeployments: true,
        //     chainId: 1,
        // },
        // polygon: {
        //     url: POLYGON_MAINNET_RPC_URL,
        //     accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
        //     saveDeployments: true,
        //     chainId: 137,
        // },
    },
    etherscan: {
        apiKey: {
          sepolia: ETHERSCAN_API_KEY,
        }
      },
    solidity: "0.8.18",
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
        player: {
            default: 1,
        },
},
gasReporter: {
    enabled: false,    //fale means disabled if u dont rly wanna use it rn // u can otherwise set as REPORT_GAS
    outputFile: "gas-report.txt",
    noColors: true,
    currency: "USD",
    coinmarketcap: COINMARKET_API_KEY,
    token: "MATIC",
  
},
mocha: {
    timeout: 400000, // 200 seconds max
}
}
