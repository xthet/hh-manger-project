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
    "0x4B5a2B7b5438A79797698570AC9D45155D3Bb0e3",
    "Furry Mittens",
    "Making mittens furry.",
    "Cooking",
    ["cooking", "household", "culinary"],
    2,
    BigNumber.from("1296000"), // 15days
    "ipfs://campaignuri",
    "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    "0x9806cf6fBc89aBF286e8140C42174B94836e36F2",
    "0x02777053d6764996e594c3E88AF1D58D5363a2e6"
  ]

  const campaign = await deploy("Campaign", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: waitBlockConfirmations
  })

  await verify(campaign.address, args)


  // if(!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
  //   log("Verifying...")
  //   await verify(campaign.address, args)
  // }
  log("==========================")
}

export default deployCampaign
deployCampaign.tags = ["all", "campaign"]