// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Campaign.sol";

// errors
// error Crf_NotCrtr();
// error Crf_CSA(); /** cmp still active */
// error Crf_DonF();
// error Crf_RefF();
// error Crf_PubF();

contract CrowdFunder {
  using SafeMath for uint256;

  event UserAdded(
    address indexed _address,
    string _username,
    string _email,
    string _shipAddress,
    string _pfp
  );

  event CampaignAdded(
    address indexed _campaignAddress,
    address indexed _creator,
    string _title,
    string _description,
    string _category,
    string _tags,
    string _imageURI
  );

  event CampaignFunded(
    address indexed _funder,
    address indexed _campaignAddress,
    uint256 _val,
    address indexed _c_creator
  );

  event CampaignShrunk(
    address indexed _withdrawer,
    address indexed _campaignAddress,
    uint256 _val,
    address indexed _c_creator
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
    string memory _email, 
    string memory _shipAddress,
    string memory _pfp
    ) external {
    emit UserAdded(_address, _username, _email, _shipAddress, _pfp);
  }

  function addCampaign (
    string calldata _title, 
    string calldata _description,
    string memory _category,
    string memory _tags, 
    uint256 _goalAmount,
    uint256 _duration,
    string calldata _imageURI
    ) external {
    Campaign newCampaign = new Campaign(
      address(this),
      payable(msg.sender), _title, 
      _description, _category, 
      _tags, _goalAmount, 
      _duration, _imageURI
    );
    campaigns[address(newCampaign)] = newCampaign;
    emit CampaignAdded(address(newCampaign), msg.sender, _title, _description, _category, _tags, _imageURI);
  }

  function donateToCampaign(address _campaignAddress) external payable {
    address c_creator = campaigns[_campaignAddress].i_creator();
    (bool success, ) = _campaignAddress.call{value:msg.value}(abi.encodeWithSignature("donate(address)",msg.sender));
    if(success){
      emit CampaignFunded(msg.sender, _campaignAddress, msg.value, c_creator);
    }else{
      revert();
    }
  }

  function refundFromCampaign(address _campaignAddress) external {
    address c_creator = campaigns[_campaignAddress].i_creator();
    uint256 refVal = campaigns[_campaignAddress].aggrDonations(msg.sender);
    if(!(refVal > 0)){revert();}
    (bool success,) = _campaignAddress.call(abi.encodeWithSignature("refund(address)", msg.sender));
    if(success){
      emit CampaignShrunk(msg.sender, _campaignAddress, refVal, c_creator);
    }else{
      revert();
    }
  }

  function removeCampaign (address _campaignAddress) external {
    if(campaigns[_campaignAddress].i_creator() != msg.sender){revert();}
    if(campaigns[_campaignAddress].currentBalance() > 0){revert();}
    // either payout or leave for refunds
    delete(campaigns[_campaignAddress]);
    emit CampaignRemoved(_campaignAddress);
  }

  function publishCampaign(address _campaignAddress, address _upkeepCreator, address _linkToken) external {
    (bool success, ) = _campaignAddress.delegatecall(abi.encodeWithSignature("timeBox(address,address,address)", _upkeepCreator, _linkToken, _campaignAddress));
    if(success){
      campaignCounter = campaignCounter.add(1);
      emit CampaignPublished(_campaignAddress, msg.sender);
    }else{revert();}
  }
}