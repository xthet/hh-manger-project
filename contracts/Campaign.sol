// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./UpkeepIDConsumer.sol";

// errors
error Campaign__NotInC_State();
error Campaign__NotCreator(address _address);
error Campaign__DonatorIsCreator(address _address);
error Campaign__PayoutFailed();
error Campaign__NoDonationsHere(address _donatorAddress);
error Campaign__RefundFailed();
error Campaign__UpkeepNotNeeded();
error Campaign__AlreadyExpired(address _campaignAddress);
error Campaign__NotRefundable(address _campaignAddress);
error Campaign__CampaignBankrupt(address _campaignAddress);


contract Campaign is KeeperCompatibleInterface{
  using SafeMath for uint256;

  // enums
  enum C_State {
    Fundraising,
    Expired,
    Canceled
  }

  // c_state variables
  address payable immutable public i_creator;
  string public s_title;
  string public s_description;
  string public s_category;
  string public s_imageURI;
  string public s_campaignURI;
  string[] public s_tags;
  uint256 public goalAmount;
  uint256 public duration;
  uint256 public currentBalance;
  uint256 private immutable i_lastTimeStamp;
  uint256 private immutable i_maxTimeStamp;
  uint256 public deadline;
  C_State public c_state = C_State.Fundraising; // default c_state
  address private immutable i_linkTokenAddress;
  address private immutable i_upkeepCreatorAddress;
  uint256 private rId;

  struct CampaignObject {
    address i_creator;
    string s_title;
    string s_description;
    string s_category;
    string[] s_tags;
    uint256 goalAmount;
    uint256 duration;
    uint256 currentBalance;
    C_State currentC_State;
    string s_imageURI;
    string s_campaignURI;
    uint256 deadline;
  }

  struct phyReward {
    uint256 price;
    string title;
    string description;
    string[] perks;
    uint256 delDate;
    uint256 quantity;
    string[] shipsTo;
  }

  struct digReward {
    uint256 price;
    string title;
    string description;
    string[] perks;
    uint256 delDate;
    uint256 quantity;
    bool infinite;
  }

  mapping (uint256 => phyReward) public phyRewards;
  mapping (uint256 => digReward) public digRewards;
  mapping (address => uint256[]) public donations;


  // events
  event FundingRecieved (
    address indexed contributor,
    uint256 amount,
    uint256 currentBalance
  );
  event CreatorPaid(address creator, address campaignAddress);
  event CampaignSuccessful(address campaignAddress);
  event CampaignExpired(address campaignAddress);
  event CampaignCanceled();


  // modifiers
  modifier isCreator() {
    if(msg.sender != i_creator){revert Campaign__NotCreator(msg.sender);}
    _;
  }


  constructor (
    address _creator,
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
  ) {
    i_creator = payable(_creator);
    s_title = _title;
    s_description = _description;
    s_category = _category;
    s_tags = _tags;
    goalAmount = _goalAmount;
    i_lastTimeStamp = block.timestamp;
    i_maxTimeStamp = i_lastTimeStamp + 5184000; // 60days
    if(_duration > (i_maxTimeStamp.sub(i_lastTimeStamp))){
      duration = i_maxTimeStamp.sub(i_lastTimeStamp);
    }else{
      duration = _duration;
    }
    deadline = i_lastTimeStamp + duration;
    s_imageURI = _imageURI;
    s_campaignURI = _campaignURI;
    currentBalance = 0;
    i_linkTokenAddress = _linkTokenAddress;
    i_upkeepCreatorAddress = _upkeepCreatorAddress;
  }

  function timeBox() public isCreator {
    UpkeepIDConsumer newUpkeepCreator = UpkeepIDConsumer(i_upkeepCreatorAddress);
    LinkTokenInterface token = LinkTokenInterface(i_linkTokenAddress);
    if(token.balanceOf(i_upkeepCreatorAddress) <= 0){revert("no funds");}
    rId = newUpkeepCreator.registerAndPredictID(s_title, "0x", address(this), 500000, i_creator, "0x", 10000000000000000000, 0);
  }

  function donate() external payable {
    if(c_state != C_State.Fundraising){revert Campaign__NotInC_State();}
    if (msg.sender == i_creator){revert Campaign__DonatorIsCreator(msg.sender);}
    donations[msg.sender].push(msg.value);
    currentBalance = currentBalance.add(msg.value);
    emit FundingRecieved(msg.sender, msg.value, currentBalance);
  }

  /**
    @dev this is the function chainlink keepers calls
    chekupkeep returns true to trigger the action after the interval has passed
   */
  function checkUpkeep(bytes memory /**checkData */) public view override
  returns (bool upkeepNeeded, bytes memory /**performData */) 
  {
    bool isOpen = c_state == C_State.Fundraising;
    bool timePassed = ((block.timestamp - i_lastTimeStamp) > duration);
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (timePassed && isOpen && hasBalance) ;
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(bytes calldata /**performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if(!upkeepNeeded){revert Campaign__UpkeepNotNeeded();}
    c_state = C_State.Expired;
    emit CampaignExpired(address(this));
    if(currentBalance >= goalAmount){
      emit CampaignSuccessful(address(this));
    }
  }

  function payout() public isCreator {
    if(c_state != C_State.Expired){revert Campaign__NotInC_State();}
    uint256 totalRaised = currentBalance;
    currentBalance = 0;
    (bool success, ) = i_creator.call{value: totalRaised}("");
    if(success){
      emit CreatorPaid(i_creator, address(this));
    }
    else{revert Campaign__PayoutFailed();}
  }

  function refund(address _donator) public {
    if(c_state == C_State.Expired){revert Campaign__AlreadyExpired(address(this));}
    if(donations[_donator].length == 0 ){revert Campaign__NoDonationsHere(_donator);}
    uint256 amountToRefund = calcFunderDonations(donations[_donator]);
    delete(donations[_donator]);
    if(currentBalance < amountToRefund){revert Campaign__CampaignBankrupt(address(this));}
    currentBalance = currentBalance.sub(amountToRefund);
    (bool success, ) = payable(_donator).call{value: amountToRefund}("");
    if(!success){revert Campaign__RefundFailed();}
  }

  function calcFunderDonations(uint256[] memory _funderArr) private pure returns(uint256 result){
    for (uint256 i = 0; i < _funderArr.length; i++) {
      result += _funderArr[i];
    }
    return result;
  }

  function makeDigitalReward (
    uint256 _price, string memory _title, 
    string memory _description, 
    string[] memory _perks,
    uint256 _quantity,
    bool _infinite
    ) public isCreator {
    digRewards[_price] = digReward(_price, _title, _description, _perks, deadline, _quantity, _infinite);
  }

  function makePhysicalReward( 
    uint256 _price, string memory _title, 
    string memory _description, string[] memory _perks, 
    uint256 _deadline, uint256 _quantity, string[] memory _shipsTo
    ) public isCreator {
    phyRewards[_price] = phyReward(_price, _title, _description, _perks, _deadline, _quantity, _shipsTo);
  }

  function deleteReward(uint256 _priceID) public isCreator {
    if(phyRewards[_priceID].price > 0){delete(phyRewards[_priceID]);}
    if(digRewards[_priceID].price > 0){delete(digRewards[_priceID]);}
  }

  function endCampaign() public isCreator {
    if(c_state == C_State.Expired){revert Campaign__AlreadyExpired(address(this));}
    c_state = C_State.Canceled;
    emit CampaignCanceled();
  }

  // update functions
  function updateGoalAmount(uint256 _newGoalAmount) public isCreator {
    goalAmount = _newGoalAmount;
  }

  function updateDuration(uint256 _additionalTime) public isCreator {
    if((_additionalTime + duration) > (i_maxTimeStamp.sub(i_lastTimeStamp))){
      duration = i_maxTimeStamp.sub(i_lastTimeStamp); // 60days
    }
    else{
      duration += _additionalTime;
    }
  }

  function updateCampaignURI(string memory _campaignURI) public isCreator {
    s_campaignURI = _campaignURI;
  }

  // getter functions
  function getDonations(address _donator) public view returns(uint256[] memory) {
    return donations[_donator];
  }

  function getCampaignDetails() public view returns(CampaignObject memory) {
    return CampaignObject(
      i_creator,
      s_title,
      s_description,
      s_category,
      s_tags,
      goalAmount,
      duration,
      currentBalance,
      c_state,
      s_imageURI,
      s_campaignURI,
      deadline
    );
  }
}