import { network, deployments, ethers, getNamedAccounts } from "hardhat"

let campaign
const campaignAddress = "0x2d6A68233AEAc3De13622F593212b9D5a59e54B8"
const newURI = ""

async function updateURI(){
  campaign = await ethers.getContractAt("Campaign", campaignAddress)
  try {
    const updateTx = await campaign.updateCampaignURI(newURI)
    const updateTxR = await updateTx.wait(1)
    const getURI = await campaign.s_campaignURI()
    console.log(getURI)
  } catch (error) {
    console.log(error)    
  }
}

updateURI()
  .then(()=>{process.exit(0)})
  .catch((e)=>
  {
    console.log(e)
    process.exit(1)
  })