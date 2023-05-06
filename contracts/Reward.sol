// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Reward{

  uint256 public price;
  string public title;
  string public description;
  string public rpic;
  string[] public perks;
  uint256 public delDate;
  uint256 public quantity;
  bool public infinite;
  string[] public shipsTo;
  address[] public donators;

  constructor(
    uint256 _price,
    string memory _title,
    string memory _description,
    string memory _rpic,
    string[] memory _perks,
    uint256 _delDate,
    uint256 _quantity,
    bool _infinite,
    string[] memory _shipsTo,
    address[] memory _donators
  ){
    
  }
}