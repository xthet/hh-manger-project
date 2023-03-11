import { network, deployments, ethers, getNamedAccounts } from "hardhat"

let campaign
const campaignAddress = "0x9344535B4EA90c1E26A07704344a5AB5e21bd7B3"

async function makeReward(){
  campaign = await ethers.getContractAt("Campaign", campaignAddress)
  try {
    const getDeadline = await campaign.deadline()
    const addRewardTx = await campaign.makeReward(
      ethers.utils.parseEther("0.23"),
      "Digital Copy with Figurine",
      "A digital copy of the game for STEAM (PC/MAC) +  Exclusive Handpainted 'Dreadnought' Figurine and includes exclusive backer-only ",
      ["Digital Artbook", "Original Soundtrack", "Discord Title", "Digital Wallpaper" , "Beta Access to the Game during development."],
      getDeadline,
      8,
      false,
      ["_AITW"] // digital
    )
    const addRewardTxR = await addRewardTx.wait(1)
    console.log(addRewardTxR)
  } catch (error) {
    console.log(error)    
  }
}

makeReward()
  .then(()=>{process.exit(0)})
  .catch((e)=>
  {
    console.log(e)
    process.exit(1)
  })

// uint256 _price, string memory _title, 
// string memory _description, string[] memory _perks, 
// uint256 _deadline, uint256 _quantity, bool _infinite string[] memory _shipsTo