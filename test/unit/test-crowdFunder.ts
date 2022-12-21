import { assert, expect } from "chai"
import { BigNumber, ContractTransaction } from "ethers"
import { network, deployments, ethers, getNamedAccounts } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { CrowdFunder } from "../../typechain-types"


!developmentChains.includes(network.name)
  ? describe.skip
  : describe("CrowdFunder Unit Tests", function(){
    let crowdFunder: CrowdFunder
    let crowdFunderContract: CrowdFunder
    let deployer: string
    let addCampaignTx: ContractTransaction
    
    beforeEach(async () => {
      deployer = (await getNamedAccounts()).deployer
      await deployments.fixture(["crowdfunder"])
      crowdFunder = await ethers.getContract("CrowdFunder", deployer)
      addCampaignTx = await crowdFunder.addCampaign(
        1, 
        "Help Jane Lynn", 
        "help Jane Lynn reach her goal",
        ["movie", "acting", "fundraise"],
        10,
        10000000000
      )
    })

    describe("addCampaign", function ()
    {
      it("emits campaign added event", async () => {
        await addCampaignTx.wait(1)
        expect (addCampaignTx).to.emit(crowdFunder, "CampaignAdded")
      })

      it("gives the campaign contract an address", async () => {
        console.log(network.config.chainId)
        const addCampaignTxR = await addCampaignTx.wait(1)
        // console.log(addCampaignTxR)
        const campaignAddress = addCampaignTxR.events![0].args!._campaignAddress
        console.log(campaignAddress)
        assert(campaignAddress)
      })
    })

    describe("cancelCampaign", function()
    {
      it("emits campaign canceled event", async () => {
        const addCampaignTxR = await addCampaignTx.wait(1)
        const campaignAddress = addCampaignTxR.events![0].args!._campaignAddress
        const cancelCampaignTx = await crowdFunder.cancelCampaign(campaignAddress)
        expect(cancelCampaignTx).to.emit(crowdFunder, "CampaignCanceled")
      })
    })

    describe("updateCampaign", function()
    {
      it("emits campaign updated event with details", async () => {
        const addCampaignTxR = await addCampaignTx.wait(1)
        // console.log(addCampaignTxR)
        const campaignAddress = addCampaignTxR.events![0].args!._campaignAddress
        const getCampaignDetails = await crowdFunder.getCampaign(campaignAddress)
        const updateCampaignTx = await crowdFunder.updateCampaign(campaignAddress, "Jane Lynn", "", BigNumber.from("30000"))
        await updateCampaignTx.wait(1)
        const getNewCampaignDetails = await crowdFunder.getCampaign(campaignAddress)
        console.log(getNewCampaignDetails)
        expect(updateCampaignTx).to.emit(crowdFunder, "CampaignUpdated")
      })
    })

  })