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
        "Furry Mittens",
        "Making mittens furry.",
        "Cooking",
        "cooking/household/culinary",
        "2",
        BigNumber.from("1296000"),
        "ipfs://campaignuri",
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

    describe("fundCampaign", function ()
    {
      it("donates to campaign successfully", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        console.log(donator)
        const crowdFunderv2 = crowdFunder.connect(accounts[1])
        const donationAmount = ethers.utils.parseEther("1")
        console.log(campaignAddress)
        const donateTx = await crowdFunderv2.donateToCampaign(campaignAddress,false,{ value: donationAmount })
        const donateTxR = await donateTx.wait(1)
        console.log(donateTxR.events)
      })
    })

    describe("getRefund", async function () 
    {
      it("refunds successfully", async () => {
        const accounts = await ethers.getSigners()
        const donator = accounts[1].address
        const crowdFunderv2 = crowdFunder.connect(accounts[1])
        console.log(crowdFunderv2.address)
        const donationAmount = ethers.utils.parseEther("2")
        const olderBalance = (await accounts[1].getBalance()).toString()
        // console.log(donateTxR.events)
        console.log(olderBalance)
        const donateTx = await crowdFunderv2.donateToCampaign(campaignAddress,true,{ value: donationAmount })
        const donateTxR = await donateTx.wait(1)
        const oldBalance = (await accounts[1].getBalance()).toString()
        // console.log(donateTxR.events)
        console.log(oldBalance)
        // const getCampaignDetails = await crowdFunderv2.getCampaign(campaignAddress)
        // console.log(getCampaignDetails)
        const refundTx = await crowdFunderv2.refundFromCampaign(campaignAddress)
        const refundTxR = await refundTx.wait(1)
        const newBalance = (await accounts[1].getBalance()).toString()
        assert(Number(newBalance) > Number(oldBalance))
        console.log(newBalance)

        console.log(refundTxR.events)
        console.log("successful")
      })
    })

    describe("cancelCampaign", function()
    {
      it("emits campaign canceled event", async () => {
        // const cancelCampaignTx = await crowdFunder.removeCampaign(campaignAddress)
        // expect(cancelCampaignTx).to.emit(crowdFunder, "CampaignCanceled")
      })
    })
  })