import { assert, expect } from "chai"
import { BigNumber, ContractReceipt, ContractTransaction } from "ethers"
import { network, deployments, ethers, getNamedAccounts } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { Campaign } from "../../typechain-types"

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Campaign Unit Tests", function () {
    let campaign: Campaign
    let deployer: string
    let campaignAddress: any
    let timeGiven: number
    const donationAmount = ethers.utils.parseEther("1")

    beforeEach(async () => {
      deployer = (await getNamedAccounts()).deployer
      await deployments.fixture(["campaign"])
      campaign = await ethers.getContract("Campaign", deployer)
      campaignAddress = campaign.address
      const { duration } = await campaign.getCampaignDetails()
      timeGiven = duration.toNumber()
    })

    describe("constructor", function ()
    {
      it("campaign is in fundraising state", async () => {
        const campaignState = await campaign.getCampaignState()
        assert(campaignState.toString() == "1") // 1 means fundraising
      })
    })

    describe("donate", function ()
    {
      it("reverts if creator tries to donate", async () => {
        await expect(campaign.donate({ value: donationAmount })).to.be.reverted
      })

      it("successfully adds donations and emits event", async ()=>{
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])

        const oldBalance = await campaign.getBalance()

        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        const donateTxR = await donateTx.wait(1)
        // console.log(donateTxR.events![0].args)
        const donatorBalance = await donatorCampaign.donations(donator)
        assert.equal(donationAmount.toString(), donatorBalance.toString())

        const newBalance = await campaign.getBalance()
        assert.equal((newBalance.sub(donationAmount)).toString(), oldBalance.toString())

        expect(donateTx).to.emit(campaign, "FundingRecieved")
      })
    })

    describe("checkUpkeep", function ()
    {
      it("emits campaign successful if goal is reached", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        const donateTxR = await donateTx.wait(1)

        const performUpkeepTx = await campaign.performUpkeep([])

        const campaignState = await campaign.getCampaignState()

        const { upkeepNeeded } = await campaign.callStatic.checkUpkeep("0x")
        assert(upkeepNeeded) // because goalReached == true
        assert(campaignState.toString() == "0")
        expect(performUpkeepTx).to.emit(campaign, "CampaignSuccessful")
      })

      it("returns false if there is no balance", async () => {
        await network.provider.send("evm_increaseTime", [timeGiven + 1]) // bool timepassed is now = true
        await network.provider.send("evm_mine", [])
        const { upkeepNeeded } = await campaign.callStatic.checkUpkeep("0x")
        assert(!upkeepNeeded) // because hasBalance == false
      })

      it("returns false if it is not fundraising", async () => {
        await network.provider.send("evm_increaseTime", [timeGiven + 1]) // bool timepassed is now = true
        await network.provider.send("evm_mine", [])

        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        const donateTxR = await donateTx.wait(1)

        const performUpkeepTx = await campaign.performUpkeep([]) // changes state to Expired
        
        const campaignState = await campaign.getCampaignState()
        const { upkeepNeeded } = await campaign.callStatic.checkUpkeep("0x") 
        // checking again after state has changed isOpen is now false
        assert.equal(campaignState == 2, upkeepNeeded == false)
      })

      it("returns false if ")
    })

    describe("getCampaignDetails", function () {
      it("returns all campaign details", async ()=>{
        const campaignDetails = await campaign.getCampaignDetails()
        assert(
          campaignDetails.creator &&
          campaignDetails.creatorType &&
          campaignDetails.title &&
          campaignDetails.description &&
          campaignDetails.tags &&
          "goalAmount" in campaignDetails && 
          "duration" in campaignDetails && 
          "currentBalance" in campaignDetails &&
          "currentState" in campaignDetails
        )
        // console.log(campaignDetails)
      })
    })
  })