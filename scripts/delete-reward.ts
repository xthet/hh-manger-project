import { network, deployments, ethers, getNamedAccounts } from "hardhat"

let campaign
const campaignAddress = "0x9344535B4EA90c1E26A07704344a5AB5e21bd7B3"

async function deleteReward(){
  campaign = await ethers.getContractAt("Campaign", campaignAddress)
  try {
    const deleteTx = await campaign.deleteReward(ethers.utils.parseEther("0.23"))
    await deleteTx.wait(1)
    console.log("successful")
  } catch (error) {
    console.log(error)
  }
}

deleteReward()
  .then(()=>{process.exit(0)})
  .catch((e)=>
  {
    console.log(e)
    process.exit(1)
  })