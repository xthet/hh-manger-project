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
        const campaignState = await campaign.c_state()
        assert(campaignState.toString() == "0") // 1 means fundraising
      })
    })

    describe("donate", function ()
    {
      it("reverts if creator tries to donate", async () => {
        const donationAmount = ethers.utils.parseEther("5")
        await expect(campaign.donate(deployer,{ value: donationAmount })).to.be.reverted
      })

      // it("successfully adds donations and emits event", async ()=>{
      //   const accounts = await ethers.getSigners()
      //   const donator = accounts[1].address
      //   const donatorCampaign = campaign.connect(accounts[1])

      //   const oldBalance = await campaign.getBalance()
      //   const donationAmount = ethers.utils.parseEther("5")

      //   const donateTx = await donatorCampaign.donate({ value: donationAmount })
      //   const donateTxR = await donateTx.wait(1)
      //   // console.log(donateTxR.events![0].args)
      //   const donatorBalance = await donatorCampaign.donations(donator)
      //   assert.equal(donationAmount.toString(), donatorBalance.toString())

      //   const newBalance = await campaign.getBalance()
      //   assert.equal((newBalance.sub(donationAmount)).toString(), oldBalance.toString())

      //   expect(donateTx).to.emit(campaign, "FundingRecieved")
      // })
    })

    describe("checkUpkeep", function ()
    {
      it("emits campaign successful if goal is reached", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("5")

        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        // here donationAmount was 5 eth 
        const donateTxR = await donateTx.wait(1)
        // goalReached == true
        const performUpkeepTx = await campaign.performUpkeep([])

        const campaignState = await campaign.c_state()

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
        const donationAmount = ethers.utils.parseEther("1")

        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        const donateTxR = await donateTx.wait(1)
        // here donationAmount was 1 eth goalAmount is 3 eth
        const performUpkeepTx = await campaign.performUpkeep([]) // changes state to Expired
        
        const campaignState = await campaign.c_state()
        const { upkeepNeeded } = await campaign.callStatic.checkUpkeep("0x") 
        // checking again after state has changed; isOpen is now false
        assert.equal(campaignState == 2, upkeepNeeded == false)
      })
    })

    describe("performUpkeep", function () {
      it("only runs if checkUpkeep is true", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("5")
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        const donateTxR = await donateTx.wait(1)
        // goalReached == true
        const performUpkeepTx = await campaign.performUpkeep([])
        assert(performUpkeepTx)
      })

      it("reverts if checkupKeep is false", async () => {
        await expect(campaign.performUpkeep("0x")).to.be.reverted
      })

      it("updates the campaign state and emits an event", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("5")
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        // here donationAmount was 5 eth 
        const donateTxR = await donateTx.wait(1)
        // goalReached == true
        const performUpkeepTx = await campaign.performUpkeep([])
        const campaignState = await campaign.c_state()
        assert(campaignState == 0)
        expect(performUpkeepTx).to.emit(campaign, "CampaignSuccessful")
      })
    })

    describe("payout", function () {
      it("fails if not called by creator", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("5")
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        // here donationAmount was 5 eth 
        const donateTxR = await donateTx.wait(1)
        // goalReached == true
        await network.provider.send("evm_increaseTime", [timeGiven + 1])
        await network.provider.send("evm_mine", [])
        const performUpkeepTx = await donatorCampaign.performUpkeep([])
        await performUpkeepTx.wait(1)
        await expect(donatorCampaign.payout()).to.be.reverted
      })

      it("fails if it is still fundraising", async () => {
        const campaignState = await campaign.c_state()
        assert(campaignState == 0)
        await expect(campaign.payout()).to.be.reverted
      })

      it("pays out for a successful campaign", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("5")
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        // here donationAmount was 5 eth 
        const donateTxR = await donateTx.wait(1)
        // goalReached == true

        await network.provider.send("evm_increaseTime", [timeGiven + 1])
        await network.provider.send("evm_mine", [])

        const performUpkeepTx = await campaign.performUpkeep([])
        await performUpkeepTx.wait(1)

        const payoutTx = await campaign.payout()
        await payoutTx.wait(1)
        // const newBalance = await campaign.getBalance()

        // assert(newBalance.toString() == "0")
      })

      it("pays out for an expired campaign", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("1")
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        // here donationAmount was 1 eth 
        const donateTxR = await donateTx.wait(1)
        // goalReached == false, hasBalance == true

        await network.provider.send("evm_increaseTime", [timeGiven + 1]) // bool timepassed is now = true
        await network.provider.send("evm_mine", [])

        const performUpkeepTx = await campaign.performUpkeep([])
        await performUpkeepTx.wait(1)

        const payoutTx = await campaign.payout()
        await payoutTx.wait(1)
        // const newBalance = await campaign.getBalance()

        // assert(newBalance.toString() == "0")        
      })

      it("disables refunds and emits event", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("5")
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        // here donationAmount was 5 eth 
        const donateTxR = await donateTx.wait(1)
        await network.provider.send("evm_increaseTime", [timeGiven + 1]) // bool timepassed is now = true
        await network.provider.send("evm_mine", [])
        
        const performUpkeepTx = await campaign.performUpkeep([])
        await performUpkeepTx.wait(1)

        const payoutTx = await campaign.payout()
        await payoutTx.wait(1)

        // const isRefunding = await campaign.nowRefundable()
        // assert(!isRefunding)
        expect(payoutTx).to.emit(campaign, "CreatorPaid")
      })
    })

    describe("refund", function () {
      it("only runs if refunds are enabled", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("1")
        const donateTx = await donatorCampaign.donate({ value: donationAmount })
        // here donationAmount was 1 eth 
        const donateTxR = await donateTx.wait(1)
        await expect(donatorCampaign.refund(donator)).to.be.reverted
      })

      it("successful if caller has donations", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const donatorCampaign = campaign.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("1")
        const donateTx = await donatorCampaign.donate(donator,{ value: donationAmount })
        // here donationAmount was 5 eth 
        const donateTxR = await donateTx.wait(1)
        console.log(donateTxR.events![0].args)
        const bal = await campaign.aggrDonations(donator)
        const bals = await campaign.getDonations(donator)
        console.log(bal, bals)
        // const performUpkeepTx = await campaign.performUpkeep([])
        // await performUpkeepTx.wait(1)

        const refundTx = await donatorCampaign.refund(donator)
        const refundTxR = await refundTx.wait(1)
        // console.log(refundTxR.events) 


        // await expect(donatorCampaign.refund()).to.satisfy
      })
    })

    // describe("getCampaignDetails", function () {
    //   it("returns all campaign details", async ()=>{
    //     const campaignDetails = await campaign.getCampaignDetails()
    //     assert(
    //       campaignDetails.creator &&
    //       campaignDetails.title &&
    //       campaignDetails.description &&
    //       campaignDetails.tags &&
    //       "goalAmount" in campaignDetails && 
    //       "duration" in campaignDetails && 
    //       "currentBalance" in campaignDetails &&
    //       "currentState" in campaignDetails
    //     )
    //     // console.log(campaignDetails)
    //   })
    // })
  })