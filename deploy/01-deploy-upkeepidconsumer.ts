import { network, ethers } from "hardhat"
import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { developmentChains, networkConfig } from "../helper-hardhat-config"
import verify from "../utils/verify"
import hasKey from "../utils/hasKey"

const deployUpkeepIDConsumer: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  const waitBlockConfirmations = chainId?.toString() == "31337" ? 1 : 4

  log("==========================")
  if(hasKey(networkConfig, chainId!))
  { const args:any[] = [networkConfig[5].linkTokenAddress, networkConfig[chainId].registrarAddress, networkConfig[chainId].registryAddress]
    const upkeepIDConsumer = await deploy("UpkeepIDConsumer", {
      from: deployer,
      args: args,
      log: true,
      waitConfirmations: waitBlockConfirmations
    })

    // if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    //   log("Verifying...")
    //   await verify(upkeepIDConsumer.address, args)
    // }
    log("==========================")
  }
}

export default deployUpkeepIDConsumer
deployUpkeepIDConsumer.tags = ["all", "upkeepidconsumer"]