// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Campaign.sol";

// errors
error Crf_NotCrtr();
error Crf_CSA(); /** cmp still active */
error Crf_DonF();
error Crf_RefF();
error Crf_PubF();

contract CrowdFunder {
  using SafeMath for uint256;

  event UserAdded(
    address indexed _address,
    string _username,
    string _twitter,
    string _email,
    string _homeAddress,
    string _pfp
  );

  event CampaignAdded(
    address indexed _campaignAddress,
    address indexed _creator,
    string _title,
    string _description,
    string _category,
    string _tags
  );

  event CampaignFunded(
    address indexed _funder,
    address indexed _campaignAddress,
    uint256 _val
  );

  event CampaignShrunk(
    address indexed _withdrawer,
    address indexed _campaignAddress,
    uint256 _val
  );

  event CampaignRemoved(
    address indexed _campaignAddress
  );

  event CampaignPublished(
    address _campaignAddress,
    address _creator
  );

  uint256 public campaignCounter;
  mapping (address => Campaign) private campaigns;

  function addUser(
    address _address, string memory _username, 
    string memory _twitter, string memory _email, 
    string memory _homeAddress,
    string memory _pfp
    ) external {
    emit UserAdded(_address, _username, _twitter, _email, _homeAddress, _pfp);
  }

  function addCampaign (
    string memory _title, 
    string memory _description,
    string memory _category,
    string memory _tags, 
    uint256 _goalAmount,
    uint256 _duration,
    string memory _imageURI
    ) external {
    Campaign newCampaign = new Campaign(
      address(this),
      payable(msg.sender), _title, 
      _description, _category, 
      _tags, _goalAmount, 
      _duration, _imageURI
    );
    campaigns[address(newCampaign)] = newCampaign;
    emit CampaignAdded(address(newCampaign), msg.sender, _title, _description, _category, _tags);
  }

  function donateToCampaign(address _campaignAddress) external payable {
    (bool success, ) = _campaignAddress.call{value:msg.value}(abi.encodeWithSignature("donate(address)",msg.sender));
    if(success){
      emit CampaignFunded(msg.sender, _campaignAddress, msg.value);
    }else{
      revert Crf_DonF();
    }
  }

  function refundFromCampaign(address _campaignAddress) external {
    uint256 refVal = campaigns[_campaignAddress].aggrDonations(msg.sender);
    if(!(refVal > 0)){revert();}
    (bool success,) = _campaignAddress.call(abi.encodeWithSignature("refund(address)", msg.sender));
    // campaigns[_campaignAddress].refund(msg.sender);
    // emit CampaignShrunk(msg.sender, _campaignAddress, refVal);
    if(success){
      emit CampaignShrunk(msg.sender, _campaignAddress, refVal);
    }else{
      revert Crf_RefF();
    }
  }

  function removeCampaign (address _campaignAddress) external {
    if(campaigns[_campaignAddress].i_creator() != msg.sender){revert Crf_NotCrtr();}
    if(campaigns[_campaignAddress].currentBalance() > 0){revert Crf_CSA();}
    // either payout or leave for refunds
    delete(campaigns[_campaignAddress]);
    emit CampaignRemoved(_campaignAddress);
  }

  function publishCampaign(address _campaignAddress, address _upkeepCreator, address _linkToken) external {
    (bool success, ) = _campaignAddress.delegatecall(abi.encodeWithSignature("timeBox(address,address,address)", _upkeepCreator, _linkToken, _campaignAddress));
    if(success){
      campaignCounter = campaignCounter.add(1);
      emit CampaignPublished(_campaignAddress, msg.sender);
    }else{revert Crf_PubF();}
  }

  fallback() external payable{}
  receive() external payable{}
}