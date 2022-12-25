import { assert, expect } from "chai"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
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
    let addCampaignTxR: ContractReceipt
    let campaignAddress: any
    
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
        BigNumber.from("10000000000")
      )
      addCampaignTxR = await addCampaignTx.wait(1)
      campaignAddress = addCampaignTxR.events![0].args!._campaignAddress
    })

    describe("addCampaign", function ()
    {
      it("emits campaign added event", async () => {
        await addCampaignTx.wait(1)
        expect (addCampaignTx).to.emit(crowdFunder, "CampaignAdded")
      })

      it("gives the campaign contract an address", async () => {
        // console.log(network.config.chainId)
        // console.log(campaignAddress)
        assert(campaignAddress)
      })
    })

    describe("cancelCampaign", function()
    {
      it("emits campaign canceled event", async () => {
        const cancelCampaignTx = await crowdFunder.cancelCampaign(campaignAddress)
        expect(cancelCampaignTx).to.emit(crowdFunder, "CampaignCanceled")
      })
    })

    describe("updateCampaign", function()
    {
      it("emits campaign updated event with details", async () => {
        const getCampaignDetails = await crowdFunder.getCampaign(campaignAddress)
        const updateCampaignTx = await crowdFunder.updateCampaign(campaignAddress, "Jane Lynn", "", BigNumber.from("30000"))
        await updateCampaignTx.wait(1)
        const getNewCampaignDetails = await crowdFunder.getCampaign(campaignAddress)
        // console.log(getNewCampaignDetails)
        expect(updateCampaignTx).to.emit(crowdFunder, "CampaignUpdated")
      })
    })

    describe("getCampaign", function()
    {
      it("returns campaign object if it exists", async () => {
        const getCampaignDetails = await crowdFunder.getCampaign(campaignAddress)
        // console.log(getCampaignDetails)
        assert(getCampaignDetails.creator.length > 0)
      })

      it("reverts if campaign doesn't exist", async () => {
        await expect(crowdFunder.getCampaign("0xe8387C8a8c1B74bB0A8d6c19b313468e3071E8D3"))
          .to.be.revertedWith("CrowdFunder__NoSuchCampaign")
      })
    })

    describe("endCampaign", function()
    {
      it("emits event and ends campaign", async () => {
        const endCampaignTx = await crowdFunder.endCampaign(campaignAddress)
        const { currentState } = await crowdFunder.getCampaign(campaignAddress)
        assert(currentState == 2)
        expect(endCampaignTx).to.emit(crowdFunder, "CampaignEnded")
      })
    })
  })