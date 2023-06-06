import { network, ethers } from "hardhat"
import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { developmentChains } from "../helper-hardhat-config"
import verify from "../utils/verify"

const deployRewardFactory: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  const waitBlockConfirmations = chainId?.toString() == "31337" ? 1 : 5

  log("==========================")
  const refunderLib = await deploy("RefunderLib", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: waitBlockConfirmations
  })

  const rewardFactory = await deploy("RewardFactory", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      RefunderLib: refunderLib.address
    },
    waitConfirmations: waitBlockConfirmations
  })


  if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...")
    await verify(refunderLib.address, [])
    await verify(rewardFactory.address, [])
  }
  log("==========================")
}

export default deployRewardFactory
deployRewardFactory.tags = ["all", "rewardfactory"]