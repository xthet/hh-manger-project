import { moveBlocks } from "../utils/move-blocks"
const BLOCKS = 2
const SLEEP_AMOUNT = 1000

async function mine()
{
  await moveBlocks(BLOCKS, SLEEP_AMOUNT)
}

mine()
  .then(()=>{process.exit(0)})
  .catch((e)=>
  {
    console.log(e)
    process.exit(1)
  })