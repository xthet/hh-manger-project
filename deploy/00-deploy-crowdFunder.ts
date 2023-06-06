import { network, ethers } from "hardhat"
import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { developmentChains } from "../helper-hardhat-config"
import verify from "../utils/verify"

const deployCrowdFunder: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
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

  const campaignFactory = await deploy("CampaignFactory", {
    from: deployer,
    args: [],
    log: true,
    libraries: {
      RefunderLib: refunderLib.address
    },
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

  const args:any[] = [campaignFactory.address, rewardFactory.address]
  const crowdFunder = await deploy("CrowdFunder", {
    from: deployer,
    args: args,
    log: true,
    libraries: {
      RefunderLib: refunderLib.address
    },
    waitConfirmations: waitBlockConfirmations
  })

  if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...")
    await verify(refunderLib.address, [])
    await verify(campaignFactory.address, [])
    await verify(rewardFactory.address, [])
    await verify(crowdFunder.address, args)
  }
  log("==========================")
}

export default deployCrowdFunder
deployCrowdFunder.tags = ["all", "crowdfunder"]