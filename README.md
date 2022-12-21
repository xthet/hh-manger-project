crowdfunder
add campaign
cancel campaign
update campaign
withdraw proceeds

campaignId is campaign contract Address

mapping
campaignId => campaign struct

events
campaign added
campaign canceled
campaign expired
campaign successful
campaign updated

getter functions
getCampaign(campaignId)
getCampaigns
getAmountMade(campaignId) -- current balance



campaign -- struct

campaign {
  campaign id
  creator
  creator type (sole or team)
  title
  description
  tags
  goalAmount
  funding deadline
  current balance
  state (expired, successful, inprogess)
  address => contributions mapping
}


getBalance
getDetails