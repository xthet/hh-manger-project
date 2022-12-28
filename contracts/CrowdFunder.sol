// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Campaign.sol";

// errors
error CrowdFunder__NoSuchCampaign(address _campaignAddress);
error CrowdFunder__NotCreator(address _caller, address _campaignAddress);

contract CrowdFunder {
  using SafeMath for uint256;

  event CampaignAdded(
    address indexed _campaignAddress,
    address indexed _creator,
    uint256 _creatorType,
    string _title,
    string _description,
    string[] _tags,
    uint256 _goalAmount,
    uint256 _duration
  );

  event CampaignUpdated(
    address indexed _campaignAddress,
    string _title,
    string _description,
    uint256 _duration
  );

  event CampaignCanceled(
    address indexed _campaignAddress
  );

  event CampaignEnded(
    address indexed _campaignAddress
  );


  mapping (address => Campaign) campaigns;
  mapping (Campaign => address) campaignCreators;
  mapping (address => bool) campaignAddresses;

  modifier isCreator(address _campaignAddress) {
    if(msg.sender != campaignCreators[campaigns[_campaignAddress]]){revert CrowdFunder__NotCreator(msg.sender, _campaignAddress);}
    _;
  }


  function addCampaign (
    uint64 _creatorType,
    string memory _title, 
    string memory _description,
    string[] memory _tags, 
    uint256 _goalAmount,
    uint256 _duration
    ) external {
    // uint256 raiseUntil = block.timestamp.add(duration.mul(1 days));
    Campaign newCampaign = new Campaign(payable(msg.sender), _creatorType, _title, _description, _tags, _goalAmount, _duration);
    campaigns[address(newCampaign)] = newCampaign;
    campaignAddresses[address(newCampaign)] = true;
    campaignCreators[newCampaign] = msg.sender;
    emit CampaignAdded(address(newCampaign), msg.sender, _creatorType, _title, _description, _tags, _goalAmount, _duration);
  }

  function cancelCampaign (address _campaignAddress) public isCreator(_campaignAddress) {
    delete(campaigns[_campaignAddress]);
    delete(campaignAddresses[_campaignAddress]);
    // emit CampaignCanceled(_campaignAddress, campaigns[_campaignAddress].creator(), campaigns[_campaignAddress].goalAmount());
    emit CampaignCanceled(_campaignAddress);
  }

  function updateCampaign(address _campaignAddress, string memory  _newTitle, string memory _newDescription, uint256 _addedTime) public 
  isCreator(_campaignAddress)
  {
    if(!campaignAddresses[_campaignAddress]){revert CrowdFunder__NoSuchCampaign(_campaignAddress);}
    Campaign campaign = campaigns[_campaignAddress];
    if(bytes(_newTitle).length > 0){campaign.updateTitle(_newTitle);}
    if(bytes(_newDescription).length > 0){campaign.updateDescription(_newDescription);}
    if(_addedTime > 0){campaign.updateDuration(_addedTime);}

    emit CampaignUpdated(_campaignAddress, campaign.title(), campaign.description(), campaign.duration());
  }

  function getCampaign(address _campaignAddress) external view returns (Campaign.CampaignObject memory) {
    if(!campaignAddresses[_campaignAddress]){revert CrowdFunder__NoSuchCampaign(_campaignAddress);}
    return campaigns[_campaignAddress].getCampaignDetails();
  }

  function endCampaign(address _campaignAddress) public isCreator(_campaignAddress) {
    campaigns[_campaignAddress].endCampaign();
    emit CampaignEnded(_campaignAddress);
  }
}