import { network, ethers } from "hardhat"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { developmentChains } from "../helper-hardhat-config"
import verify from "../utils/verify"

const deployCampaign: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId = network.config.chainId
  const waitBlockConfirmations = chainId?.toString() == "31337" ? 1 : 4

  log("==========================")
  const args:any[] = [
    deployer,
    1, 
    "Help Jane Lynn", 
    "help Jane Lynn reach her goal",
    ["movie", "acting", "fundraise"],
    ethers.utils.parseEther("3"), // 3 eth 
    BigNumber.from("345600") // 3 days
  ]

  const campaign = await deploy("Campaign", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: waitBlockConfirmations
  })

  if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("Verifying...")
    await verify(campaign.address, args)
  }
  log("==========================")
}

export default deployCampaign
deployCampaign.tags = ["all", "campaign"]