// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Campaign.sol";

// errors
error CrowdFunder__NoSuchCampaign(address _campaignAddress);
error CrowdFunder__NotCreator(address _caller, address _campaignAddress);
error CrowdFunder__CampaignStillActive(address _campaignAddress);

contract CrowdFunder {
  using SafeMath for uint256;

  event CampaignAdded(
    address indexed _campaignAddress,
    address indexed _creator,
    uint256 _creatorType,
    string _creatorName,
    string _title,
    string _description,
    string[] _tags,
    uint256 _goalAmount,
    uint256 _duration
  );

  event CampaignCanceled(
    address indexed _campaignAddress
  );


  mapping (address => Campaign) campaigns;
  mapping (address => address) campaignCreators;
  mapping (address => bool) campaignAddresses;

  modifier isCreator(address _campaignAddress) {
    if(msg.sender != campaignCreators[_campaignAddress]){
      revert CrowdFunder__NotCreator(msg.sender, _campaignAddress);
    }
    _;
  }

  function addCampaign (
    uint64 _creatorType,
    string memory _creatorName,
    string memory _title, 
    string memory _description,
    string[] memory _tags, 
    uint256 _goalAmount,
    uint256 _duration
    ) external {
    // uint256 raiseUntil = block.timestamp.add(duration.mul(1 days));
    Campaign newCampaign = new Campaign(payable(msg.sender), _creatorType, _creatorName, _title, _description, _tags, _goalAmount, _duration);
    campaigns[address(newCampaign)] = newCampaign;
    campaignAddresses[address(newCampaign)] = true;
    campaignCreators[address(newCampaign)] = msg.sender;
    emit CampaignAdded(address(newCampaign), msg.sender, _creatorType, _creatorName, _title, _description, _tags, _goalAmount, _duration);
  }

  function cancelCampaign (address _campaignAddress) public isCreator(_campaignAddress) {
    if(uint(campaigns[_campaignAddress].getCampaignState()) == 1){revert CrowdFunder__CampaignStillActive(_campaignAddress);}
    delete(campaigns[_campaignAddress]);
    delete(campaignAddresses[_campaignAddress]);
    // emit CampaignCanceled(_campaignAddress, campaigns[_campaignAddress].creator(), campaigns[_campaignAddress].goalAmount());
    emit CampaignCanceled(_campaignAddress);
  }

  function getCampaign(address _campaignAddress) external view returns (Campaign.CampaignObject memory) {
    if(!campaignAddresses[_campaignAddress]){revert CrowdFunder__NoSuchCampaign(_campaignAddress);}
    return campaigns[_campaignAddress].getCampaignDetails();
  }
}