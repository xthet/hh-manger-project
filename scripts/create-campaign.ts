import { network, deployments, ethers, getNamedAccounts } from "hardhat"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
import { developmentChains } from "../helper-hardhat-config"
import { CrowdFunder } from "../typechain-types"

let crowdFunder: CrowdFunder
let addCampaignTx: ContractTransaction
let addCampaignTxR: ContractReceipt


async function makeCampaign()
{
  // crowdFunder = await ethers.getContract("CrowdFunder")
  // console.log(crowdFunder.address)

  // addCampaignTx = await crowdFunder.addCampaign(
  //   "Help Jane Lynn", 
  //   "Help Jane Lynn reach her goal",
  //   "Goodwill", 
  //   ["crowdfund", "actor", "film making"],
  //   2, 
  //   BigNumber.from("259200")
  // )
  // addCampaignTxR = await addCampaignTx.wait(1)
  // const campaignAddress = addCampaignTxR.events![0].args!._campaignAddress
  // console.log("Campaign Added")
  // // console.log(addCampaignTxR)
  // console.log(campaignAddress)
}

makeCampaign()
  .then(()=>{process.exit(0)})
  .catch((e)=>
  {
    console.log(e)
    process.exit(1)
  })