// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Reward {
  address public immutable i_campaignAddress;
  address public immutable i_cdf;
  address public immutable i_creator

  uint256 public immutable i_price;
  string public title;
  string public description;
  string public rpic;
  string[] public perks;
  uint256 public delDate;
  uint256 public quantity;
  bool public infinite = true;
  string[] public shipsTo;
  address[] public donators;
  string public surveyLink;

  struct rewardObject {
    uint256 price;
    string title;
    string description;
    string rpic;
    string[] perks;
    uint256 delDate;
    uint256 quantity;
    bool infinite;
    string[] shipsTo;
    address[] donators;
    string surveyLink;
  }

  modifier isCreator() {
    if(msg.sender != i_creator){revert();}
    _;
  }

  constructor ( 
    uint256 _price, 
    address _campaignAddress, 
    address _cdf, address _creator
    string memory _title, 
    string memory _description, string memory _rpic,
    string[] memory _perks, 
    uint256 _deadline, uint256 _quantity, bool _infinite, 
    string[] memory _shipsTo
    ) {
    i_price = _price;
    i_campaignAddress = _campaignAddress;
    i_cdf = _cdf;
    i_creator = _creator;

    title = _title;
    description = _description;
    rpic = _rpic;
    perks = _perks;
    delDate = _deadline;
    quantity = _quantity;
    infinite = _infinite;
    shipsTo = _shipsTo;
  }

  function updateSurveyLink(string calldata _surveylink) external isCreator {
    surveyLink = _surveylink;
  }

  function getRewardDetails() external view returns(rewardObject memory){
    return rewardObject(
      i_price,
      title,
      description,
      rpic,
      perks,
      delDate,
      quantity,
      infinite,
      shipsTo,
      donators,
      surveyLink
    )
  }
}