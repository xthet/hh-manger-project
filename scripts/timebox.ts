import { network, deployments, ethers, getNamedAccounts } from "hardhat"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
import { developmentChains } from "../helper-hardhat-config"
import { UpkeepIDConsumer } from "../typechain-types"

let upkeepidconsumer: UpkeepIDConsumer
let timeboxTx: ContractTransaction
let timeboxTxR: ContractReceipt


async function timeBox()
{
  upkeepidconsumer = await ethers.getContract("UpkeepIDConsumer")
  console.log(upkeepidconsumer.address)

  const { creator } = await getNamedAccounts()
  console.log(`creator: ${creator}`)

  timeboxTx = await upkeepidconsumer.registerAndPredictID(
    "Piratopia: Raiders of Pirate Bay",
    "0x",
    "0x4Fc7Bc4877302A0D1D38fc9b734D6fC4F731986b",
    BigNumber.from("500000"),
    "0x3DAe272A6C397F8dF15A4ACe05E38c23C1787Dca",
    "0x",
    BigNumber.from("10000000000000000000"),
    0
  )
  timeboxTxR = await timeboxTx.wait(1)
  // const upkeepidconsumerAddress = addUpkeepIDConsumerTxR.events![0].args!._upkeepidconsumerAddress
  // const creatorAddr = addUpkeepIDConsumerTxR.events![0].args!._creator
  console.log("UpkeepIDConsumer Added")
  console.log(timeboxTxR)
  // console.log(`UpkeepIDConsumer Address at: ${upkeepidconsumerAddress}`)
}

timeBox()
  .then(()=>{process.exit(0)})
  .catch((e)=>
  {
    console.log(e)
    process.exit(1)
  })