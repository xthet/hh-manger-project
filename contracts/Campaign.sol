// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import { UpkeepIDConsumer } from "./UpkeepIDConsumer.sol";
import { Reward } from "./Reward.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

// errors
// error Cmp_NIS(); /**not in state */
// error Cmp_NotCrtr();
// error Cmp_DIC(); /**donator is creator */
// error Cmp_NoDns();
// error Cmp_RefF();
// error Cmp_UpkNN();
// error Cmp_NotRef();
// error Cmp_Bankrupt();

contract Campaign is KeeperCompatibleInterface, ReentrancyGuard{
  using SafeMath for uint256;

  // enums
  enum C_State {
    Fundraising,
    Expired,
    Canceled
  }

  // c_state variables
  address immutable private i_crf;
  address payable immutable public i_creator;
  string public s_title;
  string public s_description;
  string public s_category;
  string public s_imageURI;
  string public s_campaignURI;
  string public s_tags;
  uint256 public goalAmount;
  uint256 public duration;
  uint256 public currentBalance;
  uint256 private immutable i_initTimeStamp;
  uint256 private constant i_maxDur = 5184000;
  uint256 public deadline;
  C_State public c_state = C_State.Fundraising; // default c_state
  uint256 private rId;

  struct CampaignObject {
    address i_creator;
    string s_title;
    string s_description;
    string s_category;
    string s_tags;
    uint256 goalAmount;
    uint256 duration;
    uint256 currentBalance;
    C_State currentC_State;
    string s_imageURI;
    string s_campaignURI;
    uint256 deadline;
  }

  // mapping (uint256 => reward) public rewards;
  mapping (uint256 => address) public rewards;
  mapping (address => uint256[]) public entDonations;
  mapping (address => uint256) public aggrDonations;

  uint256[] public rKeys;

  // events
  event FundingRecieved (
    address indexed contributor,
    uint256 amount,
    uint256 currentBalance
  );
  event CreatorPaid(address creator, address campaignAddress);
  event CampaignExpired(address campaignAddress);
  event CampaignCanceled();

  // modifiers
  modifier isCreator() {
    if(msg.sender != i_creator){revert();}
    _;
  }

  constructor (
    address _crowdfunder,
    address _creator,
    string memory _title,
    string memory _description,
    string memory _category,
    string memory _tags,
    uint256 _goalAmount,
    uint256 _duration,
    string memory _imageURI
  ) {
    i_crf = _crowdfunder;
    i_creator = payable(_creator);
    s_title = _title;
    s_description = _description;
    s_category = _category;
    s_tags = _tags;
    goalAmount = _goalAmount;
    i_initTimeStamp = block.timestamp;
    duration = _duration > i_maxDur ? i_maxDur : _duration;
    deadline = i_initTimeStamp.add(duration);
    s_imageURI = _imageURI;
    currentBalance = 0;
  }

  function timeBox(address _upkeepCreatorAddress, address _linkTokenAddress, address _campaignAddress) external isCreator {
    UpkeepIDConsumer newUpkeepCreator = UpkeepIDConsumer(_upkeepCreatorAddress);
    LinkTokenInterface token = LinkTokenInterface(_linkTokenAddress);
    if(token.balanceOf(_upkeepCreatorAddress) == 0){revert("no funds");}
    rId = newUpkeepCreator.registerAndPredictID(s_title, "0x", _campaignAddress, 500000, i_creator, "0x", "0x", 2000000000000000000);
  }

  function donate(address _donator, bool _rewardable) public payable nonReentrant{
    // if(msg.sender != i_crf){revert();}
    if(c_state != C_State.Fundraising){revert();}
    if(_donator == i_creator){revert();}
    currentBalance = currentBalance.add(msg.value);
    if(_rewardable){
      if(rewards[msg.value] != address(0)){
        (bool success, ) = rewards[msg.value].call(abi.encodeWithSignature("addDonator(address)", _donator));
        if(!success){revert();}
        entDonations[_donator].push(msg.value);
      }
    }
    aggrDonations[_donator] = aggrDonations[_donator].add(msg.value); 
    emit FundingRecieved(_donator, msg.value, currentBalance);
  }

  /**
    @dev this is the function chainlink keepers calls
    chekupkeep returns true to trigger the action after the interval has passed
   */
  function checkUpkeep(bytes memory /**checkData */) public view override
  returns (bool upkeepNeeded, bytes memory /**performData */) 
  {
    bool isOpen = c_state == C_State.Fundraising;
    bool timePassed = ((block.timestamp.sub(i_initTimeStamp)) > duration);
    upkeepNeeded = (timePassed && isOpen);
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(bytes calldata /**performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if(!upkeepNeeded){revert();}
    c_state = C_State.Expired;
    emit CampaignExpired(address(this));
  }

  function payout() external isCreator{
    if(c_state != C_State.Expired){revert();}
    uint256 totalRaised = currentBalance;
    currentBalance = 0;
    (bool success, ) = i_creator.call{value: totalRaised}("");
    if(success){
      emit CreatorPaid(i_creator, address(this));
    }
    else{revert();}
  }

  function refund(address _donator) external nonReentrant{
    // if(msg.sender != i_crf){revert();}
    if(c_state == C_State.Expired){revert();}
    if(aggrDonations[_donator] == 0 ){revert();}
    uint256 amountToRefund = aggrDonations[_donator];
    if(currentBalance < amountToRefund){revert();}
    currentBalance = currentBalance.sub(amountToRefund);
    (bool success, ) = payable(_donator).call{value: amountToRefund}("");
    if(!success){revert();}
    delete aggrDonations[_donator];
    if(entDonations[_donator].length > 0){    
      for(uint i=0; i<entDonations[_donator].length; i++){
        if(!(rewards[i] != address(0))){
          // Reward(rewards[i]).removeDonator(_donator);
        }
      }
    }
    delete entDonations[_donator];
  }

  function makeReward( 
    uint256 _price, string memory _title, 
    string memory _description, string memory _rpic,
    string[] memory _perks, 
    uint256 _deadline, uint256 _quantity, bool _infinite, 
    string[] memory _shipsTo
    ) external isCreator {
    if(rewards[_price] != address(0)){revert();}
    rKeys.push(_price);
    Reward newReward = new Reward(address(this), i_creator, _price, _title, _description, _rpic, _perks, _deadline, _quantity, _infinite, _shipsTo);
    rewards[_price] = address(newReward);
  }

  function endCampaign() external isCreator {
    if(c_state == C_State.Expired){revert();}
    c_state = C_State.Canceled;
    emit CampaignCanceled();
  }

  // update functions
  function updateCampaignURI(string memory _campaignURI) external isCreator {
    s_campaignURI = _campaignURI;
  }

  function updateDur(uint256 _addedDur) external isCreator {
    duration = ((duration.add(_addedDur)) > i_maxDur) ? i_maxDur : duration.add(_addedDur);
    deadline = i_initTimeStamp.add(duration);
  }

  // getter functions
  function getRewardKeys() external view returns(uint256[] memory){
    return rKeys;
  }
  
  function getReward(uint256 _priceID) external view returns(Reward.RewardObject memory) {
    Reward reward = Reward(rewards[_priceID]);
    return reward.getRewardDetails();
  }

  function getCampaignDetails() external view returns(CampaignObject memory) {
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