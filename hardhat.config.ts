import "@typechain/hardhat"
import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-ethers"
import "hardhat-gas-reporter"
import "dotenv/config"
import "solidity-coverage"
import "hardhat-deploy"
import "solidity-coverage"
import { HardhatUserConfig } from "hardhat/config"


const config: HardhatUserConfig = 
{
  solidity: {
    compilers: [{ version: "0.8.8" }, { version: "0.6.6" }, { version: "0.4.19" }, { version: "0.6.12" }]
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      allowUnlimitedContractSize: true
    },
    localhost: {
      chainId: 31337,
      allowUnlimitedContractSize: true
    },
    rinkeby:{
      chainId: 4,
      url: process.env.RINKEBY_RPC_URL,
      accounts: [process.env.PRIVATE_KEY!],
      timeout: 1000000
    },
    goerli:{
      chainId: 5,
      url: process.env.GOERLI_RPC_URL,
      accounts: [process.env.PRIVATE_KEY!],
      timeout: 1000000
    },
    fuji:{
      chainId: 43113,
      url: process.env.FUJI_RPC_URL,
      accounts: [process.env.ALPHA_PRIVATE_KEY!],
      timeout: 1000000
    }
  },
  namedAccounts: {
    deployer: {
      default: 0, 
    },
    donator: {
      default: 1,
    }
  },
  gasReporter: {
    enabled: true,
    outputFile: "gas-report.txt",
    noColors: true,
    currency: "USD",
    coinmarketcap: process.env.MARKETCAP_API_KEY,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  mocha: {
    timeout: 100000000,
  }
}

export default config
