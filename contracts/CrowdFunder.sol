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
    string _sig
  );

  event CampaignAdded(
    address indexed _campaignAddress,
    address indexed _creator,
    string _category,
    string[] _tags
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

  event UserHomeAddrAdded(
    address _userAddress,
    string _homeAddr
  );

  uint256 public campaignCounter;
  mapping (address => Campaign) private campaigns;


  modifier isCreator(address _campaignAddress) {
    if(campaigns[_campaignAddress].i_creator() != msg.sender){
      revert CrowdFunder__NotCreator(msg.sender, _campaignAddress);
    }
    _;
  }

  function addUser(
    address _address, string memory _username, 
    string memory _twitter, string memory _email, 
    string memory _sig
    ) public {
    emit UserAdded(_address, _username, _twitter, _email, _sig);
  }

  function addCampaign (
    string memory _title, 
    string memory _description,
    string memory _category,
    string[] memory _tags, 
    uint256 _goalAmount,
    uint256 _duration,
    string memory _imageURI
    ) external {
    Campaign newCampaign = new Campaign(
      payable(msg.sender), _title, 
      _description, _category, 
      _tags, _goalAmount, 
      _duration, _imageURI
    );
    campaigns[address(newCampaign)] = newCampaign;
    campaignCounter+=1;
    emit CampaignAdded(address(newCampaign), msg.sender, _category, _tags);
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

  function addUserHomeAddr (address _userAddress, string memory _homeAddr) public {
    emit UserHomeAddrAdded(_userAddress, _homeAddr);
  }
}