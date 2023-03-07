import { network, deployments, ethers, getNamedAccounts } from "hardhat"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
import { developmentChains } from "../helper-hardhat-config"
import { CrowdFunder } from "../typechain-types"

let crowdFunder: CrowdFunder
let addCampaignTx: ContractTransaction
let addCampaignTxR: ContractReceipt


async function makeCampaign()
{
  crowdFunder = await ethers.getContract("CrowdFunder")
  console.log(crowdFunder.address)

  const { creator } = await getNamedAccounts()
  console.log(`creator: ${creator}`)

  addCampaignTx = await crowdFunder.addCampaign(
    "Piratopia: Raiders of Pirate Bay",
    "Conquer the Seven Seas in this open-world Pirate Ship multiplayer game for PC!",
    "P2E",
    ["adventure games", "video games", "play to earn games"],
    ethers.utils.parseEther("5.25"),
    BigNumber.from("1296000"),
    "ipfs://QmYZ5bafXB6ttnfAFQT9mQEMNto9h6iDEtaHhj3GvcLhBJ?filename=piratopiaart.jpg",
    "ipfs://QmZLsHtDgbFNezw3refECF4frX9KrFJJjPMEtCYyPSEfAS?filename=piretopiaCampaign.json",
    "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    "0x3A7ec66b1054330976E2F0fD1296720e3eBc0Ff8"
  )
  addCampaignTxR = await addCampaignTx.wait(1)
  const campaignAddress = addCampaignTxR.events![0].args!._campaignAddress
  const creatorAddr = addCampaignTxR.events![0].args!._creator
  console.log("Campaign Added")
  console.log(`creator: ${creatorAddr}`)
  console.log(`Campaign Address at: ${campaignAddress}`)
}

makeCampaign()
  .then(()=>{process.exit(0)})
  .catch((e)=>
  {
    console.log(e)
    process.exit(1)
  })