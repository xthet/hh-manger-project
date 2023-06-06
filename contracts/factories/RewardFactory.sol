// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Reward } from "../Reward.sol";

contract RewardFactory {
  struct rwdInput {
    uint256 _price;
    string  _title; 
    string  _description; 
    string  _rpic;
    string[]  _perks; 
    uint256 _deadline; 
    uint256 _quantity; 
    bool _infinite; 
    string[]  _shipsTo;
  }

  function createReward(address _cmpAddress, address _creator, rwdInput memory _rwd) public returns (address) {
    Reward rwd = new Reward(
      _cmpAddress, 
      _creator,
      _rwd._price,
      _rwd._title,
      _rwd._description,
      _rwd._rpic,
      _rwd._perks,
      _rwd._deadline,
      _rwd._quantity,
      _rwd._infinite,
      _rwd._shipsTo 
    );

    return address(rwd);
  }
}