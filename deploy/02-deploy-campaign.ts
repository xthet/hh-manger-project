import { network, ethers } from "hardhat"
import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { developmentChains } from "../helper-hardhat-config"
import verify from "../utils/verify"
import { BigNumber } from "ethers"

const deployCampaign: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  const waitBlockConfirmations = chainId?.toString() == "31337" ? 1 : 5

  log("==========================")
  const args:any[] = [
    deployer,
    "Piratopia: Raiders of Pirate Bay",
    "A P2E masterpiece on the AVAX chain",
    "P2E",
    ["arcade games", "adventure games", "web3 gaming"],
    ethers.utils.parseEther("6.75"),
    BigNumber.from("1296000"),
    "ipfs://QmV9inF2YC5MFUHWwWaCBEVJzj9aGSKmpay7mPSJDjBC4w"
  ]
  const campaign = await deploy("Campaign", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: waitBlockConfirmations
  })

  // if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
  //   log("Verifying...")
  //   await verify(campaign.address, args)
  // }
  log("==========================")
}

export default deployCampaign
deployCampaign.tags = ["all", "campaign"]