// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Reward {
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

  constructor ( uint256 _id, address _campaignAddress, address _cdf) {

  }
}