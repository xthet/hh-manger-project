import { network, deployments, ethers, getNamedAccounts } from "hardhat"

let campaign
const campaignAddress = "0x3e3FDACb5148f11FDCc489483748195755e52c6f"

async function makeReward(){
  campaign = await ethers.getContract("Campaign", campaignAddress)
  try {
    const getDeadline = await campaign.deadline()
    const addRewardTx = await campaign.makeReward(
      ethers.utils.parseEther("0.022"),
      "Digital Copy with OST",
      "A digital copy of the game for STEAM (PC/MAC).",
      ["Digital Artbook", "Original Soundtrack"],
      getDeadline,
      100,
      true,
      ["_NW"] // digital
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

// ethers.utils.parseEther("0.23"),
// "Digital Copy with Figurine",
// "A digital copy of the game for STEAM (PC/MAC) +  Exclusive Handpainted 'Dreadnought' Figurine and includes exclusive backer-only ",
// ["Digital Artbook", "Original Soundtrack", "Discord Title", "Digital Wallpaper" , "Beta Access to the Game during development."],
// getDeadline,
// 8,
// false,
// ["_AITW"] // anywhere in the world

// ethers.utils.parseEther("0.022"),
// "Digital Copy with OST",
// "A digital copy of the game for STEAM (PC/MAC).",
// ["Digital Artbook", "Original Soundtrack"],
// getDeadline,
// 100,
// true,
// ["_NW"] // digital

// ethers.utils.parseEther("0.045"),
// "Special Backer Edition",
// "A digital copy of the game for STEAM (PC/MAC) and includes exclusive backer-only",
// ["Digital Artbook", "Original Soundtrack", "Discord Title", "Digital Wallpaper", "Beta Access to the Game during development"],
// getDeadline,
// 100,
// true,
// ["_NW"] // digital