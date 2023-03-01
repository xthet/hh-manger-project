// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Campaign.sol";

// errors
error CrowdFunder__NotCreator(address _caller, address _campaignAddress);
error CrowdFunder__CampaignStillActive(address _campaignAddress);
error CrowdFunder__DonationFailed(address _campaignAddress);
error CrowdFunder__RefundFailed(address _campaignAddress);
error CrowdFunder__CampaignNotRefundable(address _campaignAddress);

contract CrowdFunder {
  using SafeMath for uint256;

  event UserAdded(
    address indexed _address,
    string _username,
    string _twitter,
    string _email,
    string _bio
  );

  event CampaignAdded(
    address indexed _campaignAddress,
    address indexed _creator
  );

  event CampaignFunded(
    address indexed _funder,
    address indexed _campaignAddress
  );

  event CampaignShrunk(
    address indexed _withdrawer,
    address indexed _campaignAddress
  );

  event CampaignRemoved(
    address indexed _campaignAddress
  );

  uint256 public campaignCounter;
  mapping (address => Campaign) campaigns;


  modifier isCreator(address _campaignAddress) {
    if(campaigns[_campaignAddress].i_creator() != msg.sender){
      revert CrowdFunder__NotCreator(msg.sender, _campaignAddress);
    }
    _;
  }

  function addUser(address _address, string memory _username, string memory _twitter, string memory _email, string memory _bio) public {
    emit UserAdded(_address, _username, _twitter, _email, _bio);
  }

  function addCampaign (
    string memory _title, 
    string memory _description,
    string memory _category,
    string[] memory _tags, 
    uint256 _goalAmount,
    uint256 _duration,
    string memory _imageURI,
    string memory _campaignURI,
    address _linkTokenAddress,
    address _upkeepCreatorAddress
    ) external {
    Campaign newCampaign = new Campaign(
      payable(msg.sender), _title, 
      _description, _category, 
      _tags, _goalAmount, 
      _duration, _imageURI, _campaignURI, 
      _linkTokenAddress, _upkeepCreatorAddress
    );
    campaigns[address(newCampaign)] = newCampaign;
    campaignCounter+=1;
    emit CampaignAdded(address(newCampaign), msg.sender);
  }

  function donateToCampaign (address _campaignAddress) public payable {
    (bool success, ) = _campaignAddress.delegatecall(abi.encodeWithSignature("donate()"));
    if(success){
      emit CampaignFunded(msg.sender, _campaignAddress);
    }else{
      revert CrowdFunder__DonationFailed(_campaignAddress);
    }
  }

  function refundFromCampaign(address _campaignAddress, address _donator) public {
    (bool success,) = _campaignAddress.delegatecall(abi.encodeWithSignature("refund(address)", _donator));
    if(success){
      emit CampaignShrunk(msg.sender, _campaignAddress);
    }else{
      revert CrowdFunder__RefundFailed(_campaignAddress);
    }
  }

  function removeCampaign (address _campaignAddress) public isCreator(_campaignAddress) {
    if(uint(campaigns[_campaignAddress].c_state()) == 0){revert CrowdFunder__CampaignStillActive(_campaignAddress);}
    delete(campaigns[_campaignAddress]);
    campaignCounter-=1;
    emit CampaignRemoved(_campaignAddress);
  }
}