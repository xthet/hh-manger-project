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
    address indexed _creator,
    string _title,
    string _description,
    string _category,
    string[] _tags,
    uint256 _goalAmount,
    uint256 _duration,
    string _campaignURI
  );

  event CampaignFunded(
    address indexed _funder,
    address indexed _campaignAddress
  );

  event CampaignShrunk(
    address indexed _withdrawer,
    address indexed _campaignAddress
  );

  event CampaignCanceled(
    address indexed _campaignAddress
  );


  mapping (address => Campaign) campaigns;
  mapping (address => address[]) campaignsBacked;


  modifier isCreator(address _campaignAddress) {
    if(campaigns[_campaignAddress].getCreator() != msg.sender){
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
    string memory _campaignURI,
    address _registryAddress, 
    address _linkTokenAddress
    ) external {
    Campaign newCampaign = new Campaign(payable(msg.sender), _title, _description, _category, _tags, _goalAmount, _duration, _campaignURI, _registryAddress, _linkTokenAddress);
    campaigns[address(newCampaign)] = newCampaign;
    emit CampaignAdded(address(newCampaign), msg.sender, _title, _description, _category, _tags, _goalAmount, _duration, _campaignURI);
  }

  function donateToCampaign (address _campaignAddress) public payable {
    (bool success, bytes memory data) = _campaignAddress.delegatecall(abi.encodeWithSignature("donate()"));
    if(success){
      emit CampaignFunded(msg.sender, _campaignAddress);
    }else{
      if(data.length>0){revert(string(abi.encodePacked(data)));}
      else{revert CrowdFunder__DonationFailed(_campaignAddress);}
    }
  }

  function refundFromCampaign(address _campaignAddress, address _donator) public {
    if(campaigns[_campaignAddress].getNowRefundable()){
      (bool success,) = _campaignAddress.delegatecall(abi.encodeWithSignature("refund(address)", _donator));
      if(success){
        emit CampaignShrunk(msg.sender, _campaignAddress);
      }else{
        revert CrowdFunder__RefundFailed(_campaignAddress);
      }
    }else{
      revert CrowdFunder__CampaignNotRefundable(_campaignAddress);
    }
  }

  function cancelCampaign (address _campaignAddress) public isCreator(_campaignAddress) {
    if(uint(campaigns[_campaignAddress].getCampaignState()) == 1){revert CrowdFunder__CampaignStillActive(_campaignAddress);}
    delete(campaigns[_campaignAddress]);
    emit CampaignCanceled(_campaignAddress);
  }

  function getCampaign(address _campaignAddress) external view returns (Campaign.CampaignObject memory) {
    return campaigns[_campaignAddress].getCampaignDetails();
  }
}